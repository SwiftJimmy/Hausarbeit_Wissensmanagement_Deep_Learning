import UIKit

extension Notification.Name {
    static let PhotoWasRemovedFromDisk = Notification.Name("PhotoWasRemovedFromDisk")
}

class ImagesTableViewController: UITableViewController {

    private let reuseIdentifier = "imageTableViewCell"
    
    var maskImages = [MaskImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Aufnahmen " + (maskImages.first?.location ?? "")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return maskImages.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showBigImageSegue" {
            if let destinationNC = segue.destination as? UINavigationController {
                if let destinationVC = destinationNC.viewControllers.first as? BigImageViewController {
                    if let cell = sender as? UITableViewCell {
                        if let indexPathRow = self.tableView.indexPath(for: cell)?.row, let image = UIImage(data: maskImages[indexPathRow].imageData!) {
                            destinationVC.imageView = UIImageView(image: cropImageToSquare(image: image))
                        }
                    }
                }
            }
            
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
           
           return true
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    // first Action
        let eraseAction = UIContextualAction(style: .normal, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:@escaping (Bool) -> Void) in
            
            let alert = UIAlertController(title: "Löschen", message: "Möchtest du wirklich den ausgewählten Eintrag löschen?", preferredStyle: UIAlertController.Style.alert)
            // configure delete action
            alert.addAction(UIAlertAction(title: "Löschen", style: UIAlertAction.Style.destructive, handler:{ (UIAlertAction)in
                self.removeMaskImagesFromDisk(at: indexPath)
                if self.maskImages.count == 0 {
                    self.navigationController?.popViewController(animated: true)
                } else {
                    DispatchQueue.main.async {
                        tableView.reloadData()
                    }
                }
                
            }))
            // configure cancel action
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler:{ (UIAlertAction)in
                success(true)
                
            }))
            self.present(alert, animated: true, completion: nil )
            
        })
        
        let imageNameErase = "trash-40"
        let imageErase = UIImage(named: imageNameErase)
        let imageViewErase = UIImageView(image: imageErase!)
        eraseAction.image = imageViewErase.image!.withRenderingMode(.alwaysTemplate)
        eraseAction.backgroundColor = .red
        let config =  UISwipeActionsConfiguration(actions: [eraseAction])
        config.performsFirstActionWithFullSwipe = true
        return config
    }
    
    private func removeMaskImagesFromDisk(at indexPath: IndexPath) {
        var fileName = maskImages[indexPath.row].date?.getTimeAndDateFormatted(dateFormat: "dd.MM.yyyy_HH:mm:ss") ?? ""
        fileName += ".json"
        if let url = try? FileManager.default.url(for: .documentDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true) {
            do {
                try FileManager.default.removeItem(at: url.appendingPathComponent(fileName))
                print("Removing Succesfull")
                maskImages.remove(at: indexPath.row)
                NotificationCenter.default.post(name: .PhotoWasAddedToDisk,object: nil)
            } catch let error as NSError {
                print(error.debugDescription)
                print("Removing NOT Succesfull")
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        
        if let image = UIImage(data: maskImages[indexPath.row].imageData!) {
            cell.backgroundColor = .clear
            let dateString = maskImages[indexPath.row].date?.getTimeAndDateFormatted(dateFormat: "dd.MM.yyyy HH:mm:ss")
            cell.textLabel?.text = dateString
            var withMaskCount = 0
            var withoutMask = 0
            var wearedIncorrect = 0
            maskImages[indexPath.row].infos.forEach({info in
                if info.labelMapName == "with_mask" {
                    withMaskCount += 1
                } else if info.labelMapName == "without_mask" {
                    withoutMask += 1
                } else if info.labelMapName == "mask_weared_incorrect" {
                    wearedIncorrect += 1
                }
                
            })
            cell.detailTextLabel?.numberOfLines = 0
            cell.detailTextLabel?.text = "With Mask: " + "\(withMaskCount)" + "\n" + "Without Mask: " + "\(withoutMask)" + "\n" + "Mask Worn Incorrectly: " + "\(wearedIncorrect)"
            if let croppedImage = cropImageToSquare(image: image) {
                cell.imageView!.image = croppedImage
            }
        }
        
        return cell
    }
    
    func cropImageToSquare(image: UIImage) -> UIImage? {
        let screenWidth = view.bounds.width
        let screenHeight = view.bounds.height
        UIGraphicsBeginImageContextWithOptions(CGSize(width: screenWidth, height: screenHeight), false, 0.0)
        if let ctx = UIGraphicsGetCurrentContext() {
            ctx.translateBy(x: 0, y: 0)
            image.draw(in: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: screenWidth, height: screenHeight)))
            if let image = UIGraphicsGetImageFromCurrentImageContext() {
                  UIGraphicsEndImageContext()
                 return image
            }
        }
        return nil
    }
    
    func addLabelBoxesToImageView() {
        
    }


    
}
