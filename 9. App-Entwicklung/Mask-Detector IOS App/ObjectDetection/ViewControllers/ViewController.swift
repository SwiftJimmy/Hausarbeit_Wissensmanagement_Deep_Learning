// Copyright 2019 The TensorFlow Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import TensorFlowLite
import FirebaseStorage
import FirebaseFirestore

extension Notification.Name {
    static let PhotoWasAddedToDisk = Notification.Name("PhotoWasAddedToDisk")
}

class ViewController: UIViewController {

  // MARK: Storyboards Connections
  @IBOutlet weak var previewView: PreviewView!
  @IBOutlet weak var overlayView: OverlayView!
  @IBOutlet weak var resumeButton: UIButton!
  @IBOutlet weak var cameraUnavailableLabel: UILabel!

  @IBOutlet weak var bottomSheetStateImageView: UIImageView!
  @IBOutlet weak var bottomSheetView: UIView!
  @IBOutlet weak var bottomSheetViewBottomSpace: NSLayoutConstraint!

    let dateFormat = "dd.MM.yyyy_HH:mm:ss"
    var name = ""
    var interval:Double = 0
    var unit = "" {
        didSet {
            if interval > 0 && unit == "Minuten"  {
               interval *= 60
            }
        }
    }
    private weak var timer: Timer?
    private var objectOverlays = [ObjectOverlay]()
    private var resultArray = [Inference]()
    private var maskImage: MaskImage? {
        didSet {
             save()
        }
    }
    
    
    // MARK: Constants
  private let displayFont = UIFont.systemFont(ofSize: 14.0, weight: .medium)
  private let edgeOffset: CGFloat = 2.0
  private let labelOffset: CGFloat = 10.0
  private let animationDuration = 0.5
  private let collapseTransitionThreshold: CGFloat = -30.0
  private let expandThransitionThreshold: CGFloat = 30.0
  private let delayBetweenInferencesMs: Double = 200

  // MARK: Instance Variables
  private var initialBottomSpace: CGFloat = 0.0

  // Holds the results at any time
  private var result: Result?
  private var previousInferenceTimeMs: TimeInterval = Date.distantPast.timeIntervalSince1970 * 1000

  // MARK: Controllers that manage functionality
  private lazy var cameraFeedManager = CameraFeedManager(previewView: previewView)
  private var modelDataHandler: ModelDataHandler? =
    ModelDataHandler(modelFileInfo: MobileNetSSD.modelInfo, labelsFileInfo: MobileNetSSD.labelsInfo)
  private var inferenceViewController: InferenceViewController?

  // MARK: View Handling Methods
  override func viewDidLoad() {
    super.viewDidLoad()

    guard modelDataHandler != nil else {
      fatalError("Failed to load model")
    }
    cameraFeedManager.delegate = self
    overlayView.clearsContextBeforeDrawing = true

    addPanGesture()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    changeBottomViewState()
    cameraFeedManager.checkCameraConfigurationAndStartSession()
    timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(takePicture), userInfo: nil, repeats: true)
  }
    
    @objc private func takePicture() {
        
        cameraFeedManager.capturePhoto()
    }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
     timer?.invalidate()
    cameraFeedManager.stopSession()
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  // MARK: Button Actions
  @IBAction func onClickResumeButton(_ sender: Any) {

    cameraFeedManager.resumeInterruptedSession { (complete) in

      if complete {
        self.resumeButton.isHidden = true
        self.cameraUnavailableLabel.isHidden = true
      }
      else {
        self.presentUnableToResumeSessionAlert()
      }
    }
  }

  func presentUnableToResumeSessionAlert() {
    let alert = UIAlertController(
      title: "Unable to Resume Session",
      message: "There was an error while attempting to resume session.",
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

    self.present(alert, animated: true)
  }

  // MARK: Storyboard Segue Handlers
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    super.prepare(for: segue, sender: sender)

    if segue.identifier == "EMBED" {

      guard let tempModelDataHandler = modelDataHandler else {
        return
      }
      inferenceViewController = segue.destination as? InferenceViewController
      inferenceViewController?.wantedInputHeight = tempModelDataHandler.inputHeight
      inferenceViewController?.wantedInputWidth = tempModelDataHandler.inputWidth
      inferenceViewController?.threadCountLimit = tempModelDataHandler.threadCountLimit
      inferenceViewController?.currentThreadCount = tempModelDataHandler.threadCount
      inferenceViewController?.delegate = self

      guard let tempResult = result else {
        return
      }
      inferenceViewController?.inferenceTime = tempResult.inferenceTime

    }
  }
}

// MARK: InferenceViewControllerDelegate Methods
extension ViewController: InferenceViewControllerDelegate {

  func didChangeThreadCount(to count: Int) {
    if modelDataHandler?.threadCount == count { return }
    modelDataHandler = ModelDataHandler(
      modelFileInfo: MobileNetSSD.modelInfo,
      labelsFileInfo: MobileNetSSD.labelsInfo,
      threadCount: count
    )
  }

}

// MARK: CameraFeedManagerDelegate Methods
extension ViewController: CameraFeedManagerDelegate {
    
    //Aufnahme des Photos
    func tookPhoto(from data: Data) {
        
        var maskImageInfoArray = [MaskImage.ImageInfo]()
        objectOverlays.forEach({overlay in
            let completeLabelArray = overlay.name.components(separatedBy: "  ")
            if completeLabelArray.count == 2 {
                var withoutPercentage = completeLabelArray[1]
                 withoutPercentage.removeFirst()
                withoutPercentage.removeLast(2)
                let maskInfo = MaskImage.ImageInfo(
                    labelMapName: completeLabelArray[0],
                    confidenceValue: withoutPercentage)
                maskImageInfoArray.append(maskInfo)
            }
        })
        
        // Das Image wird aus dem Data Object erstellt
        var image = UIImage(data: data)
        let imageName =  String(Date().timeIntervalSince1970).replacingOccurrences(of: ".", with: "") + ".jpg"
  
        self.uploadImageToFirebase(image: image!,imageName: imageName,folder: "original")
    
        /**
                    Draw Rectangle over each object
         */
        resultArray.forEach { (overlay) in
            let cgRect = overlay.rect
            let cgPoint = CGPoint(x: cgRect.minX, y:cgRect.minY - 30 )
            // Rectangle wird eingezeichnet
            image = drawRectangleOnImage(image: image!, withFrame: cgRect,rectColor: overlay.displayColor)
            // Rectangles werden mit Kategorienamen versehen
            image = textToImage(drawText:overlay.className, inImage: image!, atPoint: cgPoint, textColor: overlay.displayColor,textFont: UIFont(name: "Times New Roman", size: 30.0)!)
        }
        
         
        
        // - das neue Image wird wieder in ein Data Object umgewandelt zur Speicherung
        self.uploadImageToFirebase(image: image!,imageName: imageName,folder: "annotated")
         
        
        
        let data = image!.jpegData(compressionQuality: 1)
        maskImage = MaskImage(imageData: data!, name: name, date: Date(), infos: maskImageInfoArray)
        
    }
     
    /**
     In jedes Bild werden die erkannten Kategorien mit einem Rahmen eingezeichnet und benannt.
    */
    func drawRectangleOnImage(image: UIImage, withFrame: CGRect,rectColor: UIColor) -> UIImage? {

        UIGraphicsBeginImageContextWithOptions( image.size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        image.draw(at: CGPoint.zero)
        context!.setStrokeColor(rectColor.cgColor)
        //Line Width
        context!.setLineWidth(5)
        context!.addRect(withFrame)
        context!.drawPath(using: .stroke)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    /**
        Die Funktion lädt ein UIImage als jpg auf Firebase Storage
    */
    func uploadImageToFirebase( image: UIImage, imageName: String, folder: String){
        
        if Reachability.isConnectedToNetwork(){ // überprüft, ob das Gerät mit dem Wifi verbunden ist
            DispatchQueue.global(qos: .background).async {
            do  {
                    // wandelt UIImage in jpg um
                    guard let uploadData = image.jpegData(compressionQuality: 1.0) else {
                    print("Issue while uploading")
                    return }
                    // erstellt Firebase Reference
                    let imageReference = Storage.storage().reference().child(folder)
                    .child(imageName)
                    // lädt due Datei in den Firebase Storeage
            
                    imageReference.putData(uploadData, metadata:nil) { (metadata, err) in
                        if let err = err {
                            print("error while put data" + err.localizedDescription)
                            return
                        }
                    }
                    NotificationCenter.default.post(name: .PhotoWasAddedToDisk,object: nil)
                    print(folder + " uploaded successfully")
                }
            }
        }
    }
    
    
    

    
    
    /**
     Bennenung der einzelnen Kategorie-Rahmen
    */
    func textToImage(drawText text: String, inImage image: UIImage, atPoint point: CGPoint,textColor: UIColor, textFont: UIFont ) -> UIImage {
        
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(image.size, false, scale)

        let textFontAttributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: textColor,
            ] as [NSAttributedString.Key : Any]
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))

        let rect = CGRect(origin: point, size: image.size)
        text.draw(in: rect, withAttributes: textFontAttributes)

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }
    
    /**
         Das Image wird als Json Datei gesichert.
    */
    private func save() {
        if let stringDate = self.maskImage?.date?.getTimeAndDateFormatted(dateFormat: "dd.MM.yyyy_HH:mm:ss") {
            if let json = self.maskImage?.json {
                if let url = try? FileManager.default.url(for: .documentDirectory,
                                                          in: .userDomainMask,
                                                          appropriateFor: nil,
                                                          create: true)
                    .appendingPathComponent(stringDate + ".json") {
                    DispatchQueue.global(qos: .background).async {
                        do  {
                            try json.write(to: url)
                            NotificationCenter.default.post(name: .PhotoWasAddedToDisk,object: nil)
                            print("saved successfully")
                        } catch let error {
                            print("couldn`t save \(error)")
                        }
                    }
                }
            }
        }
    }
    
    
  func didOutput(pixelBuffer: CVPixelBuffer) {
    runModel(onPixelBuffer: pixelBuffer)
  }

  // MARK: Session Handling Alerts
  func sessionRunTimeErrorOccured() {
    timer?.invalidate()
    // Handles session run time error by updating the UI and providing a button if session can be manually resumed.
    self.resumeButton.isHidden = false
  }

  func sessionWasInterrupted(canResumeManually resumeManually: Bool) {
     timer?.invalidate()
    // Updates the UI when session is interupted.
    if resumeManually {
      self.resumeButton.isHidden = false
    }
    else {
      self.cameraUnavailableLabel.isHidden = false
    }
  }

  func sessionInterruptionEnded() {
    timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(takePicture), userInfo: nil, repeats: true)
    // Updates UI once session interruption has ended.
    if !self.cameraUnavailableLabel.isHidden {
      self.cameraUnavailableLabel.isHidden = true
        
    }

    if !self.resumeButton.isHidden {
      self.resumeButton.isHidden = true
    }
  }

  func presentVideoConfigurationErrorAlert() {
    timer?.invalidate()
    let alertController = UIAlertController(title: "Confirguration Failed", message: "Configuration of camera has failed.", preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
    alertController.addAction(okAction)

    present(alertController, animated: true, completion: nil)
  }

  func presentCameraPermissionsDeniedAlert() {
    timer?.invalidate()
    let alertController = UIAlertController(title: "Camera Permissions Denied", message: "Camera permissions have been denied for this app. You can change this by going to Settings", preferredStyle: .alert)

    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    let settingsAction = UIAlertAction(title: "Settings", style: .default) { (action) in

      UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
    }

    alertController.addAction(cancelAction)
    alertController.addAction(settingsAction)

    present(alertController, animated: true, completion: nil)

  }

  /** This method runs the live camera pixelBuffer through tensorFlow to get the result.
   */
  @objc  func runModel(onPixelBuffer pixelBuffer: CVPixelBuffer) {

    // Run the live camera pixelBuffer through tensorFlow to get the result

    let currentTimeMs = Date().timeIntervalSince1970 * 1000

    guard  (currentTimeMs - previousInferenceTimeMs) >= delayBetweenInferencesMs else {
      return
    }

    previousInferenceTimeMs = currentTimeMs
    result = self.modelDataHandler?.runModel(onFrame: pixelBuffer)
    resultArray.removeAll()
    resultArray = result!.inferences
    guard let displayResult = result else {
      return
    }

    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)

    DispatchQueue.main.async {

      // Display results by handing off to the InferenceViewController
      self.inferenceViewController?.resolution = CGSize(width: width, height: height)

      var inferenceTime: Double = 0
      if let resultInferenceTime = self.result?.inferenceTime {
        inferenceTime = resultInferenceTime
      }
      self.inferenceViewController?.inferenceTime = inferenceTime
      self.inferenceViewController?.tableView.reloadData()

      // Draws the bounding boxes and displays class names and confidence scores.
      self.drawAfterPerformingCalculations(onInferences: displayResult.inferences, withImageSize: CGSize(width: CGFloat(width), height: CGFloat(height)))
    }
  }

  /**
   This method takes the results, translates the bounding box rects to the current view, draws the bounding boxes, classNames and confidence scores of inferences.
   */
  func drawAfterPerformingCalculations(onInferences inferences: [Inference], withImageSize imageSize:CGSize) {

    self.overlayView.objectOverlays = []
    self.overlayView.setNeedsDisplay()

    guard !inferences.isEmpty else {
      return
    }

    objectOverlays.removeAll()

    for inference in inferences {

      // Translates bounding box rect to current view.
      var convertedRect = inference.rect.applying(CGAffineTransform(scaleX: self.overlayView.bounds.size.width / imageSize.width, y: self.overlayView.bounds.size.height / imageSize.height))

      if convertedRect.origin.x < 0 {
        convertedRect.origin.x = self.edgeOffset
      }

      if convertedRect.origin.y < 0 {
        convertedRect.origin.y = self.edgeOffset
      }

      if convertedRect.maxY > self.overlayView.bounds.maxY {
        convertedRect.size.height = self.overlayView.bounds.maxY - convertedRect.origin.y - self.edgeOffset
      }

      if convertedRect.maxX > self.overlayView.bounds.maxX {
        convertedRect.size.width = self.overlayView.bounds.maxX - convertedRect.origin.x - self.edgeOffset
      }

      let confidenceValue = Int(inference.confidence * 100.0)
      let string = "\(inference.className)  (\(confidenceValue)%)"

      let size = string.size(usingFont: self.displayFont)
      let numberOfRect = String(inferences.count)
        let objectOverlay = ObjectOverlay(name: string, borderRect: convertedRect, nameStringSize: size, color: inference.displayColor, font: self.displayFont,count:numberOfRect)

      objectOverlays.append(objectOverlay)
    }

    // Hands off drawing to the OverlayView
    self.draw(objectOverlays: objectOverlays)

  }

  /** Calls methods to update overlay view with detected bounding boxes and class names.
   */
  func draw(objectOverlays: [ObjectOverlay]) {

    self.overlayView.objectOverlays = objectOverlays
    self.overlayView.setNeedsDisplay()
  }

}

// MARK: Bottom Sheet Interaction Methods
extension ViewController {

  // MARK: Bottom Sheet Interaction Methods
  /**
   This method adds a pan gesture to make the bottom sheet interactive.
   */
  private func addPanGesture() {
    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(ViewController.didPan(panGesture:)))
    bottomSheetView.addGestureRecognizer(panGesture)
  }


  /** Change whether bottom sheet should be in expanded or collapsed state.
   */
  private func changeBottomViewState() {

    guard let inferenceVC = inferenceViewController else {
      return
    }

    if bottomSheetViewBottomSpace.constant == inferenceVC.collapsedHeight - bottomSheetView.bounds.size.height {

      bottomSheetViewBottomSpace.constant = 0.0
    }
    else {
      bottomSheetViewBottomSpace.constant = inferenceVC.collapsedHeight - bottomSheetView.bounds.size.height
    }
    setImageBasedOnBottomViewState()
  }

  /**
   Set image of the bottom sheet icon based on whether it is expanded or collapsed
   */
  private func setImageBasedOnBottomViewState() {

    if bottomSheetViewBottomSpace.constant == 0.0 {
        if #available(iOS 13.0, *) {
            bottomSheetStateImageView.image = UIImage(named: "down_icon")?.withTintColor(.label, renderingMode: .alwaysTemplate)
        } else {
            // Fallback on earlier versions
        }
    }
    else {
        if #available(iOS 13.0, *) {
            bottomSheetStateImageView.image = UIImage(named: "up_icon")?.withTintColor(.label, renderingMode: .alwaysTemplate)
        } else {
            // Fallback on earlier versions
        }
    }
  }

  /**
   This method responds to the user panning on the bottom sheet.
   */
  @objc func didPan(panGesture: UIPanGestureRecognizer) {

    // Opens or closes the bottom sheet based on the user's interaction with the bottom sheet.
    let translation = panGesture.translation(in: view)

    switch panGesture.state {
    case .began:
      initialBottomSpace = bottomSheetViewBottomSpace.constant
      translateBottomSheet(withVerticalTranslation: translation.y)
    case .changed:
      translateBottomSheet(withVerticalTranslation: translation.y)
    case .cancelled:
      setBottomSheetLayout(withBottomSpace: initialBottomSpace)
    case .ended:
      translateBottomSheetAtEndOfPan(withVerticalTranslation: translation.y)
      setImageBasedOnBottomViewState()
      initialBottomSpace = 0.0
    default:
      break
    }
  }

  /**
   This method sets bottom sheet translation while pan gesture state is continuously changing.
   */
  private func translateBottomSheet(withVerticalTranslation verticalTranslation: CGFloat) {

    let bottomSpace = initialBottomSpace - verticalTranslation
    guard bottomSpace <= 0.0 && bottomSpace >= inferenceViewController!.collapsedHeight - bottomSheetView.bounds.size.height else {
      return
    }
    setBottomSheetLayout(withBottomSpace: bottomSpace)
  }

  /**
   This method changes bottom sheet state to either fully expanded or closed at the end of pan.
   */
  private func translateBottomSheetAtEndOfPan(withVerticalTranslation verticalTranslation: CGFloat) {

    // Changes bottom sheet state to either fully open or closed at the end of pan.
    let bottomSpace = bottomSpaceAtEndOfPan(withVerticalTranslation: verticalTranslation)
    setBottomSheetLayout(withBottomSpace: bottomSpace)
  }

  /**
   Return the final state of the bottom sheet view (whether fully collapsed or expanded) that is to be retained.
   */
  private func bottomSpaceAtEndOfPan(withVerticalTranslation verticalTranslation: CGFloat) -> CGFloat {

    // Calculates whether to fully expand or collapse bottom sheet when pan gesture ends.
    var bottomSpace = initialBottomSpace - verticalTranslation

    var height: CGFloat = 0.0
    if initialBottomSpace == 0.0 {
      height = bottomSheetView.bounds.size.height
    }
    else {
      height = inferenceViewController!.collapsedHeight
    }

    let currentHeight = bottomSheetView.bounds.size.height + bottomSpace

    if currentHeight - height <= collapseTransitionThreshold {
      bottomSpace = inferenceViewController!.collapsedHeight - bottomSheetView.bounds.size.height
    }
    else if currentHeight - height >= expandThransitionThreshold {
      bottomSpace = 0.0
    }
    else {
      bottomSpace = initialBottomSpace
    }

    return bottomSpace
  }

  /**
   This method layouts the change of the bottom space of bottom sheet with respect to the view managed by this controller.
   */
  func setBottomSheetLayout(withBottomSpace bottomSpace: CGFloat) {

    view.setNeedsLayout()
    bottomSheetViewBottomSpace.constant = bottomSpace
    view.setNeedsLayout()
  }

}
