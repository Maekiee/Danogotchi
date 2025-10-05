import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class MyBookListViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = MyBookListViewModel()
    
    // MARK: - 컬렉션 뷰
    private enum Section {
        case main
    }
    
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, WordBookModel>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, WordBookModel>
    
    private var dataSource: DataSource!
    
    // MARK: - UI 프로퍼티
    private let addBookButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "plus")
        button.configuration = config
        return button
    }()
    private let collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: MyBookListViewController.layout())
        view.showsVerticalScrollIndicator = false
        return view
    }()
    private let changeButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.title = "변경"
        button.configuration = config
        return button
    }()
    
    private let deleteTrigger = PublishRelay<WordBookModel>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configDataSource()
        bind()
    }
    
    override func configHierarchy() {
        [
            changeButton,
            collectionView,
            addBookButton
        ].forEach { view.addSubview($0) }
    }
    
    override func configLayout() {
        changeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(changeButton.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        addBookButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.trailing.equalToSuperview().offset(-20)
        }
    }
}

// MARK: - Rx 바인딩
extension MyBookListViewController {
    private func bind() {
        let refreshTrigger = PublishRelay<Void>()
        let selectedBook = PublishRelay<WordBookModel>()
        
        let input = MyBookListViewModel.Input(
            viewWillAppear:  rx.methodInvoked(#selector(viewWillAppear)).map { _ in },
            refreshTrigger: refreshTrigger.asObservable(),
            selectedChangeBook: selectedBook.asObservable(),
            selectedDeleteTrigger: deleteTrigger.asObservable()
        )
        let output = viewModel.transform(input: input)
        
        changeButton.rx.tap
            .withLatestFrom(selectedBook)
            .bind(with: self) { owner, book in
                UserInfoManager.shared.selectedBookId = book.id
                owner.dismiss(animated: true)
            }.disposed(by: disposeBag)
        
        output.bookList
            .drive(with: self) { owner, book in
                owner.applySnapshot(items: book)
            }.disposed(by: disposeBag)
        
        // 셀 터치
        collectionView.rx.itemSelected
            .compactMap { [weak self] indexPath -> WordBookModel? in
                guard let self = self else { return nil }
                return dataSource.itemIdentifier(for: indexPath)
            }
            .bind(with: self) { owner, book in
                selectedBook.accept(book)
            }.disposed(by: disposeBag)
        
        // 단어장 추가하기
        addBookButton.rx.tap
            .bind(with: self) { owner, _ in
                let vc = CreateBookViewController()
                vc.modalPresentationStyle = .overFullScreen
                vc.modalTransitionStyle = .crossDissolve
                
                vc.bookCreated
                    .bind(to: refreshTrigger)
                    .disposed(by: vc.disposeBag)
                owner.present(vc, animated: true)
                
            }.disposed(by: disposeBag)
        
    }
}

// MARK: - 컬렉션 뷰
extension MyBookListViewController {
    private func configDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<WordCardCollectionViewCell, WordBookModel> { cell, indexPath, item in
            cell.configure(with: item)
            cell.onTouchTopIcon.bind(with: self) { owner, _ in
                print("아이콘 터치 \(item.cardTitle)")
                owner.showActionSheet(
                    title: item.title,
                    deleteAction: { [weak self] in
                        guard let self = self else { return }
                        deleteTrigger.accept(item)
                    }
                )
            }.disposed(by: cell.disposeBag)
        }
        
        dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            return collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: itemIdentifier)
        }
    }
    
    private func applySnapshot(items: [WordBookModel]) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    
    private static func layout() -> UICollectionViewLayout {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1.0))
        )
        item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(200)
        )
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        
        let layout = UICollectionViewCompositionalLayout(section: section)
        
        return layout
    }
}


