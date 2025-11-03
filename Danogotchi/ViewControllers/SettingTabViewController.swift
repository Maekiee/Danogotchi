import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class SettingTabViewController: BaseViewController {
    private let disposeBag = DisposeBag()
    private let viewModel = SettingTabViewModel()
    
    typealias Section = Setting.Category
    
    struct Item: Hashable {
        private let id = UUID()
        let icon: Setting
        let title:String
        
        init(icon: Setting, title: String) {
            self.icon = icon
            self.title = title
        }
    }
    
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        view.backgroundColor = .systemBackground

        view.backgroundColor = .systemBlue
//        view.delegate = self
        return view
    }()
    var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        configHierarchy()
        configLayout()
        configView()
        
        configureDataSource()
        applyInitialSnapshots()
        
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = self.collectionView.indexPathsForSelectedItems?.first {
            if let coordinator = self.transitionCoordinator {
                coordinator.animate(alongsideTransition: { context in
                    self.collectionView.deselectItem(at: indexPath, animated: true)
                }) { (context) in
                    if context.isCancelled {
                        self.collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                    }
                }
            } else {
                self.collectionView.deselectItem(at: indexPath, animated: animated)
            }
        }
    }
    
    override func configHierarchy() {
        view.addSubview(collectionView)
    
    }
    
    override func configLayout() {
        
    }
    
    override func configView() {
        view.backgroundColor = AppColor.backgroundBeige
       
    }
    
    private func createLayout() -> UICollectionViewLayout {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.headerMode = .supplementary
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }
    
    private func configureDataSource() {

        // list cell
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Setting>
        { cell, indexPath, setting in
            var contentConfiguration = UIListContentConfiguration.cell()
            contentConfiguration.text = "\(setting.icon)   \(setting.title)"
            cell.contentConfiguration = contentConfiguration
            cell.accessories = [.disclosureIndicator()]
        }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader) { [weak self] (headerView, elementKind, indexPath) in
            guard let self = self else { return }
            
            let section = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
            
            var content = UIListContentConfiguration.groupedHeader()
            
            content.text = section.description
            headerView.contentConfiguration = content
        }
        
        // data source
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) {
            collectionView, indexPath, item -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: item.icon)
        }
        
        dataSource.supplementaryViewProvider = { (collectionView, elementKind, indexPath) -> UICollectionReusableView? in
            if elementKind == UICollectionView.elementKindSectionHeader {
                return collectionView.dequeueConfiguredReusableSupplementary(
                    using: headerRegistration, for: indexPath)
            }
            return nil
        }
    }
    
    private func applyInitialSnapshots() {
        for category in Setting.Category.allCases {
            var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
            let items = category.list.map { Item(icon: $0, title: $0.title) }
            sectionSnapshot.append(items)
            dataSource.apply(sectionSnapshot, to: category, animatingDifferences: false)
        }
    }

}

//extension SettingTabViewController: UICollectionViewDelegate {
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        guard let setting = self.dataSource.itemIdentifier(for: indexPath)?.icon else {
//            collectionView.deselectItem(at: indexPath, animated: true)
//            return
//        }
//        let detailViewController = SettingTabViewController(with: setting)
//        self.navigationController?.pushViewController(detailViewController, animated: true)
//    }
//}

extension SettingTabViewController {
    private func bind() {
        let input = SettingTabViewModel.Input()
        let output = viewModel.transform(input: input)
    }
}
