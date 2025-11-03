import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Kingfisher

final class ThemeImageCollectionViewCell: UICollectionViewCell {
    var disposeBag = DisposeBag()
    
    private let thumbnail: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    private let selectionOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.isHidden = true
        return view
    }()
    
    private let checkmarkIcon: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(systemName: "checkmark.circle.fill")
        view.tintColor = AppColor.appWhite
        view.backgroundColor = AppColor.oxfordBlue
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        configHierarchy()
        configLayout()
        configView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        thumbnail.image = nil
        setSelected(false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configBind(with item: ThemeImageViewData, isSelected: Bool) {
        thumbnail.kf.setImage(with: URL(string: item.thumbnailUrl))
        setSelected(isSelected)
    }
    
    private func configHierarchy() {
        [
            thumbnail,
            selectionOverlay,
            checkmarkIcon,
        ].forEach { contentView.addSubview($0) }
    }
    
    private func configLayout() {
        thumbnail.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        selectionOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        checkmarkIcon.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(8)
            make.size.equalTo(24)
        }
    }
    
    private func configView() {
        backgroundColor = .systemGray5
        layer.cornerRadius = 12
        clipsToBounds = true
        
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true //

    }
    
    
    func setSelected(_ selected: Bool) {
        contentView.layer.borderWidth = selected ? 3 : 0
        contentView.layer.borderColor = selected ? AppColor.appWhite.cgColor : UIColor.clear.cgColor
        selectionOverlay.isHidden = !selected
        checkmarkIcon.isHidden = !selected
    }
}
