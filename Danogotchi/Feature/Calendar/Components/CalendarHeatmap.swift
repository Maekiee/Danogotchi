import SwiftUI

// 최근 53주 학습 잔디 UI (열 = 주, 행 = 요일)
struct CalendarHeatmap: View {
    let calendar: StudyCalendar
    let selected: Date?
    let onSelect: (Date) -> Void

    private static let cell: CGFloat = 12
    private static let gap: CGFloat = 3
    private static let weekCount = 53

    // 이번 주를 마지막 열로 두는 53주 날짜, 미래는 nil
    private var weeks: [[Date?]] {
        let cal = calendar.calendar
        guard let thisWeek = cal.dateInterval(of: .weekOfYear, for: calendar.now)?.start,
              let start = cal.date(byAdding: .weekOfYear, value: 1 - Self.weekCount, to: thisWeek) else { return [] }
        return (0..<Self.weekCount).map { week in
            (0..<7).map { weekday in
                cal.date(byAdding: .day, value: week * 7 + weekday, to: start)
                    .map { cal.startOfDay(for: $0) }
                    .flatMap { $0 <= calendar.now ? $0 : nil }
            }
        }
    }

    var body: some View {
        let weeks = weeks
        HStack(alignment: .top, spacing: AppSpacing.space4) {
            weekdayLabels
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.space4) {
                    monthLabels(weeks)
                    HStack(spacing: Self.gap) {
                        ForEach(weeks.indices, id: \.self) { index in
                            VStack(spacing: Self.gap) {
                                ForEach(0..<7, id: \.self) { row in cell(weeks[index][row]) }
                            }
                        }
                    }
                }
            }
            .defaultScrollAnchor(.trailing)
            .overlay(alignment: .leading) {
                LinearGradient(colors: [Color(AppColor.card), Color(AppColor.card).opacity(0)],
                               startPoint: .leading, endPoint: .trailing)
                    .frame(width: 16)
                    .allowsHitTesting(false)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("최근 1년 학습 기록")
        .accessibilityValue(accessibilityValue(weeks))
    }

    // 2·4·6번째 행만 표시, 가로 스크롤하지 않음
    private var weekdayLabels: some View {
        let formatter = CalendarStyle.formatter("E", calendar: calendar.calendar)
        let symbols = formatter.veryShortStandaloneWeekdaySymbols ?? []
        let first = calendar.calendar.firstWeekday - 1
        return VStack(alignment: .leading, spacing: Self.gap) {
            ForEach(0..<7, id: \.self) { row in
                Text(row % 2 == 1 && symbols.count == 7 ? symbols[(first + row) % 7] : "")
                    .frame(height: Self.cell)
            }
        }
        .font(CalendarStyle.font(AppFont.caption, relativeTo: .caption))
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .foregroundStyle(Color(AppColor.textSecondary))
        .frame(minWidth: 16, alignment: .leading)
        .padding(.top, Self.cell + AppSpacing.space4)
    }

    // 그 달 1일이 든 열 위에 월 표시
    private func monthLabels(_ weeks: [[Date?]]) -> some View {
        let formatter = CalendarStyle.formatter("MMM", calendar: calendar.calendar)
        let firsts = weeks.indices.compactMap { index -> (Int, Date)? in
            weeks[index].compactMap { $0 }.first { calendar.calendar.component(.day, from: $0) == 1 }.map { (index, $0) }
        }
        // offset 대신 padding: 마지막 열 라벨이 그리드 밖으로 나가도 스크롤 폭에 포함
        return ZStack(alignment: .topLeading) {
            ForEach(firsts, id: \.0) { index, date in
                Text(formatter.string(from: date))
                    .fixedSize()
                    .padding(.leading, CGFloat(index) * (Self.cell + Self.gap))
            }
        }
        .frame(height: Self.cell, alignment: .topLeading)
        .font(CalendarStyle.font(AppFont.caption, relativeTo: .caption))
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .foregroundStyle(Color(AppColor.textSecondary))
    }

    @ViewBuilder
    private func cell(_ date: Date?) -> some View {
        if let date {
            let level = calendar.days[date]?.level ?? 0
            RoundedRectangle(cornerRadius: 3)
                .fill(level == 0 ? Color(AppColor.gray45).opacity(0.15) : CalendarStyle.levelColor(level))
                .overlay {
                    if date == selected {
                        RoundedRectangle(cornerRadius: 3)
                            .strokeBorder(Color(AppColor.textPrimary), lineWidth: AppBorder.regular)
                    }
                }
                .frame(width: Self.cell, height: Self.cell)
                // 셀 사이 간격까지 터치 영역 (15pt)
                .contentShape(Rectangle().inset(by: -Self.gap / 2))
                .onTapGesture { onSelect(date) }
        } else {
            Color.clear.frame(width: Self.cell, height: Self.cell)
        }
    }

    private func accessibilityValue(_ weeks: [[Date?]]) -> String {
        let days = weeks.joined().compactMap { $0.flatMap { calendar.days[$0] } }
        let top = days.max { ($0.words.count, $0.date) < ($1.words.count, $1.date) }
        guard let top else { return String(localized: "\(0)일 학습") }
        let date = CalendarStyle.date(top.date, calendar: calendar.calendar, template: "MMMd")
        return String(localized: "\(days.count)일 학습, 가장 많이 학습한 날 \(date) \(top.words.count)개")
    }
}
