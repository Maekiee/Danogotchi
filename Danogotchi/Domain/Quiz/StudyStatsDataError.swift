import Foundation

enum StudyStatsDataError: Error, Equatable, LocalizedError {
    case invalidRecord
    case conflictingAnswer
    case conflictingSession
    case invalidIdentifiers

    var errorDescription: String? {
        switch self {
        case .invalidRecord: return "학습 기록의 필수 정보가 올바르지 않아요."
        case .conflictingAnswer: return "이미 저장한 답변과 내용이 달라요."
        case .conflictingSession: return "이미 저장한 회차와 정보가 달라요."
        case .invalidIdentifiers: return "학습 기록에 없거나 중복된 ID가 있어요."
        }
    }
}

// MARK: - Crashlytics 이슈 묶음 — code는 case 순서와 무관한 고정 값
extension StudyStatsDataError: CustomNSError {
    static var errorDomain: String { "danogotchi.study_stats_data" }

    var errorCode: Int {
        switch self {
        case .invalidRecord: return 1
        case .conflictingAnswer: return 2
        case .conflictingSession: return 3
        case .invalidIdentifiers: return 4
        }
    }
}
