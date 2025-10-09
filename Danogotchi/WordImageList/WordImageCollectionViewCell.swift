import UIKit
import SnapKit
import Kingfisher

final class WordImageCollectionViewCell: UICollectionViewCell {
    static let identifier = "WordImageCollectionViewCell"
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    private let selectionOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.isHidden = true
        return view
    }()
    
    private let checkmarkIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "checkmark.circle.fill")
        iv.tintColor = .systemBlue
        iv.backgroundColor = .white
        iv.layer.cornerRadius = 12
        iv.clipsToBounds = true
        iv.isHidden = true
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .systemGray5
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
        contentView.layer.borderWidth = 0
        contentView.layer.borderColor = UIColor.clear.cgColor
        
        [imageView, selectionOverlay, checkmarkIcon].forEach {
            contentView.addSubview($0)
        }
        
        imageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        selectionOverlay.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        checkmarkIcon.snp.makeConstraints {
            $0.trailing.bottom.equalToSuperview().inset(8)
            $0.size.equalTo(24)
        }
    }
    
    func config(with imageUrl: String, isSelected: Bool) {
        imageView.kf.setImage(with: URL(string: imageUrl))
        setSelected(isSelected)
    }
    
    func setSelected(_ selected: Bool) {
        contentView.layer.borderWidth = selected ? 3 : 0
        contentView.layer.borderColor = selected ? UIColor.systemBlue.cgColor : UIColor.clear.cgColor
        selectionOverlay.isHidden = !selected
        checkmarkIcon.isHidden = !selected
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        setSelected(false)
    }
}
