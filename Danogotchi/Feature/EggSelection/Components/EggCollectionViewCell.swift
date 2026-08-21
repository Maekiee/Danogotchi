import UIKit
import SnapKit

final class EggCollectionViewCell: UICollectionViewCell {

    private let spriteView = PetSpriteView()
    /// "개발중" 슬롯 8칸이 쓴다 — 알이 있는 칸은 이미지만 보여준다
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
            make.edges.equalToSuperview().inset(AppSpacing.space8)
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
            // 알은 레벨 0 시트에만 있다. 두 번째 칸이 튀어오르지 않은 온전한 포즈다.
            spriteView.renderStill(sheetName: type.sheetName(level: 0), clip: .idle, frameIndex: 1)
            accessibilityLabel = "\(type.title) 알"
            accessibilityTraits = item.isSelected ? [.staticText, .selected] : .staticText
        } else {
            titleLabel.text = "개발중"
            titleLabel.textColor = AppColor.gray60
            accessibilityLabel = "개발중인 알"
            accessibilityTraits = [.staticText, .notEnabled]
        }

        // 딤 처리 — 개발중 슬롯은 탭해도 반응하지 않는다
        contentView.alpha = item.isComingSoon ? 0.4 : 1.0
        contentView.layer.borderColor = item.isSelected
            ? AppColor.textPrimary.cgColor
            : AppColor.gray30.cgColor
    }
}
