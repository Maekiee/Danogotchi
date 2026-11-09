import SwiftUI

// 요일 머리글 + 달마다 한 페이지인 6행 달력 UI, 손가락을 따라 넘어감
struct CalendarMonthGrid: View {
    let calendar: StudyCalendar
    let month: Date
    let selected: Date?
    // 손가락으로 넘겨 바뀐 달
    let onMonthChange: (Date) -> Void
    let onSelect: (Date) -> Void

    private var columns: [GridItem] { Array(repeating: GridItem(.flexible(), spacing: AppSpacing.space4), count: 7) }

    // 최근 5개 연도 1월부터 현재 달까지, 미래 페이지가 없어 현재 달에서 더 넘어가지 않음
    private var pages: [Date] {
        var result: [Date] = []
        var page = calendar.oldestMonth
        while page <= calendar.currentMonth {
            result.append(page)
            guard let next = calendar.calendar.date(byAdding: .month, value: 1, to: page), next > page else { break }
            page = next
        }
        return result
    }

    // 첫 주 시작일부터 42일, 앞뒤는 이웃 달
    private func dates(in page: Date) -> [Date] {
        let cal = calendar.calendar
        let offset = (cal.component(.weekday, from: page) - cal.firstWeekday + 7) % 7
        return (0..<42).compactMap { index in
            cal.date(byAdding: .day, value: index - offset, to: page).map { cal.startOfDay(for: $0) }
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
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(pages, id: \.self) { page in
                        LazyVGrid(columns: columns, spacing: AppSpacing.space4) {
                            ForEach(dates(in: page), id: \.self) { date in
                                cell(date, page: page, label: formatter.string(from: date))
                            }
                        }
                        .containerRelativeFrame(.horizontal)
                        // 보고 있는 달만 VoiceOver에 노출, 달 이동은 ‹ › 버튼
                        .accessibilityHidden(page != month)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .scrollPosition(id: Binding(get: { month }, set: { page in
                // 같은 달 재보고는 무시해야 선택이 풀리지 않음
                if let page, page != month { onMonthChange(page) }
            }), anchor: .center)
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
    private func cell(_ date: Date, page: Date, label: String) -> some View {
        let isAdjacent = calendar.month(of: date) != page
        let isFuture = date > calendar.now
        let day = calendar.days[date]
        let level = isAdjacent || isFuture ? 0 : day?.level ?? 0
        let isSelected = !isAdjacent && date == selected
        let isToday = !isAdjacent && date == calendar.today
        let color: Color = isAdjacent ? Color(AppColor.gray45).opacity(0.5)
            : isFuture ? Color(AppColor.textSecondary).opacity(0.4)
            : level == 0 ? Color(AppColor.textSecondary)
            : level == 4 ? .white : Color(AppColor.textPrimary)
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
