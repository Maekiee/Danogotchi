import SwiftUI

// 요일 머리글 + 6행 고정 월 달력 UI
struct CalendarMonthGrid: View {
    let calendar: StudyCalendar
    let month: Date
    let selected: Date?
    // 새 달 날짜가 들어오는 쪽, 애니메이션 트랜잭션일 때만 밀림
    let slideEdge: Edge
    let onSelect: (Date) -> Void

    private var columns: [GridItem] { Array(repeating: GridItem(.flexible(), spacing: AppSpacing.space4), count: 7) }

    // 첫 주 시작일부터 42일, 앞뒤는 이웃 달
    private var dates: [Date] {
        let cal = calendar.calendar
        let offset = (cal.component(.weekday, from: month) - cal.firstWeekday + 7) % 7
        return (0..<42).compactMap { index in
            cal.date(byAdding: .day, value: index - offset, to: month).map { cal.startOfDay(for: $0) }
        }
    }

    var body: some View {
        let formatter = CalendarStyle.formatter("MMMMdEEEE", calendar: calendar.calendar)
        VStack(spacing: AppSpacing.space8) {
            LazyVGrid(columns: columns, spacing: AppSpacing.space4) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(CalendarStyle.font(AppFont.label, relativeTo: .subheadline))
                        .foregroundStyle(Color(AppColor.textSecondary))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(minHeight: 20)
                        .accessibilityHidden(true)
                }
            }
            ZStack {
                LazyVGrid(columns: columns, spacing: AppSpacing.space4) {
                    ForEach(dates, id: \.self) { date in cell(date, label: formatter.string(from: date)) }
                }
                .id(month)
                .transition(.push(from: slideEdge))
            }
            .clipped()
        }
    }

    // 접근성 글자 크기에서도 한 글자
    private var weekdaySymbols: [String] {
        let symbols = CalendarStyle.formatter("E", calendar: calendar.calendar).veryShortStandaloneWeekdaySymbols ?? []
        guard symbols.count == 7 else { return [] }
        let first = calendar.calendar.firstWeekday - 1
        return (0..<7).map { symbols[(first + $0) % 7] }
    }

    @ViewBuilder
    private func cell(_ date: Date, label: String) -> some View {
        let isAdjacent = calendar.month(of: date) != month
        let isFuture = date > calendar.now
        let day = calendar.days[date]
        let level = isAdjacent || isFuture ? 0 : day?.level ?? 0
        let isSelected = !isAdjacent && date == selected
        let isToday = !isAdjacent && date == calendar.today
        let color: Color = isAdjacent ? Color(AppColor.gray45).opacity(0.5)
            : isFuture ? Color(AppColor.textSecondary).opacity(0.4)
            : level == 0 ? Color(AppColor.textSecondary)
            : level == 3 ? .white : Color(AppColor.textPrimary)
        let content = VStack(spacing: AppSpacing.space2) {
            Text("\(calendar.calendar.component(.day, from: date))")
                .font(CalendarStyle.font(isSelected ? AppFont.bodyEmphasis : AppFont.body))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Circle().fill(isSelected ? color : .clear).frame(width: 4, height: 4)
        }
        .foregroundStyle(color)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(level == 0 ? .clear : CalendarStyle.levelColor(level),
                    in: RoundedRectangle(cornerRadius: AppRadius.radius8))
        .overlay {
            if isToday {
                RoundedRectangle(cornerRadius: AppRadius.radius8)
                    .strokeBorder(Color(AppColor.grass), lineWidth: AppBorder.regular)
            }
        }
        if isAdjacent {
            content.accessibilityHidden(true)
        } else if isFuture {
            content.accessibilityElement(children: .ignore).accessibilityLabel(label)
        } else {
            Button { onSelect(date) } label: { content.contentShape(Rectangle()) }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(day.map { String(localized: "\(label), 학습 단어 \($0.words.count)개") }
                                    ?? String(localized: "\(label), 학습 안 함"))
                .accessibilityValue(isToday ? String(localized: "오늘") : "")
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        }
    }
}
