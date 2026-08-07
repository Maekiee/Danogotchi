import UIKit

/// 4지선다 답안 버튼. 정답 공개 시 idle → correct/wrong 으로 전환된다.
final class ChoiceButton: UIButton {

    enum Style {
        case idle
        case correct
        case wrong
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
        apply(.idle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(_ style: Style) {
        switch style {
        case .idle:
            backgroundColor = AppColor.appWhite
            setTitleColor(AppColor.textPrimary, for: .normal)
        case .correct:
            backgroundColor = AppColor.appGreen
            setTitleColor(.white, for: .normal)
        case .wrong:
            backgroundColor = AppColor.appRed
            setTitleColor(.white, for: .normal)
        }
    }

    private func configure() {
        titleLabel?.font = AppFont.title2
        layer.cornerRadius = AppRadius.radius20

        layer.borderWidth = AppBorder.regular
        layer.borderColor = UIColor.black.cgColor

        layer.shadowColor = AppColor.pointDarkGray.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowOpacity = 1.0
        layer.shadowRadius = 0
    }
}
