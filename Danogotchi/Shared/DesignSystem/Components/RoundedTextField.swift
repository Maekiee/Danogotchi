import UIKit

final class RoundedTextField: UITextField {
    init(placeholder: String) {
        super.init(frame: .zero)

        borderStyle = .none
        backgroundColor = AppColor.white
        layer.cornerRadius = AppRadius.radius20
        layer.borderWidth = AppBorder.thin
        layer.borderColor = AppColor.gray30.cgColor
        clipsToBounds = true
        font = AppFont.title2

        textColor = AppColor.black
        attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .font: AppFont.title2,
                .foregroundColor: AppColor.gray45
            ]
        )
        autocapitalizationType = .none
        autocorrectionType = .no

        let paddingFrame = CGRect(x: 0, y: 0, width: AppSpacing.space20, height: 0)
        leftView = UIView(frame: paddingFrame)
        leftViewMode = .always
        rightView = UIView(frame: paddingFrame)
        rightViewMode = .always
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
