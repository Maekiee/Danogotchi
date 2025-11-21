import UIKit
import SwiftUI
import SnapKit
import RxSwift
import RxCocoa

/// 재사용 가능한 셀
final class MainWordCardCollectionViewCell: UICollectionViewCell {
    var disposeBag = DisposeBag()
    private let onSpeakerTapRelay = PublishRelay<Void>()
    private let onModifyTapRelay = PublishRelay<Void>()
    
    var onTouchTopIcon: Observable<Void> {
        return onSpeakerTapRelay.asObservable()
    }
    
    var onTouchImageIcon: Observable<Void> {
        return onModifyTapRelay.asObservable()
    }
    
    private var hostingController: UIHostingController<CardBlurView>?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        hostingSetup()
        configView()
    }
    
    private func configView() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func hostingSetup() {
        let cardBackgroundView = CardBlurView()
        hostingController = UIHostingController(rootView: cardBackgroundView)
        
        if let hostingView = hostingController?.view {
            hostingView.backgroundColor = .clear
            contentView.addSubview(hostingView)
            
            hostingView.snp.makeConstraints { make in
                make.horizontalEdges.equalToSuperview().inset(28)
                make.centerY.equalToSuperview()
                make.height.equalTo(180)
            }
        }
    }
    
    func configure(with item: CardDisplayable, parentVC: UIViewController) {
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
                guard let self = self else { return }
                onSpeakerTapRelay.accept(())
            },
            onModifyTap: { [weak self] in
                guard let self = self else { return }
                onModifyTapRelay.accept(())
            }
        )
        
        hostingController?.rootView = newView
    }
}

