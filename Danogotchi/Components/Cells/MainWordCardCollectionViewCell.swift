import UIKit
import SwiftUI
import SnapKit
import RxSwift
import RxCocoa

/// 재사용 가능한 셀
final class MainWordCardCollectionViewCell: UICollectionViewCell {
    var disposeBag = DisposeBag()
    
    var onTouchTopIcon: Observable<Void> {
        return speakerButton.rx.tap.asObservable()
    }
    
    var onTouchImageIcon: Observable<Void> {
        return modifiyButton.rx.tap.asObservable()
    }
    
    let modifiyButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.gray()
        config.image = UIImage(systemName: "ellipsis")
        config.baseForegroundColor = UIColor.black.withAlphaComponent(0.8)
        config.background.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        config.contentInsets = NSDirectionalEdgeInsets(
            top: 4, leading: 12, bottom: 4, trailing: 12)
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
                pointSize: 14,
                weight: .regular
            )
        config.background.cornerRadius = 16
        config.background.visualEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        button.isHidden = false
        button.configuration = config
        return button
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = AppColor.textPrimaryColor
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.numberOfLines = 0
        return label
    }()
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = AppColor.textSecondaryColor
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    private let speakerButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "speaker.wave.2.fill")
        config.baseForegroundColor = UIColor(red: 0.6, green: 0.6, blue: 0.62, alpha: 1.0)
        button.configuration = config
        return button
    }()
    private let chip: UIChip = {
        let view = UIChip(text: "n번 학습")
        view.layer.cornerRadius = 10
        view.setFont(.systemFont(ofSize: 10))
        return view
    }()
    private let circleProgress = UICircleProgress()
    
    // MARK: - SwifUI
    private var hostingController: UIHostingController<CardBlurView>?
    private var isSetup = false
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
        
//        hostingController?.willMove(toParent: nil)
//        hostingController?.view.removeFromSuperview()
//        hostingController?.removeFromParent()
//        hostingController = nil
//        isHostingControllerSetup = false
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
//        configHierarchy()
//        configLayout()
        configView()
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        guard !isSetup else { return }
                
        // SwiftUI 블러 배경 추가
        let cardBackgroundView = CardBlurView()
        let controller = UIHostingController(rootView: cardBackgroundView)
        
        
        controller.sizingOptions = []
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.backgroundColor = .clear
//        controller.view.layer.shouldRasterize = true
//        controller.view.layer.rasterizationScale = UIScreen.main.scale
        
        
        self.hostingController = controller
        contentView.addSubview(controller.view)
        
        controller.view.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(28)
            make.top.equalToSuperview().offset((contentView.bounds.height - 180) / 2)
//            make.centerY.equalToSuperview()
            make.height.equalTo(180).priority(.required)
        }
        
        // 추가
        configHierarchy()
        configLayout()
        
        isSetup = true
    }
    
    func setupHostingController(with parentVC: UIViewController) {
        guard let controller = hostingController, controller.parent == nil else { return }
        parentVC.addChild(controller)
        controller.didMove(toParent: parentVC)
    }
    
    func configure(with item: CardDisplayable, isSelected: Bool = false) {
        
        let newView = CardBlurView(
            title: item.cardTitle,
            subtitle: item.cardSubtitle,
            learningCount: item.cardChipText ?? 0,
            progress: item.cardAccuracy ?? 0.0,
            onSpeakerTap: { [weak self] in
                guard let _ = self else { return }
                TTSManager.shared.speak(item.cardTitle)
            },
            onModifyTap: { [weak self] in
                guard let self = self else { return }
                onTouchImageIcon
            }
        )
        
        hostingController?.rootView = newView
        
        
//        titleLabel.text = item.cardTitle
//        subtitleLabel.text = item.cardSubtitle
//        
//        if let learningCount = item.cardChipText {
//            chip.setText("\(learningCount)번 학습")
//        }
//        
//        if let accuracyValue = item.cardAccuracy {
//            circleProgress.setProgress(accuracyValue, animated: false)
//        }
        
        // 발음 듣기 아이콘 상태
//        TTSManager.shared.currentSpeakingText
//            .map { $0 == item.cardTitle }
//            .bind(with: self) { owner, isPlayingThisCell in
//                // tts 플레이
//                var config = owner.speakerButton.configuration
//                config?.baseForegroundColor = isPlayingThisCell
//                ? AppColor.primaryColor
//                : UIColor(red: 0.6, green: 0.6, blue: 0.62, alpha: 1.0)
//                owner.speakerButton.configuration = config
//            }.disposed(by: disposeBag)
    }
}



// MARK: Basic Config View
extension MainWordCardCollectionViewCell: UIConfigurationLayout {
    func configHierarchy() {
//        guard let containerView = hostingController?.view else { return }
        [
            modifiyButton,
//            titleLabel,
//            subtitleLabel,
//            speakerButton,
//            chip,
//            circleProgress
        ].forEach { contentView.addSubview($0) }
    }
    
    func configLayout() {
        guard let blurView = hostingController?.view else { return }
        
//        modifiyButton.snp.makeConstraints { make in
//            make.top.equalTo(blurView).offset(-28)
//            make.trailing.equalToSuperview().offset(-12)
//        }
        
//        titleLabel.snp.makeConstraints { make in
//            make.top.equalTo(blurView).offset(20)
//            make.leading.equalTo(blurView).offset(20)
//            make.trailing.lessThanOrEqualTo(speakerButton.snp.leading).offset(-8)
//        }
        
//        speakerButton.snp.makeConstraints { make in
//            make.top.equalTo(blurView)
//            make.trailing.equalToSuperview().offset(-20)
//            make.size.equalTo(24)
//        }
        
//        subtitleLabel.snp.makeConstraints { make in
//            make.top.equalTo(titleLabel.snp.bottom).offset(8)
//            make.leading.equalTo(titleLabel)
//            make.trailing.equalTo(speakerButton)
//        }
        
//        chip.snp.makeConstraints { make in
//            make.leading.equalTo(titleLabel)
//            make.bottom.equalToSuperview().offset(-20)
//            make.height.equalTo(20)
//        }
        
//        circleProgress.snp.makeConstraints { make in
//            make.trailing.equalTo(speakerButton)
//            make.bottom.equalToSuperview().offset(-20)
//            make.size.equalTo(40)
//        }
        
    }
    
    func configView() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        layer.borderWidth = 2
        layer.borderColor = UIColor.systemGreen.cgColor
    }
}

