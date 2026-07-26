import UIKit
import SnapKit
import RxSwift
import RxCocoa

protocol VocabBookDetailViewControllerDelegate: AnyObject {
    func myBookDetailDidTapBack()
    func myBookDetailDidTapMenu()
    func myBookDetailDidTapCreateWord(with createVocabModel: CreateVocab)
    func myBookDetailDidTapEditWord(with createVocabModel: CreateVocab)
    func floatingButtonDidTap()
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
        view.backgroundColor = AppColor.background
        return view
    }()
    private let addVocabButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.filled()
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
                pointSize: 22,
                weight: .semibold
            )
        config.image = UIImage(systemName: "plus")

        config.baseForegroundColor = AppColor.appWhite
        config.baseBackgroundColor = AppColor.black
        config.cornerStyle = .capsule
        config.contentInsets = .zero
        button.configuration = config

        return button
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
            addVocabButton
        ].forEach { view.addSubview($0) }
    }
    
    override func configLayout() {
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.bottom.equalToSuperview()
        }
        
        addVocabButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(AppSpacing.space24)
            make.trailing.equalTo(view.safeAreaLayoutGuide).inset(AppSpacing.space20)
            make.size.equalTo(48)
        }
    }
    
    override func configView() {
        navigationItem.title = viewModel.topic.title

        navigationItem.backButtonDisplayMode = .minimal
        // 마지막 셀이 플로팅 버튼에 가리지 않도록 하단 여백 확보
        collectionView.contentInset.bottom = 48 + AppSpacing.space24
        collectionView.verticalScrollIndicatorInsets.bottom = collectionView.contentInset.bottom
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "학습하기", style: .plain, target: nil, action: nil
        )
//        if viewModel.topic == .myBook {
//            navigationItem.rightBarButtonItem = UIBarButtonItem(
//                image: UIImage(systemName: "ellipsis"),
//                style: .plain,
//                target: nil,
//                action: nil
//            )
//        } else {
//            
//        }
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
                owner.applySnapshot(items: list)
            }.disposed(by: disposeBag)
        
        navigationItem.rightBarButtonItem?.rx.tap
            .bind(with: self) { owner, _ in
                print("단어장 학습하기로 변경")
            }.disposed(by: disposeBag)
        
        addVocabButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.delegate?.floatingButtonDidTap()
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
            heightDimension: .absolute(168)
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
            VocabBookDetailCollectionViewCell, VocabDisplayInfo> {
                [weak self] cell, indexPath, item in
                guard let self = self else { return }
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
    
    private func applySnapshot(items: [VocabDisplayInfo]) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(items, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
}
