import UIKit
import SnapKit
import RxSwift
import RxCocoa


/// 재사용 가능한 셀
final class WordListCollectionViewCell: UICollectionViewCell {
    var disposeBag = DisposeBag()
    var onTouchTopIcon: Observable<Void> {
        return iconButton.rx.tap.asObservable()
    }
    
    let thumbnail: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    let titleLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    let subtitleLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    let iconButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.gray()
        config.image = UIImage(systemName: "ellipsis")
        button.configuration = config
        return button
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // contentView의 경계를 벗어나는 내용은 잘라냅니다.
        contentView.clipsToBounds = true
    }
    
    func configure(with item: WordModel) {
        titleLabel.text = item.word
        subtitleLabel.text = item.meaning
        let url = URL(string: item.thumbnail)
        thumbnail.kf.setImage(with: url)
    }
}


extension WordListCollectionViewCell: UIConfigurationLayout {
    func configHierarchy() {
        [
            thumbnail,
            titleLabel,
            subtitleLabel,
            iconButton
        ].forEach { contentView.addSubview($0) }
    }
    
    func configLayout() {
        thumbnail.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(120)
        }
        
        iconButton.snp.makeConstraints { make in
            make.top.equalTo(thumbnail.snp.bottom).offset(8)
            make.trailing.equalToSuperview().inset(4)
            make.size.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(thumbnail.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(4)
            make.trailing.lessThanOrEqualTo(iconButton.snp.leading).offset(-8)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(thumbnail.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel.snp.trailing).offset(8)
        }
    }
    
    func configView() {
        backgroundColor = .yellow
        
    }
}
