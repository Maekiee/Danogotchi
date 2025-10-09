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
    
    let thumbnail: UIImageView = {
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
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = AppColor.textPrimaryColor
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.numberOfLines = 0
        
        return label
    }()
    
    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = AppColor.textSecondaryColor
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    let trailingIconButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "ellipsis")
        config.baseForegroundColor = UIColor(red: 0.6, green: 0.6, blue: 0.62, alpha: 1.0)
        button.configuration = config
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // contentView의 경계를 벗어나는 내용은 잘라냅니다.
        contentView.clipsToBounds = true
    }
    
    func configure(with item: CardDisplayable) {
        titleLabel.text = item.cardTitle
        subtitleLabel.text = item.cardSubtitle
        if let thumbnailUrl = item.cardThumbnail {
            thumbnail.kf.setImage(with: URL(string: thumbnailUrl))
        } else {
            thumbnail.isHidden = true
        }
       
    }
}


extension WordCardCollectionViewCell: UIConfigurationLayout {
    func configHierarchy() {
        [
            thumbnail,
            titleLabel,
            subtitleLabel,
            trailingIconButton
        ].forEach { contentView.addSubview($0) }
        
        /// TTS 추가시 사용
//        thumbnail.addSubview(imageIconButton)
    }
    
    func configLayout() {
        thumbnail.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.horizontalEdges.equalToSuperview().inset(6)
            make.height.equalTo(thumbnail.snp.width).multipliedBy(1.0/2.0)
//            make.height.equalTo(thumbnail.snp.width).multipliedBy(9.0/16.0)
        }
        
        /// TTS 추가시 사용
//        imageIconButton.snp.makeConstraints { make in
//            make.top.equalToSuperview().offset(16)
//            make.trailing.equalToSuperview().offset(-16)
//            make.size.equalTo(24)
//        }
        
        trailingIconButton.snp.makeConstraints { make in
            make.top.equalTo(thumbnail.snp.bottom).offset(8)
            make.trailing.equalToSuperview().offset(-16)
            make.size.equalTo(24)
        }
        
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(thumbnail.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(trailingIconButton.snp.leading).offset(-8)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(12)
        }
    }
    
    func configView() {
        backgroundColor = AppColor.cardColor
        self.layer.cornerRadius = 20
        self.clipsToBounds = true
        
    }
}
