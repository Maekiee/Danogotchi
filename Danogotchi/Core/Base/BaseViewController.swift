import UIKit
import OSLog
import Toast
import RxSwift
import RxCocoa

 
class BaseViewController: UIViewController, UIConfigurationLayout, ToastPresentable {
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        AppLogger.lifecycle.debug("✅ Init: \(String(describing: type(of: self)), privacy: .public) ✅")
    }
    
    deinit {
        AppLogger.lifecycle.debug("☑️ Deinit 해제: \(String(describing: type(of: self)), privacy: .public) ☑️")
    }
    
    func configHierarchy() { }
    func configLayout() { }
    func configView() { }
    
    private func setupToastObserver() {
        ToastManager.shared.toastObservable
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, toast in
                owner.showToast(toast.message, duration: toast.duration)
            }.disposed(by: disposeBag)
    }
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
