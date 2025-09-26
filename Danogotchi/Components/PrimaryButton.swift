import UIKit

final class PrimaryFillButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.filled()
        config.title = title
        config.titleAlignment = .center
        config.attributedTitle?.font = .systemFont(ofSize: 15, weight: .bold)
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .systemGreen
        config.background.cornerRadius = 8
        self.configuration = config
        
        self.configurationUpdateHandler = { button in
            
            if button.state == .disabled {
                button.configuration?.baseBackgroundColor = .lightGray
            } else if button.isHighlighted {
                button.configuration?.baseBackgroundColor = .systemGreen
            } else {
//                button.configuration?.baseBackgroundColor = .systemGreen.withAlphaComponent(0.5)
            }
            
            
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}


