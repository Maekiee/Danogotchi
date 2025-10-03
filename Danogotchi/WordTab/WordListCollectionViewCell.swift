import UIKit
import SnapKit


/// 재사용 가능한 셀
/// 단어 리스트, 단어장 리스트, 학습완료 화면 단어 리스트 등등
final class WordListCollectionViewCell: UICollectionViewCell {
    static let id = "WordListCollectionViewCell"
    let thumbnail = UIImageView()
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
            make.top.equalToSuperview().offset(4)
            make.horizontalEdges.equalToSuperview().offset(4)
            make.height.equalTo(100)
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
