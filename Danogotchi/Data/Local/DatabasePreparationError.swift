import Foundation

/// 앱 시작 시 DB 준비가 어느 단계에서 실패했는지. 원인 에러는 그대로 싣는다
struct DatabasePreparationError: Error {
    enum Stage: Int {
        case preflight = 1
        case loadStore = 2
        case backfill = 3
        case seed = 4
    }

    let stage: Stage
    let underlying: Error

    /// 이미 단계가 붙은 에러는 그대로 넘긴다 — 바깥 단계가 안쪽 단계를 덮지 않게
    static func tagging<T>(_ stage: Stage, _ body: () throws -> T) throws -> T {
        do {
            return try body()
        } catch let error as DatabasePreparationError {
            throw error
        } catch {
            throw DatabasePreparationError(stage: stage, underlying: error)
        }
    }
}

// MARK: - Crashlytics 이슈 묶음 — 단계가 code
extension DatabasePreparationError: CustomNSError {
    static var errorDomain: String { "danogotchi.database_preparation" }
    var errorCode: Int { stage.rawValue }
    var errorUserInfo: [String: Any] { [NSUnderlyingErrorKey: underlying] }
}
