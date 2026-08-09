import UIKit
import SnapKit

final class OnboardingInterestCollectionViewCell: UICollectionViewCell {

    private let icon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.label
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

    override func layoutSubviews() {
        super.layoutSubviews()
        // 캡슐 — 높이가 바뀌어도 항상 반원 모서리를 유지한다
        contentView.layer.cornerRadius = contentView.bounds.height / 2
    }

    private func configHierarchy() {
        [
            icon,
            titleLabel
        ].forEach { contentView.addSubview($0) }
    }

    private func configLayout() {
        // leading → trailing이 끊기지 않아야 셀 너비가 내용에 맞게 계산된다
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppSpacing.space12)
            make.centerY.equalToSuperview()
            make.size.equalTo(18)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(AppSpacing.space4)
            make.trailing.equalToSuperview().offset(-AppSpacing.space12)
            make.centerY.equalToSuperview()
        }
    }

    private func configView() {
        contentView.clipsToBounds = true
        // 선택 여부와 무관하게 두께는 고정 — 선택 시 캡슐 너비가 흔들리지 않도록
        contentView.layer.borderWidth = AppBorder.regular
    }

    func binding(with item: OnboardingInterestItem) {
        icon.image = UIImage(named: item.topic.icon)?
            .withRenderingMode(.alwaysTemplate)
        titleLabel.text = item.topic.title
        setSelected(item.isSelected, topic: item.topic)
    }

    private func setSelected(_ selected: Bool, topic: BookTopic) {
        contentView.backgroundColor = selected ? topic.color : AppColor.white
        contentView.layer.borderColor = selected
            ? AppColor.textPrimary.cgColor
            : AppColor.gray30.cgColor

        let contentColor = selected ? AppColor.textPrimary : AppColor.gray60
        icon.tintColor = contentColor
        titleLabel.textColor = contentColor
    }
}
