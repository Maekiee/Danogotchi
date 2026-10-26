import UIKit

final class PrimaryFillButton: UIButton {
    init(title: String) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.filled()
        config.title = title
        config.titleAlignment = .center
        config.baseBackgroundColor = AppColor.inverse
        config.baseForegroundColor = AppColor.onInverse
        config.background.cornerRadius = AppRadius.radius20
        self.configuration = config

        self.configuration?.titleTextAttributesTransformer =
            UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = AppFont.title3
                return outgoing
            }

        self.configurationUpdateHandler = { button in
            // 버튼 활성화 상태 여부
            let isEnabled = button.state != .disabled
            button.configuration?.baseBackgroundColor = isEnabled ? AppColor.inverse : AppColor.gray30
            button.configuration?.baseForegroundColor = isEnabled ? AppColor.onInverse : AppColor.gray45
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
