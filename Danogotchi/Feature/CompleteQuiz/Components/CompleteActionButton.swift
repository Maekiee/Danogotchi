import UIKit

final class CompleteActionButton: UIButton {

    enum Style {
        case primary
        case secondary
        case text
    }

    init(style: Style, title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        configure(style)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(_ style: Style) {
        switch style {
        case .primary:
            titleLabel?.font = AppFont.bodyEmphasis
            backgroundColor = AppColor.black
            setTitleColor(.white, for: .normal)
            applyOutline()
        case .secondary:
            titleLabel?.font = AppFont.bodyEmphasis
            backgroundColor = AppColor.appWhite
            setTitleColor(AppColor.textPrimary, for: .normal)
            applyOutline()
        case .text:
            titleLabel?.font = AppFont.label
            setTitleColor(AppColor.textPrimary, for: .normal)
        }
    }

    private func applyOutline() {
        layer.cornerRadius = AppRadius.radius20

        layer.borderWidth = AppBorder.regular
        layer.borderColor = UIColor.black.cgColor
    }
}
