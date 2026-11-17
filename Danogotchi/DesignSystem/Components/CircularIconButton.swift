import UIKit

final class CircularIconButton: UIButton {

    private static let diameter = AppSpacing.space24 * 2
    private static let symbolPointSize: CGFloat = 20
    private static let assetIconHeight = AppSpacing.space32

    convenience init(systemName: String) {
        let symbolConfig = UIImage.SymbolConfiguration(
            pointSize: Self.symbolPointSize,
            weight: .medium,
            scale: .default
        )
        self.init(icon: UIImage(systemName: systemName, withConfiguration: symbolConfig))
    }

    convenience init(assetNamed name: String) {
        guard let icon = UIImage(named: name) else {
            self.init(icon: nil)
            return
        }
        let height = Self.assetIconHeight
        let size = CGSize(width: height * icon.size.width / icon.size.height, height: height)
        let resized = UIGraphicsImageRenderer(size: size).image { _ in
            icon.draw(in: CGRect(origin: .zero, size: size))
        }.withRenderingMode(.alwaysTemplate)
        self.init(icon: resized)
    }

    private init(icon: UIImage?) {
        super.init(frame: .zero)
        var config = UIButton.Configuration.filled()
        config.image = icon
        config.baseForegroundColor = AppColor.white
        config.background.backgroundColor = AppColor.black.withAlphaComponent(0.25)
        config.cornerStyle = .capsule
        config.background.visualEffect = UIBlurEffect(style: .systemMaterialDark)
        configuration = config
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: Self.diameter, height: Self.diameter)
    }
}
