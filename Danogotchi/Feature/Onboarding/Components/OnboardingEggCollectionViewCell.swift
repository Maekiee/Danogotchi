import UIKit
import SnapKit

final class OnboardingEggCollectionViewCell: UICollectionViewCell {

    private let eggImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.caption
        label.textAlignment = .center
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
        [
            eggImageView,
            titleLabel
        ].forEach { contentView.addSubview($0) }
    }

    private func configLayout() {
        titleLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-AppSpacing.space8)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space4)
        }

        eggImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppSpacing.space12)
            make.centerX.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space16)
            make.bottom.equalTo(titleLabel.snp.top).offset(-AppSpacing.space4)
        }
    }

    private func configView() {
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = AppRadius.radius16
        // 선택 여부와 무관하게 두께는 고정 — 선택 시 칸 크기가 흔들리지 않도록
        contentView.layer.borderWidth = AppBorder.regular
        contentView.backgroundColor = AppColor.card
        isAccessibilityElement = true
    }

    func binding(with item: OnboardingEggItem) {
        if let type = item.petType {
            eggImageView.image = UIImage(named: type.eggImageName)
                ?? UIImage(systemName: "oval.portrait.fill")
            titleLabel.text = type.title
            titleLabel.textColor = AppColor.textPrimary
            accessibilityLabel = "\(type.title) 알"
            accessibilityTraits = item.isSelected ? [.image, .selected] : .image
        } else {
            eggImageView.image = UIImage(systemName: "questionmark")
            titleLabel.text = "개발중"
            titleLabel.textColor = AppColor.gray60
            accessibilityLabel = "개발중인 알"
            accessibilityTraits = [.image, .notEnabled]
        }

        eggImageView.tintColor = AppColor.textPrimary
        // 딤 처리 — 개발중 슬롯은 탭해도 반응하지 않는다
        contentView.alpha = item.isComingSoon ? 0.4 : 1.0
        contentView.layer.borderColor = item.isSelected
            ? AppColor.textPrimary.cgColor
            : AppColor.gray30.cgColor
    }
}
