import Foundation

/// 조회의 정상적인 데이터 부재와, 수행할 수 없는 쓰기 작업을 구분한다.
enum PersistenceError: Error {
    case entityNotFound
}
