import UIKit
import SnapKit

final class QuisQuestionCard: UIView {
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.appWhite
        view.layer.cornerRadius = 30
        view.layer.borderWidth = AppBorder.regular
        view.layer.borderColor = UIColor.black.cgColor
        return view
    }()
    
    private let circleView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.backgroundBeige
        view.layer.cornerRadius = AppRadius.radius12
        view.layer.borderWidth = AppBorder.regular
        view.layer.borderColor = UIColor.black.cgColor
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Random Access"
        label.font = AppFont.title1
        label.textColor = AppColor.textPrimary
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Public Properties
    var text: String? {
        get { return titleLabel.text }
        set { titleLabel.text = newValue }
    }
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHierarchy()
        setupLayout()
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Setup
    private func setupHierarchy() {
        addSubview(containerView)
        containerView.addSubview(circleView)
        containerView.addSubview(titleLabel)
        
    }
    
    private func setupLayout() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        circleView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(AppSpacing.space16)
            make.leading.equalToSuperview().offset(AppSpacing.space16)
            make.width.height.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func setupView() {
        backgroundColor = .clear
    }
}
