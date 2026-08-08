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
    private let vocabTypeTag: PaddingLabel = {
        let label = PaddingLabel()
        label.textAlignment = .center
        label.contentInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        label.layer.cornerRadius = 12
        label.layer.borderColor = AppColor.textPrimary.cgColor
        label.layer.borderWidth = AppBorder.regular
        label.textColor = AppColor.textPrimary
        label.font = AppFont.label
        label.text = ""
        return label
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
            vocabTypeTag,
            learningCountLabel,
        ].forEach { contentView.addSubview($0) }
    }
    
    private func configLayout() {
        vocabTypeTag.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(18)
            make.leading.equalToSuperview().inset(18)
            make.height.equalTo(24)
        }

        moreIconButton.snp.makeConstraints { make in
            make.centerY.equalTo(vocabTypeTag)
            make.trailing.equalToSuperview().inset(18)
        }
        
        saveVocabButton.snp.makeConstraints { make in
            make.centerY.equalTo(vocabTypeTag)
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
        layer.cornerRadius = AppRadius.radius20
    }
    
    
    func binding(with item: CardDisplayable, isMyBook: Bool, isSaved: Bool = false) {
        moreIconButton.isHidden = !isMyBook
        saveVocabButton.isHidden = isMyBook
        saveVocabButton.configuration?.image = UIImage(
            systemName: isSaved ? "bookmark.fill" : "bookmark"
        )

        titleLabel.text = item.cardTitle
        subtitleLabel.text = item.cardSubtitle
        backgroundColor = AppColor.pastel(for: item.cardTitle)
        
        if let partOfSpeech = item.cardPartOfSpeech {
            vocabTypeTag.text = partOfSpeech
            vocabTypeTag.isHidden = false
        } else {
            vocabTypeTag.text = nil
            vocabTypeTag.isHidden = true
        }

        if let learningCount = item.cardChipText {
            learningCountLabel.text = " · \(learningCount)번 학습"
        } else {
            learningCountLabel.text = nil
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
        } else {
            correctRateLabel.attributedText = nil
        }
    }
}

