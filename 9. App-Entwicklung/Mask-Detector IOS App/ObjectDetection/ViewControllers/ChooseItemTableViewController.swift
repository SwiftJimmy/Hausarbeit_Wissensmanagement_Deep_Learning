import UIKit
/**
 View für die Auswahl der Drop-Down elemente
 */
class ChooseItemTableViewController: UITableViewController {
    
    var cellText = ""
    var dataSource = [String]()
    private var lastSelectedCell = UITableViewCell()

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }
    
    // Gibt die Anzahl an Auswahlmöglichkeiten zurück
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
     
        return dataSource.count
    }

    // Funktion erstellt die Zelle in der Dropdown-Auswahl
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chooseItemCell", for: indexPath)
        cell.accessoryType = .none
        cell.tintColor = UIColor.white
        cell.textLabel?.text = ""
        cell.textLabel?.textAlignment = .left
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17.0)
        if #available(iOS 13.0, *) {
            cell.textLabel?.textColor = .label
        } else {
          cell.textLabel?.textColor = UIColor.black
        }
        cell.textLabel?.text = dataSource[indexPath.row]
        
        if cell.textLabel?.text == cellText {
            cell.accessoryType = .checkmark
            cell.tintColor = UIColor.systemBlue
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 17.0)
            cell.textLabel?.textColor = UIColor.systemBlue
            lastSelectedCell = cell
        }
        
        return cell
    }
    
    // Funktion für die Auwswahl eines Elements aus dem Drow-Down Menue (Highliting während der Finger auf der Zelle liegt)
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let indexPathLastSelectedCell = tableView.indexPath(for: self.lastSelectedCell) {
            let cell = tableView.cellForRow(at: indexPathLastSelectedCell)
            cell?.accessoryType = .none
            cell?.tintColor  = UIColor.white
            cell?.textLabel?.textColor = UIColor.black
            cell?.textLabel?.font = UIFont.systemFont(ofSize: 17.0)
        }
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
            cell.tintColor = UIColor.init(red: 0, green: 0.3176, blue: 0.8824, alpha: 1)
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 17.0)
            cell.textLabel?.textColor = UIColor.init(red: 0, green: 0.3176, blue: 0.8824, alpha: 1)
            cellText = cell.textLabel!.text!
        }
        return indexPath
    }
}
