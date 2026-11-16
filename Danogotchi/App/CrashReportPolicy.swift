import CoreLocation
import FirebaseFirestore
import Foundation
import UserNotifications

/// non-fatal로 남길지 판단. 오프라인·취소·권한 거부는 정상 흐름이라 남기지 않는다
enum CrashReportPolicy {
    private static let expectedURLErrorCodes: Set<URLError.Code> = [
        .cancelled, .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff
    ]

    static func shouldRecord(_ error: Error) -> Bool {
        switch error {
        case is CancellationError, LocationError.permissionDenied:
            return false
        case NetworkError.transport(let urlError):
            return shouldRecord(urlError)
        case let urlError as URLError:
            return !expectedURLErrorCodes.contains(urlError.code)
        case let locationError as CLError:
            return locationError.code != .denied && locationError.code != .locationUnknown
        case let notificationError as UNError:
            return notificationError.code != .notificationsNotAllowed
        case let firestoreError as FirestoreErrorCode:
            return firestoreError.code != .unavailable
        default:
            return true
        }
    }
}
