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
    
    private var selectedBookId: String?

    
    private enum Section {
        case myBook
        case recommend
    }
    
    private enum Item: Hashable {
        case currentBook(WordBook)
        case recommend(BookListViewModel.RecommendItem)
    }
    
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Item>
    private var dataSource: DataSource!
    
    // MARK: Cell Registration
    private var myBookCellRegistration: UICollectionView.CellRegistration<MyBookCollectionViewCell, WordBook>!
    
    private var recommendCellRegistration: UICollectionView.CellRegistration<RecommendBookCollectionViewCell, BookListViewModel.RecommendItem>!
    
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
        myBookCellRegistration = UICollectionView.CellRegistration<MyBookCollectionViewCell, WordBook> { [weak self] cell, indexPath, item in
            guard let self = self else { return }
            let isSelected = selectedBookId == item.id
            cell.binding(with: item, isSelected: isSelected)
        }
        
        recommendCellRegistration = UICollectionView.CellRegistration<RecommendBookCollectionViewCell, BookListViewModel.RecommendItem> { [weak self] cell, indexPath, item in
            guard let self = self else { return }
            // 4-1. 선택 상태 확인 (downloaded 상태일 때만)
            var isSelected = false
            if case .downloaded(let realmBook) = item {
                isSelected = (self.selectedBookId == realmBook.id)
            }
            
            // 4-2. 새로운 binding 함수 호출
            cell.binding(with: item, isSelected: isSelected)
            
            // 4-3. 💡 다운로드 버튼 탭 이벤트 구독
            cell.onTouchDownload
                .bind(with: self) { owner, _ in
                    // .notDownloaded 상태일 때만 트리거 발생
                    if case .notDownloaded(let mockBook) = item {
                        // ViewModel의 트리거로 mockBook 전달
                        owner.viewModel.downloadBookTrigger.accept(mockBook)
                    }
                }.disposed(by: cell.disposeBag)
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
            case .recommend(let recommendItem):
                return collectionView.dequeueConfiguredReusableCell(
                    using: recommendCellRegistration,
                    for: indexPath,
                    item: recommendItem)
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
    
    private func applySnapshot(myBook: WordBook?, recommendItems: [BookListViewModel.RecommendItem]) {
        
        var snapshot = Snapshot()
        
        // 1. '내 단어장' 섹션
        snapshot.appendSections([.myBook])
        if let myBook = myBook {
            snapshot.appendItems([.currentBook(myBook)], toSection: .myBook)
        }
        
        // 2. '추천 단어장' 섹션
        if !recommendItems.isEmpty {
            snapshot.appendSections([.recommend])
            // 💡 7. RecommendItem을 .recommend()로 래핑하여 추가
            snapshot.appendItems(recommendItems.map { .recommend($0) }, toSection: .recommend)
        }
        
        // 💡 8. animatingDifferences: true로 변경 (다운로드 후 자연스러운 갱신)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
}


extension BookListViewController {
    private func bind() {
        
        selectedBookId = ActiveLearningManager.shared.activeBook.value?.id
        
        ActiveLearningManager.shared.activeBook
            .compactMap { $0?.id }
            .bind(with: self) { owner, bookId in
                owner.selectedBookId = bookId
            }.disposed(by: disposeBag)
        
        
        let input = BookListViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(viewWillAppear)).map { _ in }
        )
        let output = viewModel.transform(input: input)
        
        Driver.combineLatest(output.myBook, output.recommendItems) // recommendItems 구독
            .drive(with: self) { owner, data in
                let (myBook, recommendItems) = data
                owner.applySnapshot(myBook: myBook, recommendItems: recommendItems) // 수정된 함수 호출
            }.disposed(by: disposeBag)
        
        // 9-4. 💡 다운로드 완료 시 (옵션: 선택 상태 새로고침 - 필요 시)
        // (현재 applySnapshot이 전체를 갱신하므로 별도 처리는 불필요)
        output.downloadComplete
            .emit(with: self) { owner, _ in
                // 다운로드가 완료되면 ActiveLearningManager의 캐시된 ID를 다시 확인함
                // (선택 사항: 사용성을 더 좋게 하려면 여기서 selectedBookId를 갱신할 수 있음)
                print("Download complete, snapshot refreshed.")
            }
            .disposed(by: disposeBag)
        
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
                
                let wordBook: WordBook
                let source: WordBookSource
                
                switch selectedCell {
                case .currentBook(let book):
                    // '내 단어장' 선택 (기존 로직)
                    wordBook = book
                    source = .realm(id: book.id)
                    
                case .recommend(let item):
                    switch item {
                    case .downloaded(let realmBook):
                        // 10-1. 💡 다운로드된 추천 단어장 선택
                        // Mock 데이터가 아닌 Realm 데이터를 사용
                        wordBook = realmBook
                        source = .realm(id: realmBook.id)
                        
                    case .notDownloaded:
                        // 10-2. 💡 다운로드 안된 셀은 탭해도 아무 동작 안함
                        return
                    }
                }
                
                // 10-3. ActiveLearningManager 호출 (Realm 데이터로)
                ActiveLearningManager.shared.setActiveBook(wordBook, source: source)
                
                owner.selectedBookId = wordBook.id
                
                // 10-4. UI 갱신
                var snapshot = owner.dataSource.snapshot()
                let sections = snapshot.sectionIdentifiers
                snapshot.reloadSections(sections)
                owner.dataSource.apply(snapshot, animatingDifferences: false)
                
            }.disposed(by: disposeBag)    }
}
