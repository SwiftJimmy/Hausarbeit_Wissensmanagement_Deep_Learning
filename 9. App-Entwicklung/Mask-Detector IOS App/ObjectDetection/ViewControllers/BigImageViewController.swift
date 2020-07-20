import UIKit
/**
   Beinhaltet die Logic der einzelnen Bildanzeige der  Aufnahmen-Ansicht.
*/
class BigImageViewController: UIViewController {

    var imageView = UIImageView()
    // Deklarierung und Funktion des Fertig-Buttons
    @IBAction func doneBtnAction(_ sender: UIBarButtonItem) {
        presentingViewController?.dismiss(animated: true)
    }
    // Funktion wird aufgerufen sobald die View geladen wurde.
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(imageView)
        imageView.center = view.center
    }
}
