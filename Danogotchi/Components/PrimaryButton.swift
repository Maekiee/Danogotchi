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
            
            // 버튼 활성화 상태 여부
            if button.state == .disabled {
                button.configuration?.baseBackgroundColor = .lightGray
            } else {
                button.configuration?.baseBackgroundColor = .systemGreen
            }
            
            
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}


