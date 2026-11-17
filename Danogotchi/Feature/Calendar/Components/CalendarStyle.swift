import SwiftUI
import UIKit

// 캘린더 공통 스타일 (글꼴·퍼센트·날짜·농도 색·품사 이름)
enum CalendarStyle {
    static func font(_ font: UIFont, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(font.fontName, size: font.pointSize, relativeTo: style)
    }

    static func percentValue(_ numerator: Int, _ denominator: Int) -> Int {
        denominator > 0 ? Int((Double(numerator) / Double(denominator) * 100).rounded()) : 0
    }

    // 화면을 그릴 때마다 불려 템플릿·달력·시간대별로 재사용한다
    private static let formatters = NSCache<NSString, DateFormatter>()

    // 로케일 순서를 따르는 템플릿 형식 (예: MMMdE → 10월 7일 (화))
    static func formatter(_ template: String, calendar: Calendar) -> DateFormatter {
        let key = "\(template)|\(calendar.identifier)|\(calendar.timeZone.identifier)" as NSString
        if let cached = formatters.object(forKey: key) { return cached }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: Bundle.main.preferredLocalizations.first ?? "ko")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate(template)
        formatters.setObject(formatter, forKey: key)
        return formatter
    }

    /// 달력의 첫 요일부터 시작하는 한 글자 요일 7개, 로케일이 7개를 주지 않으면 빈 배열
    static func weekdaySymbols(_ calendar: Calendar) -> [String] {
        let symbols = formatter("E", calendar: calendar).veryShortStandaloneWeekdaySymbols ?? []
        guard symbols.count == 7 else { return [] }
        let first = calendar.firstWeekday - 1
        return (0..<7).map { symbols[(first + $0) % 7] }
    }

    static func date(_ date: Date, calendar: Calendar, template: String) -> String {
        formatter(template, calendar: calendar).string(from: date)
    }

    // 농도 1~4단계 색, 0단계는 화면마다 다르다
    static func levelColor(_ level: Int) -> Color {
        Color(AppColor.grass).opacity([0, 0.25, 0.5, 0.75, 1][min(max(level, 0), 4)])
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
