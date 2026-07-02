import Foundation

protocol ToastPresentable: AnyObject {
    func showToast(_ message: String, duration: ToastDuration)
}
