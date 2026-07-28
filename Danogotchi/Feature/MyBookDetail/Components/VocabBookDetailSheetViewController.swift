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
    
    private let editVocabButton = PrimaryFillButton(title: "수정하기")
    private let deleteVocabButton = PrimaryFillButton(title: "삭제하기")

    override func viewDidLoad() {
        super.viewDidLoad()

        configHierarchy()
        configLayout()
        configView()
        bind()
    }

    override func configHierarchy() {
        [
            editVocabButton,
            deleteVocabButton
        ].forEach { view.addSubview($0) }
    }
    override func configLayout() {
        editVocabButton.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space16)
            make.top.equalToSuperview().offset(AppSpacing.space24)
        }

        deleteVocabButton.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space16)
            make.top.equalTo(editVocabButton.snp.bottom).offset(AppSpacing.space12)
        }
    }
    override func configView() {
        view.backgroundColor = AppColor.background
    }
    
    private func bind() {
        editVocabButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.delegate?.sheetDidTapAddVocab()
            }.disposed(by: disposeBag)
        
        deleteVocabButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.delegate?.sheetDidTapLearning()
            }.disposed(by: disposeBag)
        
        
    }
}
