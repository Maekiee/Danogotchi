import Foundation
@testable import Danogotchi

func makeQuizAnswer(_ word: Vocab, isCorrect: Bool = true, id: UUID = UUID(),
                    createAt: Date = Date(), session: QuizSession? = nil, questionIndex: Int = 0) -> QuizAnswer {
    QuizAnswer(
        id: id, word: word, isCorrect: isCorrect, createAt: createAt,
        session: session ?? QuizSession(id: UUID(), startedAt: createAt, questionCount: 1),
        questionIndex: questionIndex
    )
}

func reportCalendar(_ timeZone: String = "Asia/Seoul") -> Calendar {
    guard let zone = TimeZone(identifier: timeZone) else {
        fatalError("알 수 없는 시간대: \(timeZone)")
    }
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = zone
    return calendar
}

func reportDate(_ year: Int = 2026, _ month: Int = 9, _ day: Int = 26,
                _ hour: Int = 12, calendar: Calendar = reportCalendar()) -> Date {
    guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour)) else {
        fatalError("만들 수 없는 날짜: \(year)-\(month)-\(day) \(hour)시")
    }
    return date
}
