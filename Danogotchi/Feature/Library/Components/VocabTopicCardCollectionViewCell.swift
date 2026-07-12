import UIKit
import SnapKit
import RxSwift
import RxCocoa


final class VocabTopicCardCollectionViewCell: UICollectionViewCell {
    var disposeBag = DisposeBag()
    
    var buttonTap: ControlEvent<Void> {
        return button.rx.tap
    }
    
    private let textLabel: UILabel = {
        let label = UILabel()
        label.textColor = AppColor.textPrimary
        label.font = AppFont.largeDisplay
        return label
    }()
    private let icon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.tintColor = AppColor.textPrimary
        return imageView
    }()
    private let button: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(
            systemName: "arrow.right",
            withConfiguration: UIImage.SymbolConfiguration(
                pointSize: 11, weight: .medium
            )
        )
        
        config.baseForegroundColor = AppColor.textPrimary
        config.cornerStyle = .capsule
        config.background.backgroundColor = .clear
        config.background.strokeColor = AppColor.textPrimary
        config.background.strokeWidth = 2
        
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
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
            textLabel,
            icon,
            button
        ].forEach { contentView.addSubview($0) }
    }
    
    private func configLayout() {
        textLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-AppSpacing.space16)
            make.leading.equalToSuperview().offset(AppSpacing.space16)
        }
        
        icon.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppSpacing.space16)
            make.leading.equalToSuperview().offset(AppSpacing.space16)
        }
        
        button.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppSpacing.space16)
            make.trailing.equalToSuperview().offset(-AppSpacing.space16)
            make.size.equalTo(40)
        }
    }
    
    private func configView() {
        backgroundColor = AppColor.lavender
        layer.cornerRadius = AppRadius.radius20
        layer.masksToBounds = true
    }
    
    func binding(with item: BookTopic) {
        icon.image = UIImage(named: item.icon)?
            .withRenderingMode(.alwaysTemplate)
        textLabel.text = item.title
    }
    
}
