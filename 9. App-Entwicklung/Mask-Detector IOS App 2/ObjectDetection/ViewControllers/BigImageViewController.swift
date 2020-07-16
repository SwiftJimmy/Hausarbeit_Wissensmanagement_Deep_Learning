import UIKit

class BigImageViewController: UIViewController {

    var imageView = UIImageView()
    
    @IBAction func doneBtnAction(_ sender: UIBarButtonItem) {
        presentingViewController?.dismiss(animated: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(imageView)
        imageView.center = view.center
    }
}
