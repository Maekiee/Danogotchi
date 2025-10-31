import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class MyBookDetailCollectionViewCell: UICollectionViewCell {
    var disposeBag = DisposeBag()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = .boldSystemFont(ofSize: 20)
        return label
    }()
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = AppColor.pointDarkGray
        label.font = .systemFont(ofSize: 14, weight: .regular)
        return label
    }()
    private let iconButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "ellipsis")
        config.baseForegroundColor = UIColor(red: 0.6, green: 0.6, blue: 0.62, alpha: 1.0)
        button.configuration = config
        return button
    }()
    private let chip: UIChip = {
        let view = UIChip(text: "")
        view.layer.cornerRadius = 10
        view.setFont(.systemFont(ofSize: 10))
        return view
    }()
    private let circleProgress = UICircleProgress()
    
    
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
            titleLabel,
            subtitleLabel,
            iconButton,
            chip,
            circleProgress,
        ].forEach { contentView.addSubview($0) }
    }
    
    private func configLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.horizontalEdges.equalToSuperview().inset(18)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.horizontalEdges.equalToSuperview().inset(18)
        }
        
        iconButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(10)
            make.trailing.equalToSuperview().offset(-18)
        }
        
        chip.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(10)
            make.leading.equalToSuperview().inset(18)
        }
        
//        circleProgress.snp.makeConstraints { make in
//            make.bottom.equalToSuperview().offset(10)
//            make.trailing.equalToSuperview().inset(-18)
//        }
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
    
    
    func binding(with item: CardDisplayable) {
        titleLabel.text = item.cardTitle
        subtitleLabel.text = item.cardSubtitle
        
        if let learningCount = item.cardChipText {
            chip.setText("\(learningCount)번 학습")
        }
        
        if let accuracyValue = item.cardAccuracy {
            circleProgress.setProgress(accuracyValue, animated: false)
        }
        
        circleProgress.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(10)
            make.trailing.equalToSuperview().inset(18)
            make.size.equalTo(40)
        }
    }
}

