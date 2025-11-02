import UIKit
import SnapKit

final class QuisQuestionCard: UIView {
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.appWhite
        view.layer.cornerRadius = 30
        view.layer.borderWidth = 1.5
        view.layer.borderColor = UIColor.black.cgColor
        return view
    }()
    
    private let circleView: UIView = {
        let view = UIView()
        view.backgroundColor = AppColor.backgroundBeige
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1.5
        view.layer.borderColor = UIColor.black.cgColor
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Random Access"
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textColor = .black
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
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
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

// MARK: - Usage Example
extension QuisQuestionCard {
    static func createExample() -> QuisQuestionCard {
        let view = QuisQuestionCard()
        view.frame = CGRect(x: 0, y: 0, width: 400, height: 200)
        return view
    }
}
