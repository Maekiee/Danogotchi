import Foundation

enum LocationError: Error {
    case permissionDenied
    case requestInProgress
}

// MARK: - Crashlytics 이슈 묶음 — code는 case 순서와 무관한 고정 값
extension LocationError: CustomNSError {
    static var errorDomain: String { "danogotchi.location" }

    var errorCode: Int {
        switch self {
        case .permissionDenied: return 1
        case .requestInProgress: return 2
        }
    }
}
