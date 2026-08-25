import UIKit
import OSLog
import MessageUI
import SafariServices

protocol SettingCoordinatorDelegate: AnyObject {
    func settingCoordinatorDidFinish()
}

final class SettingCoordinator: NSObject, Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    weak var delegate: SettingCoordinatorDelegate?
    
    private static let inquiryRecipient = "pdwssf@gmail.com"

    private let container: AppDIContainer
    
    init(
        container: AppDIContainer,
        navigationController: UINavigationController
    ) {
        self.container = container
        self.navigationController = navigationController
        super.init()
    }
    
    func start() {
        let vm = container.makeSettingTabViewModel()
        let vc = SettingTabViewController(viewModel: vm)
        vc.delegate = self
        navigationController.pushViewController(vc, animated: true)
        navigationController.presentationController?.delegate = self
    }
}

extension SettingCoordinator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        delegate?.settingCoordinatorDidFinish()
    }
}

extension SettingCoordinator: SettingTabViewControllerDelegate {
    func didTapSearchTheme() {
        let vm = container.makeSearchThemeViewModel()
        let vc = SearchThemeViewController(mode: .settings, viewModel: vm)
        vc.delegate = self
        navigationController.pushViewController(vc, animated: true)
    }
    
    func didTapInquiry(mailBody: String) {
        guard MFMailComposeViewController.canSendMail() else {
            AlertPresenter.showNotificationAlert(
                on: navigationController,
                title: "메일 전송 실패",
                message: "기기에 메일 계정이 설정되어 있지 않습니다. 아이폰 '설정' 앱에서 메일 계정을 추가해주세요."
            )
            return
        }

        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        mailComposer.setToRecipients([Self.inquiryRecipient])
        mailComposer.setSubject("앱 문의하기")
        mailComposer.setMessageBody(mailBody, isHTML: false)
        navigationController.present(mailComposer, animated: true)
    }
    
    func didTapAppStore() {
        let storeLink = "itms-apps://itunes.apple.com/app/6753820016"
        let urlString = storeLink
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    
    func didTapPrivacyPolicy() {
        let privacyPolicyLink = "https://nebulous-coffee-e6d.notion.site/27ef47543db2800eb0d0d6e910c09cfc?source=copy_link"
        let urlString = privacyPolicyLink
        guard let url = URL(string: urlString) else { return }
        let safariVC = SFSafariViewController(url: url)
        navigationController.present(safariVC, animated: true)
    }
    
    func didTapClose() {
        navigationController.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            self.delegate?.settingCoordinatorDidFinish()
        }
    }
    
}

extension SettingCoordinator: SearchThemeViewControllerDelegate {
    func didSelectTheme() {
        navigationController.popViewController(animated: true)
    }
}

// MARK: - 문의 메일
extension SettingCoordinator: MFMailComposeViewControllerDelegate {
    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            switch result {
            case .sent:
                AlertPresenter.showNotificationAlert(
                    on: self.navigationController,
                    title: "메일 전송 성공",
                    message: "메일이 성공적으로 전송 되었습니다."
                )
            case .saved:
                AppLogger.ui.debug("메일 임시저장")
            case .cancelled:
                AppLogger.ui.debug("메일 작성 취소")
            case .failed:
                AppLogger.ui.error("메일 전송 실패: \(String(describing: error), privacy: .public)")
                if let error { CrashReporter.record(error) }
            @unknown default:
                AppLogger.ui.debug("알 수 없는 메일 결과")
            }
        }
    }
}
