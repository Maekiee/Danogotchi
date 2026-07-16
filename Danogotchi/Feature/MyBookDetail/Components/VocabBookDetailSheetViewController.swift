import UIKit
import SnapKit
import RxSwift
import RxCocoa

protocol VocabBookDetailSheetViewControllerDelegate: AnyObject {
    func sheetDidTapAddVocab()
    func sheetDidTapLearning()
}

final class VocabBookDetailSheetViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    weak var delegate: VocabBookDetailSheetViewControllerDelegate?
    
    private let addVocabButton = PrimaryFillButton(title: "단어 추가하기")
    private let learningButton = PrimaryFillButton(title: "학습하기")

    override func viewDidLoad() {
        super.viewDidLoad()

        configHierarchy()
        configLayout()
        configView()
        bind()
    }

    override func configHierarchy() {
        [
            addVocabButton,
            learningButton
        ].forEach { view.addSubview($0) }
    }
    override func configLayout() {
        addVocabButton.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space16)
            make.top.equalToSuperview().offset(AppSpacing.space24)
        }

        learningButton.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space16)
            make.top.equalTo(addVocabButton.snp.bottom).offset(AppSpacing.space12)
        }
    }
    override func configView() {
        view.backgroundColor = AppColor.background
    }
    
    private func bind() {
        addVocabButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.delegate?.sheetDidTapAddVocab()
            }.disposed(by: disposeBag)
        
        learningButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.delegate?.sheetDidTapLearning()
            }.disposed(by: disposeBag)
    }
}
