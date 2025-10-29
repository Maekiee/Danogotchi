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
    
    // MARK: -UI 프로퍼티
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
    private let speakerButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "speaker.wave.2.fill")
        config.baseForegroundColor = UIColor(red: 0.6, green: 0.6, blue: 0.62, alpha: 1.0)
        button.configuration = config
        return button
    }()
    
    // MARK: - SwifUI
    private var hostingController: UIHostingController<CardBlurView>?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configView()
    }
    
    private func configView() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
//        layer.borderWidth = 2
//        layer.borderColor = UIColor.systemGreen.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with item: CardDisplayable, parentVC: UIViewController) {
        guard hostingController == nil else { return }
                
        let cardBackgroundView = CardBlurView()
        let controller = UIHostingController(rootView: cardBackgroundView)
        
        controller.view.backgroundColor = .clear
        
        self.hostingController = controller
        contentView.addSubview(controller.view)
        
        controller.view.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(28)
            make.centerY.equalToSuperview()
            make.height.equalTo(180)
        }
        
        
        if let hostingController, hostingController.parent == nil {
            parentVC.addChild(hostingController)
            hostingController.didMove(toParent: parentVC)
        }
        
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
//                modifiyButton.rx.tap
                print("셀에서 프린트")
            }
        )
        
        hostingController?.rootView = newView
    }
}

