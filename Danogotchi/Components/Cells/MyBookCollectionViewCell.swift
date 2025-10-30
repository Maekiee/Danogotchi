import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class MyBookCollectionViewCell: UICollectionViewCell {
    var disposeBag = DisposeBag()
    
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
    
    private func configHierarchy() {
        
    }
    
    private func configLayout() {
        
    }
    
    private func configView() {
        layer.borderWidth = 2
        layer.borderColor = UIColor.systemGreen.cgColor
    }
    
    func binding(with: MyBook) {
        
    }
}
