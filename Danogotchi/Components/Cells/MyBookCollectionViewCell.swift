import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class MyBookCollectionViewCell: UICollectionViewCell {
    var disposeBag = DisposeBag()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "나의 단어장"
        label.textColor = .black
        label.font = .boldSystemFont(ofSize: 24)
        return label
    }()
    private let checkIcon: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(systemName: "checkmark.circle.fill")
        view.tintColor = AppColor.oxfordBlue
        view.backgroundColor = AppColor.backgroundBeige2
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()
    private let imageIcon: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "book_image_my")
        view.contentMode = .scaleAspectFill
        return view
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
        [
            imageIcon,
            titleLabel,
            checkIcon
        ].forEach { contentView.addSubview($0) }
    }
    
    private func configLayout() {
        
        imageIcon.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(20)
            make.trailing.lessThanOrEqualTo(titleLabel.snp.leading).offset(-4)
            make.size.equalTo(80)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        checkIcon.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().inset(12)
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
    
    
    func binding(with: WordBook, isSelected: Bool) {
        checkIcon.isHidden = !isSelected
    }
}
