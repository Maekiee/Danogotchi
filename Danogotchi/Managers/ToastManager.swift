import Foundation
import Toast
import RxSwift
import RxCocoa

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

struct ToastMessage {
    let message: String
    let duration: ToastDuration
    
    
    init(message: String, duration: ToastDuration = .short) {
        self.message = message
        self.duration = duration
    }
}


final class ToastManager {
    static let shared = ToastManager()
    
    private init() { }
    
    private let toastRelay = PublishRelay<ToastMessage>()
    
    var toastObservable: Observable<ToastMessage> {
        return toastRelay.asObservable()
    }
    
    func show(_ message: String, duration: ToastDuration = .short) {
        let toast = ToastMessage(message: message, duration: duration)
        toastRelay.accept(toast)
    }
    
}
