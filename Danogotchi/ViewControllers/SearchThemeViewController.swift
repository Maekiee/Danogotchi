import RxCocoa
import RxSwift
import SnapKit
import UIKit

final class SearchThemeViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = SearchThemeViewModel()

    private let titleText: UILabel = {
        let label = UILabel()
        label.text = "배경 테마를 골라주세요"
        label.font = .systemFont(ofSize: 28, weight: .semibold)
        label.textColor = .black
        return label
    }()

    private let textField: UnderlineTextField = {
        let tf = UnderlineTextField()
        tf.placeholder = "이미지를 검색해주세요"
        tf.font = .systemFont(ofSize: 16, weight: .regular)
        tf.isUserInteractionEnabled = true
        return tf
    }()
    
    private let submitButton = PrimaryFillButton(title: "시작하기")

    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configView()

        bind()
    }

    override func configHierarchy() {
        [
            titleText,
            textField,
            submitButton,
        ].forEach { view.addSubview($0) }
    }

    override func configLayout() {
        titleText.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        textField.snp.makeConstraints { make in
            make.top.equalTo(titleText.snp.bottom).offset(12)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(40)
        }
        
        submitButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }

    }

    override func configView() {

    }

}

extension SearchThemeViewController {
    private func bind() {
        let input = SearchThemeViewModel.Input()
        let output = viewModel.transform(input: input)
    }
}
