import SwiftUI
import UIKit

// 통계 공통 스타일 (글꼴·퍼센트·날짜·색)
enum StudyStatsStyle {
    static func font(_ font: UIFont, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(font.fontName, size: font.pointSize, relativeTo: style)
    }

    static func percent(_ numerator: Int, _ denominator: Int) -> String {
        guard denominator > 0 else { return "—" }
        return "\(Int((Double(numerator) / Double(denominator) * 100).rounded()))%"
    }

    static func date(_ date: Date, calendar: Calendar, format: String = "M.d") -> String {
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
}
