import UIKit
import SnapKit
import RealmSwift
import RxSwift
import RxCocoa

final class WordTabViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: WordTabViewModel
    private let userInfo = UserInfoManager.shared
    
    init(viewModel: WordTabViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let addWordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = .systemBlue
        return button
    }()
    private let showWordBookButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "line.3.horizontal"), for: .normal)
        button.tintColor = .systemBlue
        return button
    }()
    private let noWordBookLabel: UILabel = {
        let label = UILabel()
        label.text = "학습할 단어장을 만들어 주세요"
        label.textColor = .black
        return label
    }()
    private let goCreateWordBookButton = PrimaryFillButton(title: "단어장 만들기")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configView()
        
        bind()
    }
    
    override func configHierarchy() {
        [
            noWordBookLabel,
            goCreateWordBookButton
        ].forEach { view.addSubview($0) }
    }
    
    override func configLayout() {
        noWordBookLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        goCreateWordBookButton.snp.makeConstraints { make in
            make.top.equalTo(noWordBookLabel.snp.bottom).offset(8)
            make.horizontalEdges.equalToSuperview().inset(24)
            make.height.equalTo(40)
        }
    }
    
    override func configView() {
        let firstBarButton = UIBarButtonItem(customView: showWordBookButton)
        let secondBarButton = UIBarButtonItem(customView: addWordButton)
        navigationItem.rightBarButtonItems = [firstBarButton, secondBarButton]
        
        // 선택한 단어장의 타이틀 명
//        navigationItem.title = "토익 테스트 영단어"
    }
}

extension WordTabViewController {
    private func bind() {
        let input = WordTabViewModel.Input(
            viewWillAppear:  rx.methodInvoked(#selector(viewWillAppear)).map { _ in }
        )
        let output = viewModel.transform(input: input)
        
        output.selectedWordBookId
            .drive(with: self) { owner, hasWordBook in
                owner.addWordButton.isHidden = hasWordBook
                owner.showWordBookButton.isHidden = hasWordBook
                
                owner.noWordBookLabel.isHidden = !hasWordBook
                owner.goCreateWordBookButton.isHidden = !hasWordBook
            }
            .disposed(by: disposeBag)
        
        output.bookTitle
            .drive(navigationItem.rx.title)
            .disposed(by: disposeBag)
        
        addWordButton.rx.tap
            .withLatestFrom(output.bookTitle)
            .do { text in
                print("값이 왓나..?: \(text)")
            }
            .bind(with: self) { owner, bookTitle in
                guard let bookId = owner.userInfo.selectedWordBook else { return }
                let bookObjectId = try? ObjectId(string: bookId)
                // 여기에는 선택한 단어장의 pk 주입
                let vm = AddWordViewModel(isWordBookId: bookObjectId)
                let vc = UINavigationController(rootViewController: AddWordViewController(
                    viewModel: vm,
                    initWordBookTitle: bookTitle)
                )
                vc.modalPresentationStyle = .fullScreen
                owner.present(vc, animated: true)
            }.disposed(by: disposeBag)
        
        showWordBookButton.rx.tap
            .bind(with: self) { owner, _ in
                let vc = WordBookListViewController()
                owner.present(vc, animated: true)
            }.disposed(by: disposeBag)
        
        
        goCreateWordBookButton.rx.tap
            .bind(with: self) { owner, _ in
                let vm = AddWordViewModel()
                let vc = UINavigationController(rootViewController: AddWordViewController(viewModel: vm))
                vc.modalPresentationStyle = .fullScreen
                owner.present(vc, animated: true)
            }.disposed(by: disposeBag)
        
    }
}
