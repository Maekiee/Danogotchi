import UIKit
import SwiftUI
import SnapKit
import RxSwift
import RxCocoa

final class MainWordCardCollectionViewCell: UICollectionViewCell {
    var disposeBag = DisposeBag()
    private let onSpeakerTapRelay = PublishRelay<Void>()
    private let onSaveTapRelay = PublishRelay<Void>()

    var onTouchTopIcon: Observable<Void> {
        return onSpeakerTapRelay.asObservable()
    }

    var onSaveVocab: Observable<Void> {
        return onSaveTapRelay.asObservable()
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
                make.horizontalEdges.equalToSuperview().inset(16)
                make.centerY.equalToSuperview()
                make.height.equalTo(200)
            }
        }
    }
    
    func configure(
        with item: CardDisplayable,
        parentVC: UIViewController,
        isSaved: Bool,
        showsSaveButton: Bool
    ) {
        if let hostingController, hostingController.parent == nil {
            parentVC.addChild(hostingController)
            hostingController.didMove(toParent: parentVC)
        }

        let newView = CardBlurView(
            title: item.cardTitle,
            subtitle: item.cardSubtitle,
            learningCount: item.cardChipText ?? 0,
            progress: item.cardAccuracy ?? 0.0,
            isSaved: isSaved,
            showsSaveButton: showsSaveButton,
            onSpeakerTap: { [weak self] in
                guard let self = self else { return }
                onSpeakerTapRelay.accept(())
            },
            onSaveTap: { [weak self] in
                guard let self = self else { return }
                onSaveTapRelay.accept(())
            }
        )

        hostingController?.rootView = newView
    }

    /// TTS 재생 상태만 갱신한다 — rootView가 struct라 나머지 표시 상태는 유지된다.
    func setSpeaking(_ isSpeaking: Bool) {
        hostingController?.rootView.isSpeaking = isSpeaking
    }
}

