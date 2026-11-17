import UIKit
import OSLog
import Toast


class BaseViewController: UIViewController, UIConfigurationLayout, ToastPresentable {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        AppLogger.lifecycle.debug("✅ Init: \(String(describing: type(of: self)), privacy: .public) ✅")
    }

    /// 하위 클래스가 override하면 반드시 super를 호출해야 화면 breadcrumb가 남는다
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        CrashReporter.screenDidAppear(String(describing: type(of: self)))
    }

    deinit {
        AppLogger.lifecycle.debug("☑️ Deinit 해제: \(String(describing: type(of: self)), privacy: .public) ☑️")
    }
    
    func configHierarchy() { }
    func configLayout() { }
    func configView() { }
}

extension ToastPresentable where Self: UIViewController {
    func showToast(_ message: String, duration: ToastDuration = .short) {
        var style = ToastStyle()
        style.backgroundColor = .black.withAlphaComponent(0.8)
        style.messageColor = .white
        style.messageFont = AppFont.footnote
        style.cornerRadius = AppRadius.radius8
        style.verticalPadding = AppSpacing.space12
        style.horizontalPadding = AppSpacing.space16
        
        view.makeToast(
            message,
            duration: duration.timeInterval,
            position: .center,
            style: style
        )
    }
}
