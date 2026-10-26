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
            backgroundColor = AppColor.inverse
            setTitleColor(AppColor.onInverse, for: .normal)
            applyOutline()
        case .secondary:
            titleLabel?.font = AppFont.bodyEmphasis
            backgroundColor = AppColor.surface
            setTitleColor(AppColor.textPrimary, for: .normal)
            applyOutline()
        case .text:
            titleLabel?.font = AppFont.label
            setTitleColor(AppColor.textPrimary, for: .normal)
        }
    }

    private func applyOutline() {
        applyBorder(width: AppBorder.regular, color: AppColor.outline, radius: AppRadius.radius20)
    }
}
