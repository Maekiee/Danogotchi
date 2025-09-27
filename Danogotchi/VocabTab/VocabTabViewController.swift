import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class VocabTabViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = VocabTabViewModel()
    
    private let addWordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = .systemBlue
        return button
    }()
    
    private let shoWordBookButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "line.3.horizontal"), for: .normal)
        button.tintColor = .systemBlue
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configView()
        
        bind()
    }
    
    override func configHierarchy() {
        
    }
    
    override func configLayout() {
        
    }
    
    override func configView() {
        let firstBarButton = UIBarButtonItem(customView: shoWordBookButton)
        let secondBarButton = UIBarButtonItem(customView: addWordButton)
        navigationItem.rightBarButtonItems = [firstBarButton, secondBarButton]
        
        navigationItem.title = "토익 테스트 영단어"
    }
}

extension VocabTabViewController {
    private func bind() {
        let input = VocabTabViewModel.Input()
        let output = viewModel.transform(input: input)
        
        
        addWordButton.rx.tap
            .bind(with: self) { owner, _ in
                let vc = UINavigationController(rootViewController: AddWordViewController())
                vc.modalPresentationStyle = .fullScreen
                owner.present(vc, animated: true)
            }.disposed(by: disposeBag)
        
        shoWordBookButton.rx.tap
            .bind(with: self) { owner, _ in
                let vc = WordBookListViewController()
                owner.present(vc, animated: true)
            }.disposed(by: disposeBag)
        
    }
}
