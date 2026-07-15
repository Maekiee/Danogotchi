import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class VocabBookDetailCollectionViewCell: UICollectionViewCell {
    var disposeBag = DisposeBag()
    
    var onTouchIcon: Observable<Void> {
        return iconButton.rx.tap.asObservable()
    }
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = AppColor.textPrimary
        label.font = AppFont.title1
        label.numberOfLines = 2
        return label
    }()
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = AppColor.textSecondary
        label.font = AppFont.footnote
        return label
    }()
    private let iconButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "ellipsis")
        config.baseForegroundColor = UIColor(red: 0.6, green: 0.6, blue: 0.62, alpha: 1.0)
        config.contentInsets = .zero
        button.configuration = config
        return button
    }()
    private let lavelTag: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.layer.cornerRadius = 18
        label.layer.borderColor = AppColor.textPrimary.cgColor
        label.layer.borderWidth = AppBorder.regular
        label.textColor = AppColor.textPrimary
        label.font = AppFont.label
        label.clipsToBounds = true
        label.text = "H1"
        return label
    }()
    private let learningCountLabel: UILabel = {
        let label = UILabel()
        label.textColor = AppColor.textSecondary
        label.font = AppFont.footnote
        return label
    }()
    private let correctRateLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.largeDisplay
        label.textColor = AppColor.textPrimary
        return label
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
            titleLabel,
            subtitleLabel,
            iconButton,
            correctRateLabel,
            lavelTag,
            learningCountLabel,
        ].forEach { contentView.addSubview($0) }
    }
    
    private func configLayout() {
        lavelTag.snp.makeConstraints { make in
            make.size.equalTo(36)
            make.top.equalToSuperview().inset(18)
            make.leading.equalToSuperview().inset(18)
        }

        iconButton.snp.makeConstraints { make in
            make.centerY.equalTo(lavelTag)
            make.trailing.equalToSuperview().inset(18)
        }

        correctRateLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(18)
            make.bottom.equalToSuperview().inset(20)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(18)
            make.bottom.equalToSuperview().inset(20)
        }

        learningCountLabel.snp.makeConstraints { make in
            make.leading.equalTo(subtitleLabel.snp.trailing)
            make.centerY.equalTo(subtitleLabel)
            make.trailing.lessThanOrEqualTo(correctRateLabel.snp.leading).offset(-8)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(18)
            make.bottom.equalTo(subtitleLabel.snp.top).offset(-6)
            make.trailing.lessThanOrEqualTo(correctRateLabel.snp.leading).offset(-8)
        }

        correctRateLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    private func configView() {
        backgroundColor = AppColor.backgroundBeige2
        layer.cornerRadius = AppRadius.radius20
    }
    
    
    func binding(with item: CardDisplayable) {
        titleLabel.text = item.cardTitle
        subtitleLabel.text = item.cardSubtitle
        
        if let learningCount = item.cardChipText {
            learningCountLabel.text = " · \(learningCount)번 학습"
        }

        if let accuracyValue = item.cardAccuracy {
            let percentText = NSMutableAttributedString(
                string: "\(Int(accuracyValue * 100))",
                attributes: [.font: AppFont.largeDisplay]
            )
            percentText.append(NSAttributedString(
                string: "%",
                attributes: [.font: AppFont.font(.bold, size: 14)]
            ))
            correctRateLabel.attributedText = percentText
        }
    }
}

