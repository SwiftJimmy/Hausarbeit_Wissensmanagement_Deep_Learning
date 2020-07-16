import UIKit
/**
   Beinhaltet die Logic der Time-Laps-Ansicht.
*/
class TimeLapsTableViewController: UITableViewController {
    // ReportButton wird nur dann aktiviert, wenn Time-Laps Aufnahmen vorhanden sind
    private var loadedMaskImages = [MaskImage]() {
        didSet {
            dailyReportsBtn.isEnabled = loadedMaskImages.count > 0
        }
    }
    // Gruppierung der Aufnahme-Sessions nach Datum
    private var groupedImagesByDay = [Date: [MaskImage]]()
    private var groupedImagesByDayUnmodified = [Date: [MaskImage]]()
    // Sortierung der Aufnahme-Sessions nach Datum
    private var sortedKeys = [Date]()
    private var sortedValuesForKey = [MaskImage]()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let myIndicator = UIActivityIndicatorView(style: .whiteLarge)
        myIndicator.hidesWhenStopped = true
        return myIndicator
    }()
    
    // Deklaration des reportButtons
    @IBOutlet weak var dailyReportsBtn: UIBarButtonItem!
    
    /**
    Funktion wird aufgerufen sobald der View geladen wurde.
    Lädt die Dtaen in den Table View
    */
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDataForTableView()
        addObserver()
       
    }
    
    /**
    add Observer, welcher kontrolliert ob eine neue Aufnahme-Sessions dazugekommen ist beziehungsweise gelöscht wurde.
    Falss ja, wird der Table View erneut mit den aktuellen Daten gefüllt.
     */
    private func addObserver() {
        NotificationCenter.default.addObserver(
            forName: .PhotoWasAddedToDisk,
            object: nil,
            queue: OperationQueue.main,
            using: {[weak self] _ in
                self?.setupDataForTableView()
                self?.tableView.reloadData()
        })
        
        NotificationCenter.default.addObserver(
            forName: .PhotoWasRemovedFromDisk,
            object: nil,
            queue: OperationQueue.main,
            using: {[weak self] _ in
                self?.setupDataForTableView()
                self?.tableView.reloadData()
        })
    }
    
    /**
        Funktion  fügt alle Aufnahme-Sessions. der Tabelle hinzu
     */
    private func setupDataForTableView() {
        loadedMaskImages = getMaskImageFromDisk()
        groupedImagesByDay = groupedMaskImagesByDay(loadedMaskImages)
        groupedImagesByDayUnmodified = groupedImagesByDay
        sortedKeys = groupedImagesByDay.keys.sorted(by: >)
        sortedKeys.forEach {date in
            let valuesForKey = groupedImagesByDay[date]
            sortedValuesForKey = valuesForKey!.sorted(by: {$0.date!.compare($1.date!) == .orderedDescending})
            let uniqueValuesForKey = sortedValuesForKey.removingDuplicates()
            groupedImagesByDay[date] = uniqueValuesForKey
        }
    }
    
    /**
       Funktion zum Löschen von Aufnahme-Sessions. Dies wird durch einen Swipe nach rechts realisert.
    */
    private func removeMaskImagesFromDisk(maskImages: [MaskImage]) {
        
        var fileNames = [String]()
        maskImages.forEach({maskImage in
            fileNames.append((maskImage.date?.getTimeAndDateFormatted(dateFormat: "dd.MM.yyyy_HH:mm:ss"))! + ".json")
        })
        
        if let url = try? FileManager.default.url(for: .documentDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: nil,
                                                  create: true) {
            fileNames.forEach({fileName in
                do {
                    try FileManager.default.removeItem(at: url.appendingPathComponent(fileName))
                    print("Removing Succesfull")
                } catch let error as NSError {
                    print(error.debugDescription)
                    print("Removing NOT Succesfull")
                }
            })
        }
    }
    
    /**
       Lädt die lokal abgelegten Aufnahme-Sessions
    */
    private func getMaskImageFromDisk() -> [MaskImage] {
        var maskImages = [MaskImage]()
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let directoryContents = try? FileManager.default.contentsOfDirectory(at: url!, includingPropertiesForKeys: nil)
        directoryContents!.forEach({url in
            if let jsonData = try? Data(contentsOf: url){
                if let maskImage = MaskImage(json: jsonData) {
                    maskImages.append(maskImage)
                }
            }
        })
        return maskImages
    }
    
    /**
            Die Funktion gruppiert die Images nach dem Datum und gibt diese in Form einer Liste zurück
    */
    private func groupedMaskImagesByDay(_ maskImages: [MaskImage]) -> [Date: [MaskImage]] {
        let empty: [Date: [MaskImage]] = [:]
        return maskImages.reduce(into: empty) { acc, cur in
            let components = Calendar.current.dateComponents([.day,.month,.year], from: cur.date!)
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: "UTC")!
            let date = calendar.date(from: components)!
            let existing = acc[date] ?? []
            acc[date] = existing + [cur]
        }
    }

    // MARK: - Table view data source
    
    /**
       Gibt die Anzahl an Aufnahme-Session der ausgewählten Sektion zurück
    */
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return groupedImagesByDay.keys.count
    }
    
    /**
           Gibt die Anzahl an Aufnahme-Session zurück
    */
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        let day = sortedKeys[section]
        return groupedImagesByDay[day]!.count
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    /**
       Erstellt den Nachfrage-Alert bei der Löschung einer Aufnahme-Session
    */
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    // first Action
        let eraseAction = UIContextualAction(style: .normal, title:  "", handler: { (ac:UIContextualAction, view:UIView, success:@escaping (Bool) -> Void) in
            let alert = UIAlertController(title: "Löschen", message: "Möchtest du wirklich den ausgewählten Eintrag löschen?", preferredStyle: UIAlertController.Style.alert)
            // configure delete action
            alert.addAction(UIAlertAction(title: "Löschen", style: UIAlertAction.Style.destructive, handler:{ (UIAlertAction)in
                let date = self.sortedKeys[indexPath.section]
                let maskImages = self.groupedImagesByDayUnmodified[date]
                let chosenMaskImagesLocation = self.groupedImagesByDay[date]
                let location = chosenMaskImagesLocation![indexPath.row].location
                let filteredMaskImages = maskImages?.filter({maskImage in
                    maskImage.location == location
                })
                self.view.addSubview(self.activityIndicator)
                self.activityIndicator.isHidden = false
                self.activityIndicator.center = self.view.center
                self.activityIndicator.startAnimating()
                self.removeMaskImagesFromDisk(maskImages: filteredMaskImages!)
                self.setupDataForTableView()
                
                DispatchQueue.main.async {
                    tableView.reloadData()
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.removeFromSuperview()
                }
                success(true)
                
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
    
    /**
        Erstellt den Header der Tages-Sektion
    */
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let date = sortedKeys[section]
        let format = "dd.MM.yyyy"
        let stringDay = date.dayNameOfWeek()
        let stringDate = date.getTimeAndDateFormatted(dateFormat: format)
        return stringDay + " " + stringDate
    }
    
    /**
        Erstellt den View der einzelnen Aufnahme-Session
    */
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dateCell", for: indexPath)
        let date = sortedKeys[indexPath.section]
        let maskImages = groupedImagesByDay[date]
        let time = maskImages![indexPath.row].date!.getTimeAndDateFormatted(dateFormat: "HH:mm:ss")
        cell.textLabel!.text = "Ort: " + maskImages![indexPath.row].location
        cell.detailTextLabel!.text = "Startzeit: " + time
        return cell
    }
    
    /**
        Realisiert die Selektierung und deselktierung einer einzelnen Aufnahme-Session (grauer Hintergrund bei Selektierung)
    */
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let cell = sender as? UITableViewCell {
            if segue.identifier == "showImages" {
                if let destinationVc = segue.destination as? ImagesTableViewController {
                    if let section = tableView.indexPath(for: cell)?.section, let indexPath = tableView.indexPath(for: cell) {
                        let day = sortedKeys[section]
                        let groupedImages = groupedImagesByDay[day]
                        var images = groupedImagesByDayUnmodified[day]
                        images = images?.sorted(by:{$0.date! > $1.date!})
                        destinationVc.maskImages = images!.filter({image in
                            return image.location == groupedImages![indexPath.row].location
                        })
                    }
                }
            }
        }
        if segue.identifier == "showReportsSegue" {
              if let destinationVc = segue.destination as? ReportsViewController {
                destinationVc.maskImages = groupedImagesByDayUnmodified
            }
        }
        
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()

        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }

    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
}
