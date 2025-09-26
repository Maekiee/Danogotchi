import UIKit

final class PrimaryTextField: UITextField {
    init() {
        super.init(frame: .zero)
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: self.frame.height))
        autocapitalizationType = .none
        textColor = .black
        leftView = paddingView
        leftViewMode = .always
        textAlignment = .left
        borderStyle = .none
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemGray.cgColor
    }
    
    convenience init(placeholder: String) {
        self.init()
        self.placeholder = placeholder
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
