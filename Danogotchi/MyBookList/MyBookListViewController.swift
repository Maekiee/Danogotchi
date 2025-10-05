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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configView()
        configDataSource()
        bind()
    }
    
    override func configHierarchy() {
        [
            collectionView,
            addBookButton
        ].forEach { view.addSubview($0) }
    }
    
    override func configLayout() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        addBookButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.trailing.equalToSuperview().offset(-20)
        }
    }
    
    override func configView() {
        
    }
}

// MARK: - Rx 바인딩
extension MyBookListViewController {
    private func bind() {
        let input = MyBookListViewModel.Input()
        let output = viewModel.transform(input: input)
        
        output.bookList
            .drive(with: self) { owner, book in
                owner.applySnapshot(items: book)
            }.disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .compactMap { [weak self] indexPath -> WordBookModel? in
                guard let self = self else { return nil }
                return dataSource.itemIdentifier(for: indexPath)
            }
            .bind(with: self) { owner, book in
                print(book.title)
            }.disposed(by: disposeBag)
        
        addBookButton.rx.tap
            .bind(with: self) { owner, _ in
                let vc = CreateBookViewController()
                vc.modalPresentationStyle = .overFullScreen
                vc.modalTransitionStyle = .crossDissolve
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


