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
    var dataSource: UICollectionViewDiffableDataSource<Section, SettingMenu>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
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
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SettingMenu>
        { [weak self] cell, indexPath, setting in
            guard let self = self else { return }
            
            var contentConfiguration = UIListContentConfiguration.valueCell()
            contentConfiguration.text = "\(setting.icon)   \(setting.title)"
            
            var backgroundConfig = UIBackgroundConfiguration.listGroupedCell()
            backgroundConfig.backgroundColor = AppColor.appWhite
            
            if setting.action == .appVersion {
                // 앱 버전 셀일 경우
                contentConfiguration.secondaryText = currentAppVersion // 버전 정보 표시
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

extension SettingTabViewController: MFMailComposeViewControllerDelegate {
    private func bind() {
        let input = SettingTabViewModel.Input()
        let output = viewModel.transform(input: input)
        
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
        
        collectionView.rx.itemSelected
            .bind(with: self) { owner, indexPath in
                guard let selectedCell = owner.dataSource.itemIdentifier(for: indexPath) else { return }
                switch selectedCell.action {
                case .searchTheme:
                    owner.delegate?.didTapSearchTheme()
                case .inquiry:
                    owner.openEmailForm()
                case .appStore:
                    owner.delegate?.didTapAppStore()
                case .privacyPolicy:
                    owner.delegate?.didTapPrivacyPolicy()
                case .appVersion:
                    owner.collectionView.deselectItem(at: indexPath, animated: true)
                }
            }.disposed(by: disposeBag)
    }
    

    private func openEmailForm() {
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            
            mailComposer.mailComposeDelegate = self
            
            mailComposer.setToRecipients(["pdwssf@gmail.com"])
            
            mailComposer.setSubject("앱 문의하기")
            
            let body = """
                    궁금하신 점이나 불편 사항을 편하게 남겨주세요.
                    
                    
                    
                    
                    -------------------
                    앱 버전: \(currentAppVersion)
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
