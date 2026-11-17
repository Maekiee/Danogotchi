import Foundation

// 많이 틀린 단어 기준, 누적 필터
enum StudyStatsMistakeThreshold: Int, CaseIterable, Sendable {
    case seventy = 70, forty = 40, twenty = 20

    func contains(_ word: VocabStats) -> Bool {
        word.accuracyPercent <= rawValue
    }
}
