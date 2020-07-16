import UIKit

class ConfigureMaskDetectionTableViewController: UITableViewController {

    private var choosenIndexPath = 0
    private var possibleInterval: [String] {
        var stringArray = [String]()
        for index in 1...12 {
            stringArray.append(String(index * 5))
        }
        return stringArray
    }
    
    private let possibleUnit = ["Sekunden", "Minuten"]
    
    @IBOutlet weak var recordNameTxtField: UITextField! {
        didSet {
            recordNameTxtField.delegate = self
        }
    }
    
    @IBOutlet weak var intervalLbl: UILabel!
    @IBOutlet weak var unitLbl: UILabel!
    @IBOutlet weak var cameraBtn: UIBarButtonItem! {
        didSet {
            cameraBtn.isEnabled = false
        }
    }
    
    @IBAction func cancelActionBtn(_ sender: UIBarButtonItem) {
        presentingViewController?.dismiss(animated: true)
    }
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupToHideKeyboardOnTapOnView()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.recordNameTxtField.endEditing(true)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        choosenIndexPath = indexPath.row
    }
    
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
    
    func setupToHideKeyboardOnTapOnView() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(self.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
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
