import UIKit

final class PrimaryFillButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.filled()
        config.title = title
        config.titleAlignment = .center
        config.attributedTitle?.font = .systemFont(ofSize: 15, weight: .bold)
        config.baseForegroundColor = .white
        config.baseBackgroundColor = AppColor.oxfordBlue
//        config.background.cornerRadius = 8
        config.background.cornerRadius = 24
        self.configuration = config
        
        self.configurationUpdateHandler = { button in
            
            // 버튼 활성화 상태 여부
            if button.state == .disabled {
                button.configuration?.baseBackgroundColor = .gray
            } else {
                button.configuration?.baseBackgroundColor = AppColor.oxfordBlue
            }
            
            
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}


