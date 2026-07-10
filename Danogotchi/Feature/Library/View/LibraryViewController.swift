import UIKit
import SnapKit
import RxSwift
import RxCocoa


final class LibraryViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: LibraryViewModel
    weak var delegate: LibraryViewControllerDelegate?
    
    init(viewModel: LibraryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private enum Section {
        case main
    }
    
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, BookTopic>
    
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, BookTopic>
    
    private var dataSource: DataSource!
    
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(160)
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize,
            subitems: [item]
        )
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = AppSpacing.space16
        section.contentInsets = NSDirectionalEdgeInsets(
            top: AppSpacing.space16,
            leading: AppSpacing.space16,
            bottom: AppSpacing.space16,
            trailing: AppSpacing.space16,
        )

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(44)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]

        return UICollectionViewCompositionalLayout(section: section)
    }
    
    private func configDataSource() {
        let registration = UICollectionView.CellRegistration
        <VocabTopicCardCollectionViewCell, BookTopic> { cell, _ ,item in
            cell.binding(with: item)
        }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { supplementaryView, _, _ in
            var config = supplementaryView.defaultContentConfiguration()
            config.text = "Vocabulary"
            config.textProperties.font = AppFont.headline
            config.textProperties.color = AppColor.textPrimary
            config.directionalLayoutMargins = .zero
            supplementaryView.contentConfiguration = config
        }

        dataSource = DataSource(collectionView: collectionView) {
            collectionView, indexPath, itemIdentifier in

            collectionView.dequeueConfiguredReusableCell(
                using: registration,
                for: indexPath,
                item: itemIdentifier
            )
        }

        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(
                using: headerRegistration,
                for: indexPath
            )
        }
    }
    
    private func applySnapshot() {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(BookTopic.allCases, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    //MARK: UI 프로퍼티
    private let navigationTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Vocabulary"
        label.font = AppFont.label
        return label
    }()
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(
            frame: .zero,
            collectionViewLayout: createLayout()
        )
        view.alwaysBounceVertical = false
        return view
    }()
   
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configHierarchy()
        configLayout()
        configView()
        configDataSource()
        applySnapshot()
        bind()
    }
    
    override func configHierarchy() {
        [
            collectionView
        ].forEach { view.addSubview($0) }
    }

    override func configLayout() {
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.bottom.equalToSuperview()
        }
    }
    
    override func configView() {
        navigationItem.title = navigationTitleLabel.text
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "닫기", style: .plain, target: nil, action: nil
        )
    }
}

extension LibraryViewController {
    private func bind() {
        let input = LibraryViewModel.Input()
        let output = viewModel.transform(input: input)
        
        
    }
}
