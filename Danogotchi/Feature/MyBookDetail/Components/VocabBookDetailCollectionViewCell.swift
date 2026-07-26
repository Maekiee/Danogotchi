import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class VocabBookDetailCollectionViewCell: UICollectionViewCell {
    var disposeBag = DisposeBag()
    
    var onTouchIcon: Observable<Void> {
        return moreIconButton.rx.tap.asObservable()
    }
    
    var onSaveVocab: Observable<Void> {
        return saveVocabButton.rx.tap.asObservable()
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
        label.textColor = AppColor.textPrimary
        label.font = AppFont.footnote
        return label
    }()
    private let moreIconButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "ellipsis")
        config.baseForegroundColor = AppColor.black
        config.contentInsets = .zero
        button.configuration = config
        return button
    }()
    private let saveVocabButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "bookmark")
        config.baseForegroundColor = AppColor.black
        config.contentInsets = .zero
        button.configuration = config
        return button
    }()
    private let partOfSpeechTag: UIButton = {
        var container = AttributeContainer()
        container.font = AppFont.label

        var config = UIButton.Configuration.plain()
        config.attributedTitle = AttributedString("adv.", attributes: container)
        config.baseForegroundColor = AppColor.textPrimary
        config.cornerStyle = .capsule
        config.background.backgroundColor = .clear
        config.background.strokeColor = AppColor.textPrimary
        config.background.strokeWidth = AppBorder.regular
        config.contentInsets = NSDirectionalEdgeInsets(
            top: AppSpacing.space4,
            leading: AppSpacing.space12,
            bottom: AppSpacing.space4,
            trailing: AppSpacing.space12
        )

        let button = UIButton(configuration: config)
        button.isUserInteractionEnabled = false
        return button
    }()
    private let learningCountLabel: UILabel = {
        let label = UILabel()
        label.textColor = AppColor.textPrimary
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
            moreIconButton,
            saveVocabButton,
            correctRateLabel,
            partOfSpeechTag,
            learningCountLabel,
        ].forEach { contentView.addSubview($0) }
    }
    
    private func configLayout() {
        partOfSpeechTag.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(18)
            make.leading.equalToSuperview().inset(18)
        }

        moreIconButton.snp.makeConstraints { make in
            make.centerY.equalTo(partOfSpeechTag)
            make.trailing.equalToSuperview().inset(18)
        }
        
        saveVocabButton.snp.makeConstraints { make in
            make.centerY.equalTo(partOfSpeechTag)
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
    
    
    func binding(with item: CardDisplayable, isMyBook: Bool) {
        // 나의 단어장은 편집(ellipsis), 추천 단어장은 저장(bookmark)
        moreIconButton.isHidden = !isMyBook
        saveVocabButton.isHidden = isMyBook

        titleLabel.text = item.cardTitle
        subtitleLabel.text = item.cardSubtitle
        backgroundColor = UIColor(
            hue: CGFloat(abs(item.cardTitle.hashValue % 300)) / 360.0,
            saturation: 0.30,
            brightness: 0.95,
            alpha: 1.0
        )
        
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

