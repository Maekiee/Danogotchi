import UIKit
import SnapKit



final class VocabTopicCardCollectionViewCell: UICollectionViewCell {
    private let textLabel: UILabel = {
        let label = UILabel()
        label.textColor = AppColor.black
        label.font = AppFont.label
        return label
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
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
            textLabel
        ].forEach { contentView.addSubview($0) }
    }
    
    private func configLayout() {
        textLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
    
    private func configView() {
        
    }
    
    func binding(with item: LibraryViewController.BookTopic) {
        textLabel.text = item.title
    }
    
}
