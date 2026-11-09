import Foundation

enum StudyStatsCategoryKind: String, CaseIterable, Sendable {
    case topic, partOfSpeech

    var identifiers: [String] {
        self == .topic ? ["travel", "business", "emotion", "life", "unknown"]
            : ["noun", "verb", "adj", "adv", "unknown"]
    }

    func identifier(_ rawValue: String?) -> String {
        guard let rawValue, identifiers.contains(rawValue) else { return "unknown" }
        return rawValue
    }
}

// 많이 틀린 단어 기준, 누적 필터
enum StudyStatsMistakeThreshold: Int, CaseIterable, Sendable {
    case seventy = 70, forty = 40, twenty = 20

    // 화면 표기(StudyStatsStyle.percent)와 같은 반올림 정수로 판정
    func contains(_ word: VocabStats) -> Bool {
        Int((Double(word.correct) / Double(word.total) * 100).rounded()) <= rawValue
    }
}

struct StudyStatsRecords: Sendable {
    let histories: [LearningHistory]
    let sessions: [QuizSession]
}

struct StudyStats: Equatable, Sendable {
    struct Category: Equatable, Sendable, Identifiable {
        let id: String
        var total: Int = 0
    }

    let now: Date
    let calendar: Calendar
    let start: Date
    let totalAnswers: Int
    let totalCorrect: Int
    let words: [VocabStats]
    let mistakeWords: [VocabStats]
    let topics: [Category]
    let parts: [Category]

    var accuracy: Double? {
        totalAnswers == 0 ? nil : Double(totalCorrect) / Double(totalAnswers)
    }
}
