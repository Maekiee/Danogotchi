import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class MyBookDetailViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = MyBookDetailViewModel()
    
    private enum Section {
        case main
    }
    
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, WordDisplayInfo>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, WordDisplayInfo>
    private var dataSource: DataSource!
    
    // MARK:
    private let backButton: UIButton = {
        let button = UIButton()
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "chevron.left")
        config.baseForegroundColor = .black
        button.configuration = config
        return button
    }()
    private let collectionView: UICollectionView = {
        let view = UICollectionView(
            frame: .zero,
            collectionViewLayout: MyBookDetailViewController.layout()
        )
        view.backgroundColor = AppColor.backgroundBeige
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
            backButton,
            collectionView,
        ].forEach { view.addSubview($0)
        }
    }
    
    override func configLayout() {
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.equalToSuperview().offset(6)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(backButton.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }
    }
    
    override func configView() {
        view.backgroundColor = AppColor.backgroundBeige
    }
}

extension MyBookDetailViewController {
    private func bind() {
        let input = MyBookDetailViewModel.Input(
            viewWillAppear: rx.methodInvoked(#selector(viewWillAppear)).map { _ in }
        )
        let output = viewModel.transform(input: input)
        
        backButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.navigationController?.popViewController(animated: true)
            }.disposed(by: disposeBag)
        
        output.wordList
            .drive(with: self) { owner, items in
                owner.applaySnapshot(items: items)
            }.disposed(by: disposeBag)
    }
}

// MARK: 컬렉션 뷰
extension MyBookDetailViewController {
    private func configDataSource() {
        let cellregistration = UICollectionView.CellRegistration<MyBookDetailCollectionViewCell, WordDisplayInfo> { [weak self]
            cell, indexPath, item in
            guard let _ = self else { return }
            cell.binding(with: item)
            
        }
        
        dataSource = DataSource(collectionView: collectionView) {
            collectionView, indexPath, itemIdentifier in
            return collectionView.dequeueConfiguredReusableCell(
                using: cellregistration,
                for: indexPath,
                item: itemIdentifier)
        }
    }
    
    private func applaySnapshot(items: [WordDisplayInfo]) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private static func layout() -> UICollectionViewLayout {
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
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 0)
        section.interGroupSpacing = 12
        
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        
        
        let layout = UICollectionViewCompositionalLayout(section: section, configuration: config)
        
        return layout
    }
}
