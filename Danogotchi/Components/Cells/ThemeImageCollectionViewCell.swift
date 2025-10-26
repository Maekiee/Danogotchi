import UIKit
import SnapKit
import RxSwift
import RxCocoa


final class ThemeImageCollectionViewCell: UICollectionViewCell {
    var disposeBag = DisposeBag()
    
    private let thumbnail: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        contentView.addSubview(thumbnail)
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
