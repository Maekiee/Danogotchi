import UIKit
import Toast
import RxSwift
import RxCocoa

 
class BaseViewController: UIViewController, UIConfigurationLayout, ToastPresentable {
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColor.background
        print("✅ Init: \(String(describing: type(of: self))) ✅")
    }
    
    deinit {
        print("☑️ Deinit 해제: \(String(describing: type(of: self))) ☑️")
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
        style.messageFont = .systemFont(ofSize: 14, weight: .regular)
        style.cornerRadius = 8
        style.verticalPadding = 12
        style.horizontalPadding = 16
        
        view.makeToast(
            message,
            duration: duration.timeInterval,
            position: .center,
            style: style
        )
    }
}
