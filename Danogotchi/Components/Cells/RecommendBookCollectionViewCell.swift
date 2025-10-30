import UIKit
import SnapKit
import RxSwift
import RxCocoa


final class RecommendBookCollectionViewCell: UICollectionViewCell {
    var disposeBag = DisposeBag()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = .boldSystemFont(ofSize: 18)
        return label
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
    
    private func configHierarchy() {
        contentView.addSubview(titleLabel)
    }
    
    private func configLayout() {
        titleLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-20)
            make.leading.equalToSuperview().offset(20)
        }
    }
    
    private func configView() {
        backgroundColor = AppColor.backgroundBeige2
        layer.borderWidth = 1.5
        layer.borderColor = AppColor.pointDarkGray.cgColor
        layer.cornerRadius = 20
        
        // 그림자 (cell의 layer에 적용)
        layer.shadowColor = AppColor.pointDarkGray.cgColor
        layer.shadowOpacity = 1
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 0
    }
    
    func binding(with item: Recommend) {
        titleLabel.text = item.title
    }
}

