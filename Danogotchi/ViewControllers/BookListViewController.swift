import UIKit
import SnapKit
import RxSwift
import RxCocoa


struct Recommend: Hashable {
    let title: String
    let isStudying: Bool
}


final class BookListViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = BookListViewModel()
    
    private enum Section {
        case myBook
        case recommend
    }
    
    private enum Item: Hashable {
        case currentBook(WordBook)
        case recommend(Recommend)
    }
    
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    private var dataSource: DataSource!
    
    // MARK: UI 프로퍼티
    private let closeButton: UIButton = {
        let button = UIButton()
        button.setTitle("닫기", for: .normal)
        button.setTitleColor(.black, for: .normal)
        return button
    }()
    private let myBookSectionTitle: UILabel = {
        let label = UILabel()
        label.text = "내 단어장"
        label.font = .boldSystemFont(ofSize: 20)
        return label
    }()
//    private let collectionView: UICollectionView = {
//        let view = UICollectionView(
//            frame: .zero,
//            collectionViewLayout: layout()
//        )
//        return view
//    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configView()
        bind()
    }
    
    override func configHierarchy() {
        [
            closeButton,
            myBookSectionTitle,
        ].forEach { view.addSubview($0) }
    }
    
    override func configLayout() {
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.equalToSuperview().offset(20)
        }
        
        myBookSectionTitle.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(20)
        }
    }
    
    override func configView() {
        view.backgroundColor = AppColor.backgroundBeige
    }
    
//    private func layout() -> UICollectionViewLayout {
//        
//    }
}


extension BookListViewController {
    private func bind() {
        
    }
}
