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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configBind(with item: ThemeImageViewData) {
        thumbnail.kf.setImage(with: URL(string: item.thumbnailUrl))
    }
    
    private func configHierarchy() {
        contentView.addSubview(thumbnail)
    }
    
    private func configLayout() {
        thumbnail.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func configView() {
        backgroundColor = .systemBlue
        layer.cornerRadius = 20
        clipsToBounds = true
    }
    
}
