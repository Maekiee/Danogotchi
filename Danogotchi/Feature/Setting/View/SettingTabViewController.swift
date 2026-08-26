import UIKit
import SnapKit
import RxSwift
import RxCocoa

protocol SettingTabViewControllerDelegate: AnyObject {
    func didTapSearchTheme()
    func didTapInquiry(mailBody: String)
    func didTapAppStore()
    func didTapPrivacyPolicy()
    func didTapClose()
}

final class SettingTabViewController: BaseViewController {
    weak var delegate: SettingTabViewControllerDelegate?
    private let disposeBag = DisposeBag()
    private let viewModel: SettingTabViewModel
    
    init(viewModel: SettingTabViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    typealias Section = SettingMenu.Category
    
    private var currentAppVersion: String = ""
    
    /// 셀이 아니라 VC가 인스턴스 하나를 보유한다 — 셀 재사용 때 같은 스위치가 재부착되므로 바인딩을 한 번만 걸면 된다
    private let reminderSwitch = UISwitch()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "설정"
        label.font = AppFont.display
        label.textColor = AppColor.textPrimary
        return label
    }()
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = AppColor.appWhite
        view.alwaysBounceVertical = false
        view.bounces = true
        return view
    }()
    var dataSource: UICollectionViewDiffableDataSource<Section, SettingMenu>!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configHierarchy()
        configLayout()
        configView()
        
        configureDataSource()
        
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
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.bottom.equalToSuperview()
        }
    }
    
    override func configView() {
        // 네비게이션 바 영역(safeArea 위)까지 리스트 배경과 같은 톤으로 맞춘다
        view.backgroundColor = AppColor.appWhite

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"), style: .plain, target: nil, action: nil
        )
    }
    
    private func createLayout() -> UICollectionViewLayout {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.headerMode = .supplementary
        configuration.backgroundColor = AppColor.appWhite
        
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 0
        layout.configuration = config
        
        return layout
    }
}

//MARK: DiffableDataSource
extension SettingTabViewController {
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SettingMenu>
        { [weak self] cell, indexPath, setting in
            guard let self = self else { return }
            
            var contentConfiguration = UIListContentConfiguration.valueCell()
            contentConfiguration.text = "\(setting.icon)   \(setting.title)"
            
            var backgroundConfig = UIBackgroundConfiguration.listGroupedCell()
            backgroundConfig.backgroundColor = AppColor.card
            
            contentConfiguration.secondaryText = nil

            switch setting.action {
            case .appVersion:
                contentConfiguration.secondaryText = currentAppVersion
                contentConfiguration.secondaryTextProperties.color = AppColor.textSecondary
                cell.accessories = []
            case .studyReminder:
                cell.accessories = [
                    .customView(configuration: .init(
                        customView: reminderSwitch,
                        placement: .trailing()
                    ))
                ]
            default:
                cell.accessories = [.disclosureIndicator()]
            }
            
            cell.backgroundConfiguration = backgroundConfig
            cell.contentConfiguration = contentConfiguration
        }
        
        let headerRegistration = UICollectionView.SupplementaryRegistration<CustomHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader) { [weak self] (headerView, elementKind, indexPath) in
                guard let self = self else { return }
                let section = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
                headerView.configure(with: section.description)
            }
        
        dataSource = UICollectionViewDiffableDataSource<Section, SettingMenu>(collectionView: collectionView) {
            collectionView, indexPath, item -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: item
            )
        }
        
        dataSource.supplementaryViewProvider = { (collectionView, elementKind, indexPath) -> UICollectionReusableView? in
            if elementKind == UICollectionView.elementKindSectionHeader {
                return collectionView.dequeueConfiguredReusableSupplementary(
                    using: headerRegistration, for: indexPath)
            }
            return nil
        }
    }
}


//MARK: - viewModel biding
extension SettingTabViewController {
    private func bind() {
        let input = SettingTabViewModel.Input(
            itemSelected: collectionView.rx.itemSelected.compactMap { [weak self] indexPath in
                self?.dataSource.itemIdentifier(for: indexPath)
            },
            reminderToggled: reminderSwitch.rx.isOn.changed.asObservable()
        )
        let output = viewModel.transform(input: input)

        navigationItem.rightBarButtonItem?.rx.tap
            .bind(with: self) { owner, _ in
                owner.delegate?.didTapClose()
            }.disposed(by: disposeBag)

        // 앱 버전
        output.appVersion
            .drive(with: self) { owner, version in
                owner.currentAppVersion = version
            }.disposed(by: disposeBag)
        
        output.isReminderOn
            .drive(with: self) { owner, isOn in
                owner.reminderSwitch.isOn = isOn
            }.disposed(by: disposeBag)

        output.sections
            .drive(with: self) { owner, sections in
                sections.forEach { section in
                    var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<SettingMenu>()
                    sectionSnapshot.append(section.items)
                    owner.dataSource.apply(
                        sectionSnapshot,
                        to: section.category,
                        animatingDifferences: false
                    )
                }
            }.disposed(by: disposeBag)
        
        output.action
            .emit(with: self) { owner, action in
                switch action {
                case .studyReminder:
                    // 스위치가 상태를 바꾸므로 행 탭은 선택 해제만 한다
                    owner.collectionView.indexPathsForSelectedItems?.forEach {
                        owner.collectionView.deselectItem(at: $0, animated: true)
                    }
                case .searchTheme:
                    owner.delegate?.didTapSearchTheme()
                case .inquiry:
                    break
                case .appStore:
                    owner.delegate?.didTapAppStore()
                case .privacyPolicy:
                    owner.delegate?.didTapPrivacyPolicy()
                case .appVersion:
                    owner.collectionView.indexPathsForSelectedItems?.forEach {
                        owner.collectionView.deselectItem(at: $0, animated: true)
                    }
                }
            }.disposed(by: disposeBag)
        
        output.mailBody
            .emit(with: self) { owner, body in
                owner.delegate?.didTapInquiry(mailBody: body)
            }.disposed(by: disposeBag)
    }
}
