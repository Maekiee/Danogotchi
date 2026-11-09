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
            case 1...20: return 1
            case 21...40: return 2
            case 41...60: return 3
            default: return 4
            }
        }
    }

    let now: Date
    let calendar: Calendar
    let days: [Date: Day]
    let streak: Int

    var studiedDayCount: Int { days.count }
    var today: Date { calendar.startOfDay(for: now) }
    var currentMonth: Date { month(of: now) }

    func month(of date: Date) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)
    }

    // 이동 가능한 가장 이른 달: 현재 연도 포함 최근 5개 연도의 1월
    var oldestMonth: Date {
        let year = calendar.component(.year, from: now) - 4
        return calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? currentMonth
    }
}
