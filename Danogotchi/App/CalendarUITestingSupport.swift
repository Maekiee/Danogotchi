#if DEBUG
import Foundation

// UI 테스트용 단어 예시
private struct CalendarExample {
    let word: String
    let meaning: String
    let part: String
}

extension UITestingSupport {
    private static var calendarScenario: String? {
        ProcessInfo.processInfo.environment["CALENDAR_UI_TEST"]
    }

    // 고정 날짜(2026-11-03 화 12시, 서울)와 예시 기록으로 캘린더 생성
    static func makeCalendarFeatureIfRequested(
        onClose: @escaping @MainActor @Sendable () -> Void,
        onNavigate: @escaping @MainActor @Sendable (StudyStatsDestination) -> Void
    ) -> CalendarFeature? {
        guard let scenario = calendarScenario,
              let timeZone = TimeZone(identifier: "Asia/Seoul") else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let fixedCalendar = calendar
        guard let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 3, hour: 12)) else { return nil }
        let words = [
            CalendarExample(word: "journey", meaning: "여행", part: "noun"),
            CalendarExample(word: "negotiate", meaning: "협상하다", part: "verb"),
            CalendarExample(word: "anxious", meaning: "불안한", part: "adj"),
            CalendarExample(word: "briefly", meaning: "잠시", part: "adv"),
            CalendarExample(word: "souvenir", meaning: "기념품", part: "noun"),
            CalendarExample(word: "itinerary", meaning: "여행 일정표", part: "noun"),
            CalendarExample(word: "thorough", meaning: "철저한", part: "adj"),
            CalendarExample(word: "postpone", meaning: "미루다", part: "verb"),
            CalendarExample(word: "accommodate", meaning: "수용하다", part: "verb"),
            CalendarExample(word: "deadline", meaning: "마감 기한", part: "noun"),
            CalendarExample(word: "embarrassed", meaning: "당황한", part: "adj"),
            CalendarExample(word: "invoice", meaning: "청구서", part: "noun"),
            CalendarExample(word: "commute", meaning: "통근하다", part: "verb"),
            CalendarExample(word: "reluctant", meaning: "꺼리는", part: "adj"),
            CalendarExample(word: "schedule", meaning: "일정", part: "noun")
        ]
        let wordIDs = words.map { _ in UUID() }
        // (월, 일, 단어 수): 농도 1·2·3단계, 9월은 기록 없는 달, 오늘 미학습 + 2일 연속
        let days = [(8, 10, 1), (10, 15, 5), (10, 20, 15), (11, 1, 2), (11, 2, 1)]
        let histories = days.flatMap { month, day, count -> [LearningHistory] in
            guard let date = calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 9)) else { return [] }
            let session = UUID()
            // 단어마다 두 번 풀고 첫 단어만 모두 정답
            return (0..<count).flatMap { index in
                (0..<2).map { attempt in
                    LearningHistory(
                        id: UUID(), vocabId: wordIDs[index], isCorrect: index == 0 || attempt == 0,
                        createAt: date.addingTimeInterval(Double(index * 2 + attempt)),
                        wordSnapshot: words[index].word, meaningSnapshot: words[index].meaning,
                        topicSnapshot: "travel", partOfSpeechSnapshot: words[index].part, sessionId: session
                    )
                }
            }
        }
        return CalendarFeature(
            fetch: { now, calendar in
                if scenario == "error" { throw CocoaError(.fileReadUnknown) }
                return try DefaultFetchCalendarUseCase.aggregate(scenario == "empty" ? [] : histories,
                                                                 now: now, calendar: calendar)
            },
            reportError: { _ in }, onClose: onClose, onNavigate: onNavigate,
            now: { now }, calendar: { fixedCalendar }
        )
    }
}
#endif
