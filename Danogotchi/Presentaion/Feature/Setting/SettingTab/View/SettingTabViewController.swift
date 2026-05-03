import UIKit
import SnapKit
import RxSwift
import RxCocoa
import SafariServices
import MessageUI

class CustomHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "CustomHeaderView"
    
    private let label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(4)
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with text: String) {
        label.text = text
    }
}



protocol SettingTabViewControllerDelegate: AnyObject {
    func didTapSetDamagotchi()
    func didTapSearchTheme()
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
    
    private var appVersion: String {
        guard let info = Bundle.main.infoDictionary,
              let version = info["CFBundleShortVersionString"] as? String else {
            return "N/A"
        }
        return "v \(version)"
    }
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "설정"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .black
        return label
    }()
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = AppColor.backgroundBeige
        view.alwaysBounceVertical = false
        view.bounces = true
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
        
        navigationController?.setNavigationBarHidden(true, animated: animated)

        
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 다른 화면으로 이동 시 네비게이션 바 다시 보이기
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    
    override func configHierarchy() {
        view.addSubview(titleLabel)
        view.addSubview(collectionView)
        
    }
    
    override func configLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.leading.equalToSuperview().offset(20)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    override func configView() {
        view.backgroundColor = AppColor.backgroundBeige
    }
    
    private func createLayout() -> UICollectionViewLayout {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.headerMode = .supplementary
        configuration.backgroundColor = AppColor.backgroundBeige
        
        let layout = UICollectionViewCompositionalLayout.list(using: configuration)
        
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 0
        layout.configuration = config
        
        return layout
    }
    
    private func configureDataSource() {
        
        // list cell
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Setting>
        { [weak self] cell, indexPath, setting in
            guard let self = self else { return }
            
            var contentConfiguration = UIListContentConfiguration.valueCell()
            contentConfiguration.text = "\(setting.icon)   \(setting.title)"
            
            var backgroundConfig = UIBackgroundConfiguration.listGroupedCell()
            backgroundConfig.backgroundColor = AppColor.appWhite
            
            if setting.title == "앱 버전" {
                // 앱 버전 셀일 경우
                contentConfiguration.secondaryText = appVersion // 버전 정보 표시
                contentConfiguration.secondaryTextProperties.color = .gray // 버전 텍스트 색상
                cell.accessories = [] // 화살표 제거
            } else {
                // 다른 모든 셀일 경우
                contentConfiguration.secondaryText = nil
                cell.accessories = [.disclosureIndicator()] // 화살표 표시
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

extension SettingTabViewController: MFMailComposeViewControllerDelegate {
    private func bind() {
        let input = SettingTabViewModel.Input()
        let output = viewModel.transform(input: input)
        
        
        collectionView.rx.itemSelected
            .bind(with: self) { owner, indexPath in
                guard let selectedCell = owner.dataSource.itemIdentifier(for: indexPath) else { return }
                owner.handleSettingAction(selectedCell.icon)
            }.disposed(by: disposeBag)
    }
    
    private func handleSettingAction(_ setting: Setting) {
        switch setting.title {
        case "배경 테마 변경하기":
            showThemeSelector()
        case "문의하기":
            openEmailForm()
        case "앱스토어 리뷰":
            openAppStore()
        case "개인정보 처리방침":
            openPrivacyPolicy()
        default:
            print("ddd")
        }
    }
    
    private func showThemeSelector() {
        // TODO: Step 1-7에서 SettingCoordinator로 이동
        let vm = SearchThemeViewModel(mode: .settings, repository: SearchThemeRepository())
        let vc = SearchThemeViewController(mode: .settings, viewModel: vm)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func openAppStore() {
        let urlString = "itms-apps://itunes.apple.com/app/6753820016"
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    
    private func openPrivacyPolicy() {
        let urlString = "https://nebulous-coffee-e6d.notion.site/27ef47543db2800eb0d0d6e910c09cfc?source=copy_link"
        guard let url = URL(string: urlString) else { return }
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true)
    }
    
    private func pushLicenseList() {
        let vc = OpenSourceLicenseListViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
//
    private func openEmailForm() {
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            
            mailComposer.mailComposeDelegate = self
            
            mailComposer.setToRecipients(["pdwssf@gmail.com"])
            
            mailComposer.setSubject("앱 문의하기")
            
            let body = """
                    궁금하신 점이나 불편 사항을 편하게 남겨주세요.
                    
                    
                    
                    
                    -------------------
                    앱 버전: \(appVersion)
                    기기: \(UIDevice.current.model)
                    OS 버전: \(UIDevice.current.systemVersion)
                    -------------------
                    """
            mailComposer.setMessageBody(body, isHTML: false)
            
            self.present(mailComposer, animated: true, completion: nil)
            
        } else {
            showMailErrorAlert()
        }
    }
    
    func showMailErrorAlert() {
        let alert = UIAlertController(title: "메일 전송 실패", message: "기기에 메일 계정이 설정되어 있지 않습니다. 아이폰 '설정' 앱에서 메일 계정을 추가해주세요.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showMailSucceedAlert() {
        let alert = UIAlertController(title: "메일 전송 성공", message: "메일이 성공적으로 전송 되었습니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            switch result {
            case .sent:
                self.showMailSucceedAlert()
            case .saved:
                print("Mail saved")
            case .cancelled:
                print("Mail cancelled")
            case .failed:
                print("Mail failed: \(error?.localizedDescription ?? "Unknown error")")
            @unknown default:
                fatalError()
            }
        }
    }
}
