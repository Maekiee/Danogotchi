import UIKit

class BaseViewController: UIViewController, UIConfigurationLayout {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }
    
    deinit {
        print("Deinit 해제됨")
    }
    
    func configHierarchy() { }
    func configLayout() { }
    func configView() { }
    
}
