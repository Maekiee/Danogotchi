import RxCocoa
import RxSwift
import SnapKit
import UIKit


protocol StudyReportViewControllerDelegate: AnyObject {
    func studyReportDidTapClose()
}

final class StudyReportViewController: BaseViewController {

    weak var delegate: StudyReportViewControllerDelegate?

    private let disposeBag = DisposeBag()
    private let viewModel: StudyReportViewModel

    // MARK: - UI 프로퍼티
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "학습 리포트 화면 입니다."
        label.font = AppFont.title2
        label.textColor = AppColor.textPrimary
        label.textAlignment = .center
        return label
    }()

    init(viewModel: StudyReportViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @MainActor
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configView()
        bind()
    }

    override func configHierarchy() {
        view.addSubview(placeholderLabel)
    }

    override func configLayout() {
        placeholderLabel.snp.makeConstraints { make in
            make.center.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview().inset(AppSpacing.space20)
        }
    }

    override func configView() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"), style: .plain, target: nil, action: nil
        )
    }
}

extension StudyReportViewController {
    private func bind() {
        // Output이 아직 비어 있어 결과를 받지 않는다 — 리포트 데이터가 생기면 let output = ...
        _ = viewModel.transform(input: StudyReportViewModel.Input())

        navigationItem.leftBarButtonItem?.rx.tap
            .bind(with: self) { owner, _ in
                owner.delegate?.studyReportDidTapClose()
            }.disposed(by: disposeBag)
    }
}
