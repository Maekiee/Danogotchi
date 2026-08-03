import UIKit

/// UILabel은 자체 여백이 없어 테두리를 두르면 텍스트가 선에 붙는다. 그 여백을 지원하는 라벨.
final class PaddingLabel: UILabel {
    var contentInsets: UIEdgeInsets = .zero {
        didSet { invalidateIntrinsicContentSize() }
    }

    /// layer.borderColor는 CGColor라 light/dark 전환을 따라가지 못하므로 UIColor를 들고 있다가 갱신한다
    var borderColor: UIColor? {
        didSet { layer.borderColor = borderColor?.cgColor }
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInsets.left + contentInsets.right,
            height: size.height + contentInsets.top + contentInsets.bottom
        )
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            layer.borderColor = borderColor?.cgColor
        }
    }
}
