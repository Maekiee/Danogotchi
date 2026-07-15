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
        label.font = AppFont.font(.bold, size: 20)
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
        button.configuration = config
        return button
    }()
    private let circleProgress = UICircleProgress()
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
            make.top.equalToSuperview().inset(8)
            make.leading.equalToSuperview().inset(8)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(lavelTag.snp.bottom).offset(AppSpacing.space12)
            make.horizontalEdges.equalToSuperview().inset(18)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.equalToSuperview().inset(18)
        }
        
        iconButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(10)
            make.trailing.equalToSuperview().offset(-18)
        }
        
        learningCountLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.leading.equalTo(subtitleLabel.snp.trailing).offset(8)
        }
      
    }
    
    private func configView() {
        backgroundColor = AppColor.backgroundBeige2
        layer.cornerRadius = AppRadius.radius20
    }
    
    
    func binding(with item: CardDisplayable) {
        titleLabel.text = item.cardTitle
        subtitleLabel.text = item.cardSubtitle
        
        if let learningCount = item.cardChipText {
            learningCountLabel.text = " | \(learningCount)번 학습"
        }
        
        if let accuracyValue = item.cardAccuracy {
            correctRateLabel.text = "\(accuracyValue)%"
            circleProgress.setProgress(accuracyValue, animated: false)
        }
        
        correctRateLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(10)
            make.trailing.equalToSuperview().inset(18)
            make.size.equalTo(40)
        }
    }
}

