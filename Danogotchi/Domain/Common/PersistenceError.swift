import Foundation

/// 조회의 정상적인 데이터 부재와, 수행할 수 없는 쓰기 작업을 구분한다.
enum PersistenceError: Error {
    case entityNotFound
}

// MARK: - Crashlytics 이슈 묶음 — code는 case 순서와 무관한 고정 값
extension PersistenceError: CustomNSError {
    static var errorDomain: String { "danogotchi.persistence" }

    var errorCode: Int {
        switch self {
        case .entityNotFound: return 1
        }
    }
}
