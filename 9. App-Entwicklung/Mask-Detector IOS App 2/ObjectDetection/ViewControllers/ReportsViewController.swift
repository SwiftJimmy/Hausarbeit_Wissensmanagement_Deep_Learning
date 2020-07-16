import UIKit
import Charts
import SRCountdownTimer

class ReportsViewController: UIViewController, UITextFieldDelegate, UIPopoverPresentationControllerDelegate {

    var maskImages = [Date: [MaskImage]]()
    var dataEntryWithMask = PieChartDataEntry(value: 0)
    var dataEntryWithoutMask = PieChartDataEntry(value: 0)
    var dataEntryWornMaskIncorrectly = PieChartDataEntry(value: 0)
    var confidenceValueWithMask = [Double]()
    var confidenceValueWithoutMask = [Double]()
    var confidenceValueWornMaskIncorrectly = [Double]()
    var confidenceOverall = [Double]()
    var confidenceAverageValueWithMask = 0.0
    var confidenceAverageValueWithoutMask = 0.0
    var confidenceAverageValueWornMaskIncorrectly = 0.0
    var confidenceAverageValueOverall = 0.0
    let dateFormat = "dd.MM.yyyy"
    
    private var withMaskLabel: UILabel = {
        let label = UILabel()
        label.text = "100%"
        label.font = UIFont.systemFont(ofSize: 30, weight: .regular)
        label.textColor = UIColor.systemGreen
        label.sizeToFit()
        return label
    }()
    
    private var withoutMaskLabel = UILabel()
    
    private var wornMaskIncorrectlyLabel = UILabel()
    
   private var overallAverageLabel = UILabel()
    
    @IBOutlet weak var withMaskCircle: SRCountdownTimer! {
        didSet {
            withMaskCircle.isLabelHidden = true
            withMaskCircle.moveClockWise = false
            withMaskCircle.delegate = self
            if #available(iOS 13.0, *) {
                withMaskCircle.trailLineColor = .label
            } else {
                withMaskCircle.trailLineColor = .black
            }
        }
    }
    @IBOutlet weak var withoutMaskCircle: SRCountdownTimer! {
        didSet {
            withoutMaskCircle.isLabelHidden = true
            withoutMaskCircle.moveClockWise = false
            withoutMaskCircle.delegate = self
            if #available(iOS 13.0, *) {
                withoutMaskCircle.trailLineColor = .label
            } else {
                withoutMaskCircle.trailLineColor = .black
            }
        }
    }
    @IBOutlet weak var wornMaskIncorrectlyCircle: SRCountdownTimer! {
        didSet {
            wornMaskIncorrectlyCircle.isLabelHidden = true
            wornMaskIncorrectlyCircle.delegate = self
            wornMaskIncorrectlyCircle.moveClockWise = false
            if #available(iOS 13.0, *) {
                wornMaskIncorrectlyCircle.trailLineColor = .label
            } else {
                wornMaskIncorrectlyCircle.trailLineColor = .black
            }
        }
    }
    @IBOutlet weak var overallAverage: SRCountdownTimer! {
        didSet {
            overallAverage.isLabelHidden = true
            overallAverage.delegate = self
            overallAverage.moveClockWise = false
            if #available(iOS 13.0, *) {
                overallAverage.trailLineColor = .label
            } else {
               overallAverage.trailLineColor = .black
            }
        }
    }
    
    
    var numberOfDataEntries = [PieChartDataEntry]()
    
    @IBAction func goBack(segue: UIStoryboardSegue) {
        if let mvcUnwoundFrom = segue.source as? ChooseItemTableViewController {
            if chooseDayTxtField.text != mvcUnwoundFrom.cellText {
                chooseDayTxtField.text = mvcUnwoundFrom.cellText
                maskImages.keys.forEach({date in
                    if date.getTimeAndDateFormatted(dateFormat: dateFormat) == chooseDayTxtField.text {
                        removeLabels()
                        setup(for: date)
                        setupLabels()
                        startTimer()
                    }
                })
            }
        }
    }
    
    @IBOutlet weak var chooseDayTxtField: UITextField! {
        didSet {
            chooseDayTxtField.delegate = self
        }
    }
    @IBOutlet weak var pieChartView: PieChartView!
    @IBOutlet weak var recognitionRate: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let latestDate = maskImages.keys.sorted(by: >).first!
        chooseDayTxtField.text = latestDate.getTimeAndDateFormatted(dateFormat: dateFormat)
        setup(for: latestDate)
        setupLabels()
        startTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        resetTimer()
    }
    
    private func removeLabels() {
        withMaskCircle.subviews.forEach({
            $0.removeFromSuperview()
        })
        withoutMaskCircle.subviews.forEach({
            $0.removeFromSuperview()
        })
        wornMaskIncorrectlyCircle.subviews.forEach({
            $0.removeFromSuperview()
        })
        overallAverage.subviews.forEach({
            $0.removeFromSuperview()
        })
    }
    
    func setup(for date: Date) {
        createReports(for: date)
        createRecognitionAverages()
        setupChart()
        updateChartData()
    }
    
    private func startTimer() {
        withMaskCircle.start(beginingValue: 100, interval: 0.05)
        withoutMaskCircle.start(beginingValue: 100, interval: 0.05)
        wornMaskIncorrectlyCircle.start(beginingValue: 100, interval: 0.05)
        overallAverage.start(beginingValue: 100, interval: 0.05)
    }
    
    private func resetTimer() {
        withMaskCircle.reset()
        withoutMaskCircle.reset()
        wornMaskIncorrectlyCircle.reset()
        overallAverage.reset()
    }
    
    private func createReports(for date: Date) {
        var withMaskCount = 0
        var withoutMaskCount = 0
        var maskIncorrectlyWornCount = 0
        confidenceValueWithMask.removeAll()
        confidenceValueWithoutMask.removeAll()
        confidenceValueWornMaskIncorrectly.removeAll()
        
        let maskImagesOfDate = maskImages[date]
        maskImagesOfDate?.forEach({maskImage in
            maskImage.infos.forEach({
                var newConfidence = $0.confidenceValue
                if $0.confidenceValue.contains("%") {
                    newConfidence.removeFirst()
                    newConfidence.removeLast(2)
                }
                let confidenceValue = Double(newConfidence) ?? 0.0
                if $0.labelMapName == "with_mask" {
                    withMaskCount += 1
                    print(confidenceValue)
                    confidenceValueWithMask.append(confidenceValue)
                } else if $0.labelMapName == "without_mask" {
                    withoutMaskCount += 1
                    confidenceValueWithoutMask.append(confidenceValue)
                } else if $0.labelMapName == "mask_weared_incorrect" {
                    maskIncorrectlyWornCount += 1
                    confidenceValueWornMaskIncorrectly.append(confidenceValue)
                }
            })
        })

        let all = withMaskCount + withoutMaskCount + maskIncorrectlyWornCount
        dataEntryWithMask.value = (Double(withMaskCount) / Double(all) * 100).rounded()
        dataEntryWithMask.label = "With Mask: " + String(dataEntryWithMask.value)
        dataEntryWithMask.label?.removeLast(2)
        dataEntryWithMask.label! += "%"
        
        dataEntryWithoutMask.value = (Double(withoutMaskCount) / Double(all) * 100).rounded()
        dataEntryWithoutMask.label = "Without Mask: " + String(dataEntryWithoutMask.value)
        dataEntryWithoutMask.label?.removeLast(2)
        dataEntryWithoutMask.label! += "%"
        
        dataEntryWornMaskIncorrectly.value = (Double(maskIncorrectlyWornCount) / Double(all)  * 100).rounded()
        dataEntryWornMaskIncorrectly.label = "Mask Worn Incorrectly: " + String(dataEntryWornMaskIncorrectly.value)
        dataEntryWornMaskIncorrectly.label?.removeLast(2)
        dataEntryWornMaskIncorrectly.label! += "%"
        
    }
    
    private func createRecognitionAverages() {
        
        print(confidenceValueWithMask.reduce(0, +))
        confidenceAverageValueWithMask = confidenceValueWithMask.reduce(0, +) / Double(confidenceValueWithMask.count)
        print(confidenceAverageValueWithMask)
        
        confidenceAverageValueWithoutMask = confidenceValueWithoutMask.reduce(0, +) / Double(confidenceValueWithoutMask.count)
     
        confidenceAverageValueWornMaskIncorrectly = (confidenceValueWornMaskIncorrectly.reduce(0, +) / Double(confidenceValueWornMaskIncorrectly.count))
        
        var count = 0.0
        if confidenceAverageValueWithMask.isNaN {
            confidenceAverageValueWithMask = 0
        } else {
            count += 1
        }
        
        if confidenceAverageValueWithoutMask.isNaN {
            confidenceAverageValueWithoutMask = 0
        } else {
            count += 1
        }
        
        if confidenceAverageValueWornMaskIncorrectly.isNaN {
            confidenceAverageValueWornMaskIncorrectly = 0
        } else {
            count += 1
        }
        
        confidenceAverageValueOverall = (confidenceAverageValueWithMask + confidenceAverageValueWithoutMask + confidenceAverageValueWornMaskIncorrectly) / count
       
    }
    
    private func setupChart() {
        pieChartView.drawHoleEnabled = false
        pieChartView.drawEntryLabelsEnabled = false
        pieChartView.legend.font = UIFont.systemFont(ofSize: 20
            , weight: .regular)
        if #available(iOS 13.0, *) {
            pieChartView.legend.textColor = .label
        } else {
            pieChartView.legend.textColor = .black
        }
        pieChartView.legend.orientation = .horizontal
        pieChartView.legend.form = .circle
        pieChartView.legend.formSize = 15
        pieChartView.legend.xOffset = 15
        pieChartView.legend.yEntrySpace = 5
        pieChartView.legend.xEntrySpace = 10
        pieChartView.legend.verticalAlignment = .bottom
        numberOfDataEntries = [dataEntryWithMask, dataEntryWithoutMask, dataEntryWornMaskIncorrectly]
    }
    
    private func updateChartData() {
        let chartDataSet = PieChartDataSet(entries: numberOfDataEntries, label: "")
   
        if #available(iOS 13.0, *) {
            chartDataSet.valueTextColor = .label
        } else {
             chartDataSet.valueTextColor = .black
        }
        chartDataSet.drawValuesEnabled = false
        chartDataSet.valueFont =  UIFont.systemFont(ofSize: 17, weight: .regular)
        let chartData = PieChartData(dataSet: chartDataSet)
        let colors = [UIColor.systemGreen, UIColor.systemRed, UIColor.systemOrange]
        chartDataSet.colors = colors
        
        pieChartView.data = chartData
        
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
        performSegue(withIdentifier: "daySegue", sender: self)
        
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "daySegue" {
            if let destination = segue.destination as? ChooseItemTableViewController {
                destination.modalPresentationStyle = UIModalPresentationStyle.popover
                destination.popoverPresentationController!.delegate = self
                destination.cellText = chooseDayTxtField.text!
                destination.dataSource = maskImages.keys.sorted(by: >).map({
                    $0.getTimeAndDateFormatted(dateFormat: dateFormat)
                })
                
            }
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
            return UIModalPresentationStyle.none
       }
}

extension ReportsViewController: SRCountdownTimerDelegate {
    
    func timerDidUpdateCounterValue(sender: SRCountdownTimer, newValue: Int) {
        
        if sender == self.withMaskCircle {
            if confidenceAverageValueWithMask == 0.0 {
                withMaskLabel.text = "no Data"
                withMaskLabel.sizeToFit()
                withMaskLabel.center.x -= 8
                sender.pause()
                return
            }
            if Double(newValue) < abs(confidenceAverageValueWithMask - 100) {
                sender.pause()
                return
            }
            withMaskLabel.text = "\(abs(newValue - 100))" + " %"
        }
        
        if sender == self.withoutMaskCircle {
            if confidenceAverageValueWithoutMask == 0.0 {
                withoutMaskLabel.text = "no Data"
                withoutMaskLabel.sizeToFit()
                withoutMaskLabel.center.x -= 8
                sender.pause()
                return
                //
            }
            if Double(newValue) <= abs(confidenceAverageValueWithoutMask - 100) {
                sender.pause()
                return
            }
            withoutMaskLabel.text = "\(abs(newValue - 100))" + " %"
        }
        
        if sender == self.wornMaskIncorrectlyCircle {
            if confidenceAverageValueWornMaskIncorrectly == 0.0 {
                wornMaskIncorrectlyLabel.text = "no Data"
                wornMaskIncorrectlyLabel.sizeToFit()
                wornMaskIncorrectlyLabel.center.x -= 8
                sender.pause()
                return
            }
            if Double(newValue) <= abs(confidenceAverageValueWornMaskIncorrectly - 100) {
                sender.pause()
                return
            }
            wornMaskIncorrectlyLabel.text = "\(abs(newValue - 100))" + " %"
        }
        
        if sender == self.overallAverage {
            if confidenceAverageValueOverall == 0.0 {
                overallAverageLabel.text = "no Data"
                overallAverageLabel.sizeToFit()
                overallAverageLabel.center.x -= 8
                sender.pause()
            }
            if Double(newValue) <= abs(confidenceAverageValueOverall - 100) {
                sender.pause()
                return
            }
            overallAverageLabel.text = "\(abs(newValue - 100))" + " %"
        }
        
    }
}

extension ReportsViewController {
    func setupLabels() {
       
        withMaskLabel = UILabel()
        withMaskLabel.text = "100%"
        withMaskLabel.font = UIFont.systemFont(ofSize: 30, weight: .regular)
        withMaskLabel.textColor = UIColor.systemGreen
        withMaskLabel.sizeToFit()
        withMaskCircle.addSubview(withMaskLabel)
        withMaskLabel.center = withMaskCircle.center
        withMaskLabel.center.x += 10
        withMaskLabel.center.y -= 20
        let firstlabel = UILabel()
        firstlabel.text = "With Mask"
        firstlabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        firstlabel.textColor = UIColor.systemGreen
        firstlabel.sizeToFit()
        withMaskCircle.addSubview(firstlabel)
        firstlabel.center = withMaskCircle.center
        firstlabel.center.y += 15
        
  
        withoutMaskLabel = UILabel()
        withoutMaskLabel.text = "100%"
        withoutMaskLabel.font = UIFont.systemFont(ofSize: 30, weight: .regular)
        withoutMaskLabel.textColor = UIColor.systemRed
        withoutMaskLabel.sizeToFit()
        withoutMaskCircle.addSubview(withoutMaskLabel)
        withoutMaskLabel.center = withoutMaskCircle.center
        withoutMaskLabel.center.y -= 20
        withoutMaskLabel.center.x -= 185
        let secondLabel = UILabel()
        secondLabel.text = "Without Mask"
        secondLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        secondLabel.textColor = UIColor.systemRed
        secondLabel.sizeToFit()
        withoutMaskCircle.addSubview(secondLabel)
        secondLabel.center = withoutMaskCircle.center
        secondLabel.center.y += 15
        secondLabel.center.x -= 188
        
      
        wornMaskIncorrectlyLabel = UILabel()
        wornMaskIncorrectlyLabel.text = "100%"
        wornMaskIncorrectlyLabel.font = UIFont.systemFont(ofSize: 30, weight: .regular)
        wornMaskIncorrectlyLabel.textColor = UIColor.systemOrange
        wornMaskIncorrectlyLabel.sizeToFit()
        wornMaskIncorrectlyCircle.addSubview(wornMaskIncorrectlyLabel)
        wornMaskIncorrectlyLabel.center = wornMaskIncorrectlyCircle.center
        wornMaskIncorrectlyLabel.center.y -= 25
        let thirdLabel = UILabel()
        thirdLabel.text = "Mask Incorrect"
        thirdLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        thirdLabel.textColor = UIColor.systemOrange
        thirdLabel.sizeToFit()
        wornMaskIncorrectlyCircle.addSubview(thirdLabel)
        thirdLabel.center = wornMaskIncorrectlyCircle.center
        thirdLabel.center.y += 5
        
       
        overallAverageLabel = UILabel()
        overallAverageLabel.text = "100%"
        overallAverageLabel.font = UIFont.systemFont(ofSize: 30, weight: .regular)
        overallAverageLabel.textColor = UIColor.systemBlue
        overallAverageLabel.sizeToFit()
        overallAverage.addSubview(overallAverageLabel)
        overallAverageLabel.center = overallAverage.center
        overallAverageLabel.center.y -= 25
        overallAverageLabel.center.x -= 175
        let fourthLabel = UILabel()
        fourthLabel.text = "overall Average"
        fourthLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        fourthLabel.textColor = UIColor.systemBlue
        fourthLabel.sizeToFit()
        overallAverage.addSubview(fourthLabel)
        fourthLabel.center = overallAverage.center
        fourthLabel.center.y += 5
        fourthLabel.center.x -= 188
    }
}
