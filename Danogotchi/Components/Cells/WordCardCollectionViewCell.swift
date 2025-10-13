import UIKit
import SnapKit
import RxSwift
import RxCocoa


/// 재사용 가능한 셀
final class WordCardCollectionViewCell: UICollectionViewCell {
    var disposeBag = DisposeBag()
    
    var onTouchTopIcon: Observable<Void> {
        return trailingIconButton.rx.tap.asObservable()
    }
    
    private let thumbnail: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true
        return imageView
    }()
    
    // TTS 추가시 사용
    //    let imageIconButton: UIButton = {
    //        let button = UIButton()
    //        var config = UIButton.Configuration.gray()
    //        config.image = UIImage(systemName: "ellipsis")
    //        button.configuration = config
    //        return button
    //    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = AppColor.textPrimaryColor
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.numberOfLines = 0
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = AppColor.textSecondaryColor
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    private let trailingIconButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "ellipsis")
        config.baseForegroundColor = UIColor(red: 0.6, green: 0.6, blue: 0.62, alpha: 1.0)
        button.configuration = config
        return button
    }()
    
    private let chip: UIChip = {
        let view = UIChip(text: "n번 학습")
        view.layer.cornerRadius = 10
        view.setFont(.systemFont(ofSize: 10))
        return view
    }()
    
    private let circleProgress = UICircleProgress()
    
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.clipsToBounds = true
    }
    
    func configure(with item: CardDisplayable, isSelected: Bool = false) {
        titleLabel.text = item.cardTitle
        subtitleLabel.text = item.cardSubtitle
        if let learningCount = item.cardChipText {
            chip.setText("\(learningCount)번 학습")
        }
        
        
        // 셀 스타일
        if isSelected {
            layer.borderColor = AppColor.primaryColor.cgColor
            layer.borderWidth = 2.0
        } else {
            layer.borderColor = UIColor.clear.cgColor
            layer.borderWidth = 0
        }
        
        // 이미지 있는 경우
        if let thumbnailUrl = item.cardThumbnail {
            thumbnail.isHidden = false
            chip.isHidden = false
            circleProgress.isHidden = false
            thumbnail.kf.setImage(with: URL(string: thumbnailUrl))
            
            thumbnail.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(6)
                make.horizontalEdges.equalToSuperview().inset(6)
                make.height.equalTo(thumbnail.snp.width).multipliedBy(1.0/2.0)
            }
            
            // titleLabel을 썸네일 아래에 위치시킵니다.
            titleLabel.snp.remakeConstraints { make in
                make.top.equalTo(thumbnail.snp.bottom).offset(8)
                make.leading.equalToSuperview().offset(16)
                make.trailing.lessThanOrEqualTo(trailingIconButton.snp.leading).offset(-8)
            }
            
            // trailingIconButton도 원래 위치로 되돌립니다.
            trailingIconButton.snp.remakeConstraints { make in
                make.top.equalTo(thumbnail.snp.bottom).offset(8)
                make.trailing.equalToSuperview().offset(-16)
                make.size.equalTo(24)
            }
            
            circleProgress.snp.remakeConstraints { make in
                make.bottom.trailing.equalToSuperview().inset(16)
                make.size.equalTo(40)
            }
            
            // subtitleLabel도 하단 고정 제약 조건을 다시 추가합니다.
            subtitleLabel.snp.remakeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(4)
                make.leading.equalToSuperview().offset(16)
                make.trailing.equalToSuperview().inset(16)
            }
            
            chip.snp.remakeConstraints { make in
                make.top.equalTo(subtitleLabel.snp.bottom).offset(20)
                make.leading.equalToSuperview().offset(16)
                make.bottom.equalToSuperview().inset(16)
                make.height.equalTo(20)
            }
        } else {
            // 이미지 없는 경우
            thumbnail.isHidden = true
            chip.isHidden = true
            circleProgress.isHidden = true
            
            /// titleLabel을 셀 상단에 위치시킵니다.
            titleLabel.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(16)
                make.leading.equalToSuperview().offset(16)
                make.trailing.lessThanOrEqualTo(trailingIconButton.snp.leading).offset(-8)
            }
            
            // trailingIconButton을 titleLabel 상단에 맞춥니다.
            trailingIconButton.snp.remakeConstraints { make in
                make.top.equalTo(titleLabel.snp.top).offset(-4)
                make.trailing.equalToSuperview().offset(-16)
                make.size.equalTo(24)
            }
            
            // subtitleLabel에서 하단 고정 제약 조건을 제거합니다.
            subtitleLabel.snp.remakeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(40)
                make.leading.equalToSuperview().offset(16)
                make.trailing.equalToSuperview().inset(16)
                make.bottom.equalToSuperview().inset(16)
            }
        }
    }
}



// MARK: Basic Config View
extension WordCardCollectionViewCell: UIConfigurationLayout {
    func configHierarchy() {
        [
            thumbnail,
            titleLabel,
            subtitleLabel,
            trailingIconButton,
            chip,
            circleProgress
        ].forEach { contentView.addSubview($0) }
        
    }
    
    func configLayout() { }
    
    func configView() {
        backgroundColor = AppColor.cardColor
        layer.cornerRadius = 20
        clipsToBounds = true
        
        circleProgress.setProgress(0.88, animated: false)
    }
}
