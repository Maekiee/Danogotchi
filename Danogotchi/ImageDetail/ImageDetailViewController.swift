import UIKit
import SnapKit
import RxSwift
import RxCocoa


final class ImageDetailViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = ImageDetailViewModel()
    
    // MARK: UIProperty
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        return searchBar
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configView()
        
        bind()
    }
    
    override func configHierarchy() {
        [
            searchBar,
        ].forEach { view.addSubview($0) }
    }
    
    override func configLayout() {
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
        }
    }
    
    override func configView() {
        
    }
}

extension ImageDetailViewController {
    private func bind() {
        
    }
}
