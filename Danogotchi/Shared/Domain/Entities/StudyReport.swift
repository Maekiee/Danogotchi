import Foundation

enum StudyReportPeriod: String, CaseIterable, Sendable {
    case week, month, all

    func start(now: Date, calendar: Calendar) -> Date? {
        switch self {
        case .week: return calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now))
        case .month: return calendar.dateInterval(of: .month, for: now)?.start
        case .all: return nil
        }
    }
}

enum StudyReportCategoryKind: String, CaseIterable, Sendable {
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

struct StudyReportRecords: Sendable {
    let histories: [LearningHistory]
    let sessions: [QuizSession]
}

struct StudyReport: Equatable, Sendable {
    struct Word: Equatable, Sendable, Identifiable {
        let id: UUID
        var snapshot: LearningHistory
        var total: Int
        var correct: Int

        var accuracy: Double { Double(correct) / Double(total) }
    }

    struct Activity: Equatable, Sendable, Identifiable {
        let date: Date
        let count: Int
        var id: Date { date }
    }

    struct Session: Equatable, Sendable, Identifiable {
        let id: UUID
        let completedAt: Date
        let correct: Int
        let total: Int
        var accuracy: Double { Double(correct) / Double(total) }
    }

    struct Category: Equatable, Sendable, Identifiable {
        let id: String
        var total: Int = 0
        var wrong: Int = 0
    }

    let period: StudyReportPeriod
    let now: Date
    let calendar: Calendar
    let periodStart: Date
    let allStart: Date
    let totalAnswers: Int
    let totalCorrect: Int
    let streak: Int
    let weekWordCount: Int
    let monthWordCount: Int
    let recentDays: [Activity]
    let allWords: [Word]
    let words: [Word]
    let periodAnswerCount: Int
    let activity: [Activity]
    let sessions: [Session]
    let topics: [Category]
    let parts: [Category]
    let mistakesByPart: [Category]

    var accuracy: Double? {
        totalAnswers == 0 ? nil : Double(totalCorrect) / Double(totalAnswers)
    }
}
