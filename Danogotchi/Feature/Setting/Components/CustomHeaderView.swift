import UIKit

class CustomHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "CustomHeaderView"
    
    private let label: UILabel = {
        let label = UILabel()
        label.font = AppFont.font(.medium, size: 17)
        label.textColor = AppColor.textPrimary
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AppSpacing.space4)
            make.top.equalToSuperview().offset(AppSpacing.space8)
            make.bottom.equalToSuperview().offset(-AppSpacing.space8)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with text: String) {
        label.text = text
    }
}
