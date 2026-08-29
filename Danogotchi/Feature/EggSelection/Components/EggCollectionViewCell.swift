import UIKit
import SnapKit

final class EggCollectionViewCell: UICollectionViewCell {
    private let spriteView = PetSpriteView()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.label
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        configHierarchy()
        configLayout()
        configView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configHierarchy() {
        [spriteView, titleLabel].forEach { contentView.addSubview($0) }
    }

    private func configLayout() {
        spriteView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space8)
            make.height.equalTo(spriteView.snp.width)
        }

        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space8)
        }
    }

    private func configView() {
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = AppRadius.radius16
        contentView.layer.borderWidth = AppBorder.regular
        contentView.backgroundColor = .clear
        isAccessibilityElement = true
    }

    func binding(with item: EggItem) {
        spriteView.isHidden = item.isComingSoon
        titleLabel.isHidden = !item.isComingSoon

        if let type = item.petType {
            spriteView.renderStill(sheetName: type.sheetName(level: 0), clip: .idle, frameIndex: 1)
            accessibilityLabel = "\(type.title) 알"
            accessibilityTraits = item.isSelected ? [.staticText, .selected] : .staticText
        } else {
            titleLabel.text = "준비중"
            titleLabel.textColor = AppColor.gray60
            accessibilityLabel = "준비중인 알"
            accessibilityTraits = [.staticText, .notEnabled]
        }

        contentView.alpha = item.isComingSoon ? 0.4 : 1.0
        contentView.layer.borderColor = item.isSelected
            ? AppColor.textPrimary.cgColor
            : AppColor.gray30.cgColor
    }
}
