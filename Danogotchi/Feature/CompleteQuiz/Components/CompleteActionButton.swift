import UIKit

/// 학습 완료 화면의 액션 버튼. 스타일로 위계를 구분한다.
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
            backgroundColor = AppColor.oxfordBlue
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

    /// 앱 공통 외곽선 스타일 (검은 테두리 + 오프셋 그림자)
    private func applyOutline() {
        layer.cornerRadius = AppRadius.radius20

        layer.borderWidth = AppBorder.regular
        layer.borderColor = UIColor.black.cgColor

        layer.shadowColor = AppColor.pointDarkGray.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowOpacity = 1.0
        layer.shadowRadius = 0
    }
}
