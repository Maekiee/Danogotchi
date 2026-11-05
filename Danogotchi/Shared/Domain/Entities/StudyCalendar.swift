import Foundation

// 캘린더 날짜별 학습 집계, 잔디 53주·달력 6행은 뷰가 days에서 꺼낸다
struct StudyCalendar: Equatable, Sendable {
    struct Day: Equatable, Sendable {
        let date: Date
        let words: [VocabStats]
        let answerCount: Int
        let correctCount: Int
        let quizCount: Int

        // 잔디·달력 공통 농도 구간 (고유 단어 수)
        var level: Int {
            switch words.count {
            case 0: return 0
            case 1...4: return 1
            case 5...14: return 2
            default: return 3
            }
        }
    }

    let now: Date
    let calendar: Calendar
    let days: [Date: Day]
    let earliestMonth: Date
    let streak: Int

    var studiedDayCount: Int { days.count }
    var today: Date { calendar.startOfDay(for: now) }
    var currentMonth: Date { month(of: now) }

    func month(of date: Date) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    // 현재 달부터 earliestMonth까지 최신순
    var months: [Date] {
        var result: [Date] = []
        var month = currentMonth
        while month >= earliestMonth {
            result.append(month)
            guard let previous = calendar.date(byAdding: .month, value: -1, to: month), previous < month else { break }
            month = previous
        }
        return result
    }
}
