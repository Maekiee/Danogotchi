import UIKit
import SnapKit
import RxSwift
import RxCocoa


struct MyBook: Hashable, Identifiable {
    let id = UUID()
    let title: String
}

struct Recommend: Hashable, Identifiable {
    let id = UUID()
    let title: String
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
        case recommend(WordBook)
    }
    
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    private var dataSource: DataSource!
    
    // MARK: Cell Registration
    private var myBookCellRegistration: UICollectionView.CellRegistration<MyBookCollectionViewCell, WordBook>!
    
    private var recommendCellRegistration: UICollectionView.CellRegistration<RecommendBookCollectionViewCell, WordBook>!
    
    private var headerRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewListCell>!

    
    
    // MARK: UI 프로퍼티
    private let closeButton: UIButton = {
        let button = UIButton()
        button.setTitle("닫기", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        return button
    }()
    private let moreButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.title = "단어 보기"
        config.baseForegroundColor = AppColor.pointDarkGray
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
            pointSize: 10,
            weight: .semibold
        )
        config.image = UIImage(systemName: "chevron.right")
        config.imagePlacement = .trailing
        config.imagePadding = 8
        
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 13, weight: .semibold)
            return outgoing
        }
        
        button.configuration = config
        return button
    }()
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(
            frame: .zero,
            collectionViewLayout: layout()
        )
        view.alwaysBounceVertical = false
        view.backgroundColor = AppColor.backgroundBeige
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupCellRegistrations()
        
        configHierarchy()
        configLayout()
        configView()
        
        configDataSource()
        
        bind()
    }
    
    override func configHierarchy() {
        [
            closeButton,
            moreButton,
            collectionView,
        ].forEach { view.addSubview($0) }
    }
    
    override func configLayout() {
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.equalToSuperview().offset(20)
        }
        
        moreButton.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(moreButton.snp.bottom).offset(2)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }
    }
    
    override func configView() {
        view.backgroundColor = AppColor.backgroundBeige
    }
    
    private func setupCellRegistrations() {
        myBookCellRegistration = UICollectionView.CellRegistration<MyBookCollectionViewCell, WordBook> { cell, indexPath, item in
            cell.binding(with: item)
        }
        
        recommendCellRegistration = UICollectionView.CellRegistration<RecommendBookCollectionViewCell, WordBook> { cell, indexPath, item in
            cell.binding(with: item)
        }
        
        headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { supplementaryView, elementKind, indexPath in
            var config = supplementaryView.defaultContentConfiguration()
            config.text = "추천 단어장"
            config.textProperties.font = .boldSystemFont(ofSize: 20)
            config.textProperties.color = .black
            supplementaryView.contentConfiguration = config
        }
    }
    
    private func layout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, environment in
            guard let self = self else { return nil }
            let section = self.dataSource.snapshot().sectionIdentifiers[sectionIndex]
            
            switch section {
            case .myBook:
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(100)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(100)
                )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: [item]
                )
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 0, leading: 0, bottom: 16, trailing: 0
                )
                return section
            case .recommend:
                // 2열 그리드
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.5),
                    heightDimension: .absolute(200)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(
                    top: 6, leading: 6, bottom: 6, trailing: 6
                )
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(200)
                )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: [item, item]
                )
                let headerSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(40)
                )
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                
                let section = NSCollectionLayoutSection(group: group)
                section.boundarySupplementaryItems = [header]
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 0, leading: 0, bottom: 4, trailing: 0
                )
                return section
            }
        }
    }
    
    private func configDataSource() {
        dataSource = DataSource(collectionView: collectionView) { [weak self]
            collectionView, indexPath, itemIdentifier in
            guard let self = self else { return UICollectionViewCell() }
            
            switch itemIdentifier {
            case .currentBook(let wordBook):
                return collectionView.dequeueConfiguredReusableCell(
                    using: myBookCellRegistration,
                    for: indexPath,
                    item: wordBook)
            case .recommend(let wordBook):
                return collectionView.dequeueConfiguredReusableCell(
                    using: recommendCellRegistration,
                    for: indexPath,
                    item: wordBook)
            }
            
        }
        
        dataSource.supplementaryViewProvider = { [weak self]
            collectionView, kind, indexPath in
            guard let self = self else { return nil }
            return collectionView.dequeueConfiguredReusableSupplementary(
                using: headerRegistration,
                for: indexPath
            )
        }
    }
    
    private func applySnapshot(myBook: WordBook, recommendBooks: [WordBook]) {
        var snapshot = Snapshot()
        snapshot.appendSections([.myBook, .recommend])
        
        // 임시 데이터
        snapshot.appendItems([.currentBook(myBook)], toSection: .myBook)
        snapshot.appendItems(recommendBooks.map { .recommend($0) }, toSection: .recommend)
        
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
}


extension BookListViewController {
    private func bind() {
        let input = BookListViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(viewWillAppear)).map { _ in }
        )
        let output = viewModel.transform(input: input)
        
        
        Driver.combineLatest(output.myBook, output.recommendBooks)
            .drive(with: self) { owner, data in
                let (myBook, recommendBooks) = data
                owner.applySnapshot(myBook: myBook, recommendBooks: recommendBooks)
            }.disposed(by: disposeBag)
        
        closeButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.dismiss(animated: true)
            }.disposed(by: disposeBag)
        
        moreButton.rx.tap
            .bind(with: self) { owner, _ in
                let vc = MyBookDetailViewController()
                owner.navigationController?.pushViewController(vc, animated: true)
            }.disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .bind(with: self) { owner, indexPath in
                guard let selectedCell = owner.dataSource.itemIdentifier(for: indexPath) else { return }
                
                print(selectedCell)
            }.disposed(by: disposeBag)
    }
}
