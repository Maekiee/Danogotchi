import UIKit

final class TextButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.plain()
        config.title = title
        self.configuration = config
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
