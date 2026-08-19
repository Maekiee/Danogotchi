import UIKit
import OSLog
import SnapKit
import RxSwift
import RxCocoa
import SafariServices
import MessageUI

protocol SettingTabViewControllerDelegate: AnyObject {
    func didTapSearchTheme()
    func didTapInquiry()
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
            
            if setting.action == .appVersion {
                contentConfiguration.secondaryText = currentAppVersion
                contentConfiguration.secondaryTextProperties.color = AppColor.textSecondary
                cell.accessories = []
            } else {
                contentConfiguration.secondaryText = nil
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
            }
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
                if MFMailComposeViewController.canSendMail() {
                    let mailComposer = MFMailComposeViewController()
                    mailComposer.mailComposeDelegate = owner
                    mailComposer.setToRecipients(["pdwssf@gmail.com"])
                    mailComposer.setSubject("앱 문의하기")
                    mailComposer.setMessageBody(body, isHTML: false)
                    owner.present(mailComposer, animated: true, completion: nil)
                } else {
                    owner.showMailErrorAlert()
                }
            }.disposed(by: disposeBag)
    }
}

//
extension SettingTabViewController: MFMailComposeViewControllerDelegate {
    // 공통 컴포넌트로 분리
    func showMailErrorAlert() {
        let alert = UIAlertController(title: "메일 전송 실패", message: "기기에 메일 계정이 설정되어 있지 않습니다. 아이폰 '설정' 앱에서 메일 계정을 추가해주세요.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // 공통 컴포넌트로 분리
    func showMailSucceedAlert() {
        let alert = UIAlertController(title: "메일 전송 성공", message: "메일이 성공적으로 전송 되었습니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    // 메일 관련
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            switch result {
            case .sent:
                self.showMailSucceedAlert()
            case .saved:
                AppLogger.ui.debug("메일 임시저장")
            case .cancelled:
                AppLogger.ui.debug("메일 작성 취소")
            case .failed:
                AppLogger.ui.error("메일 전송 실패: \(error?.localizedDescription ?? "알 수 없는 오류", privacy: .public)")
                if let error { CrashReporter.record(error) }
            @unknown default:
                fatalError()
            }
        }
    }
}
