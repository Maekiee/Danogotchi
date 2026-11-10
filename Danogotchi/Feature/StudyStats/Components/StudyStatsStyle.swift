import SwiftUI
import UIKit

// 통계 공통 스타일 (글꼴·퍼센트·날짜·색·주제·품사 이름)
enum StudyStatsStyle {
    static func font(_ font: UIFont, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(font.fontName, size: font.pointSize, relativeTo: style)
    }

    static func percent(_ numerator: Int, _ denominator: Int) -> String {
        guard denominator > 0 else { return "—" }
        return "\(Int((Double(numerator) / Double(denominator) * 100).rounded()))%"
    }

    static func date(_ date: Date, calendar: Calendar, format: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: Bundle.main.preferredLocalizations.first ?? "ko")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    static func range(_ start: Date, _ end: Date, calendar: Calendar) -> String {
        "\(date(start, calendar: calendar, format: "yyyy.M.d")) – \(date(end, calendar: calendar, format: "yyyy.M.d"))"
    }

    static func color(_ index: Int) -> Color {
        let colors = [AppColor.primary, AppColor.sage, AppColor.sky, AppColor.lavender, AppColor.gray45]
        return Color(colors[index % colors.count])
    }

    // 나의 단어장·알 수 없는 값은 미분류
    static func topicTitle(_ rawValue: String?) -> String {
        switch BookTopic(rawValue: rawValue ?? "") {
        case .travel: return String(localized: "여행")
        case .business: return String(localized: "비즈니스")
        case .emotion: return String(localized: "감정")
        case .life: return String(localized: "일상")
        case .myBook, nil: return String(localized: "미분류")
        }
    }

    static func partTitle(_ rawValue: String?) -> String {
        switch PartOfSpeech(rawValue: rawValue ?? "") {
        case .noun: return String(localized: "명사")
        case .verb: return String(localized: "동사")
        case .adj: return String(localized: "형용사")
        case .adv: return String(localized: "부사")
        case nil: return String(localized: "미분류")
        }
    }
}
