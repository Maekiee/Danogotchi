import UIKit
import SnapKit
import RxSwift
import RxCocoa

protocol VocabBookDetailViewControllerDelegate: AnyObject {
    func myBookDetailDidTapBack()
    func myBookDetailDidTapCreateWord(with createVocabModel: CreateVocab)
    func myBookDetailDidTapEditWord(with createVocabModel: CreateVocab)
}

final class VocabBookDetailViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: VocabBookDetailViewModel
    weak var delegate: VocabBookDetailViewControllerDelegate?
    
    init(viewModel: VocabBookDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Collection View
    private enum Section {
        case main
    }
    
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, VocabDisplayInfo>
    
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, VocabDisplayInfo>
    
    private var dataSource: DataSource!
    
    // MARK: UI 프로퍼티
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(
            frame: .zero,
            collectionViewLayout: createLayout()
        )
        view.backgroundColor = AppColor.appRed
        return view
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
        navigationItem.title = viewModel.navigationBarTitle
    }
}

// MARK: 바인딩
extension VocabBookDetailViewController {
    private func bind() {
        let input = VocabBookDetailViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(viewWillAppear)).map { _ in }
        )
        let output = viewModel.transform(input: input)
        
        output.vocabList
            .drive(with: self) { owner, list in
                print("뷰컨에서 단어장 리스트: \(list)")
            }.disposed(by: disposeBag)
        
    }
}

// MARK: CollectionView Layout
extension VocabBookDetailViewController {
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(120)
        )
        let group = NSCollectionLayoutGroup.horizontal(
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
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    private func configDataSource() {
        let registration = UICollectionView.CellRegistration<
            MyBookDetailCollectionViewCell, VocabDisplayInfo> {
                [weak self] cell, indexPath, item in
                guard let self else { return }
                cell.binding(with: item)
        }
        
        dataSource = DataSource(collectionView: collectionView) {
            collectionView, indexPath, itemIdentifier in
            return collectionView.dequeueConfiguredReusableCell(
                using: registration,
                for: indexPath,
                item: itemIdentifier
            )
        }
    }
    
//    private func applySnapshot() {
//        var snapshot = Snapshot()
//        snapshot.appendSections([.main])
//        snapshot.appendItems(items)
//        dataSource.apply(snapshot, animatingDifferences: true)
//    }
}
