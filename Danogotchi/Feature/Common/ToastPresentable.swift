import Foundation

enum ToastDuration {
    case short
    case long

    var timeInterval: TimeInterval {
        switch self {
        case .short: 0.8
        case .long: 2.5
        }
    }
}

protocol ToastPresentable: AnyObject {
    func showToast(_ message: String, duration: ToastDuration)
}
