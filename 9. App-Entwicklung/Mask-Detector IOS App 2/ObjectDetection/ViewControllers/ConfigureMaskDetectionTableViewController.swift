import UIKit

/**
   Beinhaltet die Logic der Aufnahmeoptionen-Ansicht.
*/
class ConfigureMaskDetectionTableViewController: UITableViewController {

    private var choosenIndexPath = 0
    // Intervallauswahl
    private var possibleInterval: [String] {
        var stringArray = [String]()
        for index in 1...12 {
            stringArray.append(String(index * 5))
        }
        return stringArray
    }
    
    // Auswahl der Intervall-Kategorie
    private let possibleUnit = ["Sekunden", "Minuten"]
    
    // Bestimmung des Namen der Aufnahme (Beispielsweise Aufnahmeort)
    @IBOutlet weak var recordNameTxtField: UITextField! {
        didSet {
            recordNameTxtField.delegate = self
        }
    }
    
    // Intervall und Invervall-Kategorie Label
    @IBOutlet weak var intervalLbl: UILabel!
    @IBOutlet weak var unitLbl: UILabel!
    
    // Kamera Button
    @IBOutlet weak var cameraBtn: UIBarButtonItem! {
        didSet {
            cameraBtn.isEnabled = false
        }
    }
    
    // Done / Cancle Button
    @IBAction func cancelActionBtn(_ sender: UIBarButtonItem) {
        presentingViewController?.dismiss(animated: true)
    }
    
    // Annimation beim herunterziehen der Ansicht
    @IBAction func goBack(segue: UIStoryboardSegue) {
        if let mvcUnwoundFrom = segue.source as? ChooseItemTableViewController {
            if choosenIndexPath == 1 {
                intervalLbl.text = mvcUnwoundFrom.cellText
            }
            if choosenIndexPath == 2 {
                unitLbl.text = mvcUnwoundFrom.cellText
            }
            cameraBtn.isEnabled = !recordNameTxtField.text!.isEmpty && !intervalLbl.text!.isEmpty && !unitLbl.text!.isEmpty
        }
    }
    
    // Lädt den Inhalt nachdem der View geladen wird
    override func viewDidLoad() {
        super.viewDidLoad()
        setupToHideKeyboardOnTapOnView()
    }
    
    // Funktion triggert das Berühren des Name of Record Input Feldes
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.recordNameTxtField.endEditing(true)
    }
    
    // Animation und Auswahl eines Menue-Objektes
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        choosenIndexPath = indexPath.row
    }
    
    // Speicherung der Menue-Auswahl/Eingabe
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destination = segue.destination as? ChooseItemTableViewController {
            destination.modalPresentationStyle = UIModalPresentationStyle.popover
            destination.popoverPresentationController!.delegate = self
            switch segue.identifier {
            case "intervalSegue":
                destination.dataSource = possibleInterval
                destination.cellText = intervalLbl.text ?? ""
            case "unitSegue":
                destination.dataSource = possibleUnit
                destination.cellText = unitLbl.text ?? ""
            default:
                break
            }
        }
        
        if segue.identifier == "cameraSegue" {
            if let destinationVC = segue.destination as? ViewController {
                destinationVC.name = recordNameTxtField.text ?? ""
                destinationVC.interval = Double(intervalLbl.text!) ?? 0.0
                destinationVC.unit = unitLbl.text ?? ""
            }
        }
    }
    // Funktion lädt die Inhalte in die App und versteckt das keyboard
    func setupToHideKeyboardOnTapOnView() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    // Funktion versteckt das keyboard
    @objc func dismissKeyboard() {
        self.cameraBtn.isEnabled = !recordNameTxtField.text!.isEmpty && !intervalLbl.text!.isEmpty && !unitLbl.text!.isEmpty
        view.endEditing(true)
    }
}

extension ConfigureMaskDetectionTableViewController: UITextFieldDelegate, UIPopoverPresentationControllerDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.recordNameTxtField.endEditing(true)
        if let intervalText = self.intervalLbl.text, let unitText = self.unitLbl.text {
            self.cameraBtn.isEnabled = !intervalText.isEmpty && !unitText.isEmpty
        }

        return true
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
         return UIModalPresentationStyle.none
    }
}
