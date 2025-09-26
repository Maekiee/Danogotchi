import UIKit

class BaseViewController: UIViewController, UIConfigurationLayout {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }
    
    func configHierarchy() { }
    func configLayout() { }
    func configView() { }
    
}
