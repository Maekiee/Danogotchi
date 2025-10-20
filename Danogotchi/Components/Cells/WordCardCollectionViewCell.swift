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
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    // TTS 추가시 사용
    let imageIconButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.gray()
        config.image = UIImage(systemName: "ellipsis")
        config.baseForegroundColor = UIColor.black.withAlphaComponent(0.8)
        config.background.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        config.contentInsets = NSDirectionalEdgeInsets(
            top: 4, leading: 12, bottom: 4, trailing: 12)
        
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
                pointSize: 14,
                weight: .regular
            )
        
        config.background.cornerRadius = 16
        config.background.visualEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        button.isHidden = false
        button.configuration = config
        
        
        return button
    }()
    
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
        
        if let accuracyValue = item.cardAccuracy {
            circleProgress.setProgress(accuracyValue, animated: false)
        }
        
        // 셀 선택 스타일
        if isSelected {
            layer.borderColor = AppColor.primaryColor.cgColor
            layer.borderWidth = 2.0
        } else {
            layer.borderColor = UIColor.clear.cgColor
            layer.borderWidth = 0
        }
        
        // --- 레이아웃 분기 처리 ---
        let hasThumbnail = item.cardThumbnail != nil
        thumbnail.isHidden = !hasThumbnail
        chip.isHidden = !hasThumbnail
        circleProgress.isHidden = !hasThumbnail
        
        if hasThumbnail {
            // [이미지가 있는 경우]
            thumbnail.kf.setImage(with: URL(string: item.cardThumbnail!))
            
            // titleLabel의 상단을 thumbnail의 하단에 연결
            titleLabel.snp.remakeConstraints { make in
                make.top.equalTo(thumbnail.snp.bottom).offset(8)
                make.leading.equalToSuperview().offset(16)
                make.trailing.lessThanOrEqualTo(trailingIconButton.snp.leading).offset(-8)
            }
            
            // trailingIconButton의 상단을 titleLabel의 상단과 맞춤
            trailingIconButton.snp.remakeConstraints { make in
                make.top.equalTo(titleLabel.snp.top)
                make.trailing.equalToSuperview().offset(-16)
                make.size.equalTo(24)
            }
            
            // [중요] 셀의 최종 높이를 결정하는 하단 제약조건
            // chip의 하단을 셀의 하단에 연결하여 수직 경로를 완성합니다.
            chip.snp.makeConstraints { make in
                make.bottom.equalToSuperview().inset(16)
            }
            circleProgress.snp.makeConstraints { make in
                make.bottom.equalToSuperview().inset(16)
            }
            
        } else {
            // [이미지가 없는 경우]
            
            // titleLabel의 상단을 셀의 상단에 연결
            titleLabel.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(16)
                make.leading.equalToSuperview().offset(16)
                make.trailing.lessThanOrEqualTo(trailingIconButton.snp.leading).offset(-8)
            }
            
            // trailingIconButton의 상단을 titleLabel의 상단과 맞춤
            trailingIconButton.snp.remakeConstraints { make in
                make.top.equalTo(titleLabel.snp.top).offset(-4)
                make.trailing.equalToSuperview().offset(-16)
                make.size.equalTo(24)
            }
            
            // [중요] 셀의 최종 높이를 결정하는 하단 제약조건
            // subtitleLabel의 하단을 셀의 하단에 연결하여 수직 경로를 완성합니다.
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
        
        thumbnail.addSubview(imageIconButton)
    }
    
    func configLayout() {
        
        // --- 고정 제약 조건들 ---
        thumbnail.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.horizontalEdges.equalToSuperview().inset(6)
            make.height.equalTo(thumbnail.snp.width).multipliedBy(1.0/2.0)
        }
        
        imageIconButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }
        
        trailingIconButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.size.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(trailingIconButton.snp.leading).offset(-8)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
        }
        
        chip.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(20)
        }
        
        circleProgress.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.size.equalTo(40)
        }
        
    }
    
    func configView() {
        backgroundColor = AppColor.cardColor
        layer.cornerRadius = 20
        clipsToBounds = true
    }
}
