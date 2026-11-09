import SwiftUI

// 월·연도 휠로 달을 고르는 바텀 시트 UI (최근 5개 연도, 미래 달 제외)
struct CalendarMonthPickerSheet: View {
    let calendar: StudyCalendar
    let onSelect: (Date) -> Void
    let onCancel: () -> Void
    @State private var year: Int
    @State private var month: Int

    init(calendar: StudyCalendar, month: Date, onSelect: @escaping (Date) -> Void, onCancel: @escaping () -> Void) {
        self.calendar = calendar
        self.onSelect = onSelect
        self.onCancel = onCancel
        _year = State(initialValue: calendar.calendar.component(.year, from: month))
        _month = State(initialValue: calendar.calendar.component(.month, from: month))
    }

    private var currentYear: Int { calendar.calendar.component(.year, from: calendar.now) }
    private var currentMonth: Int { calendar.calendar.component(.month, from: calendar.now) }
    private var years: [Int] { Array(calendar.calendar.component(.year, from: calendar.oldestMonth)...currentYear) }
    private var months: [Int] { Array(1...(year == currentYear ? currentMonth : 12)) }

    private func date(year: Int, month: Int) -> Date? {
        calendar.calendar.date(from: DateComponents(year: year, month: month, day: 1))
    }

    var body: some View {
        VStack(spacing: AppSpacing.space24) {
            Text("월 선택")
                .font(CalendarStyle.font(AppFont.title3, relativeTo: .headline))
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: AppSpacing.space16) {
                wheel(title: String(localized: "월"), selection: $month, values: months) { value in
                    date(year: year, month: value).map {
                        CalendarStyle.date($0, calendar: calendar.calendar, template: "MMM")
                    } ?? "\(value)"
                }
                wheel(title: String(localized: "연도"), selection: $year, values: years) { "\($0)" }
            }
            VStack(spacing: AppSpacing.space8) {
                Button {
                    if let picked = date(year: year, month: month) { onSelect(picked) }
                } label: {
                    Text("선택한 월 보기")
                        .font(CalendarStyle.font(AppFont.title3, relativeTo: .headline))
                        .foregroundStyle(Color(AppColor.onInverse))
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Color(AppColor.inverse), in: RoundedRectangle(cornerRadius: AppRadius.radius20))
                }
                Button("취소", action: onCancel)
                    .frame(minHeight: 44)
            }
        }
        .padding(AppSpacing.space20)
        .padding(.top, AppSpacing.space8)
        .frame(maxHeight: .infinity, alignment: .top)
        .foregroundStyle(Color(AppColor.textPrimary))
        .background(Color(AppColor.background).ignoresSafeArea())
        // 현재 연도로 바꾸면 미래 달 대신 현재 달
        .onChange(of: year) { _, newYear in
            if newYear == currentYear, month > currentMonth { month = currentMonth }
        }
    }

    private func wheel(title: String, selection: Binding<Int>, values: [Int],
                       label: @escaping (Int) -> String) -> some View {
        VStack(spacing: AppSpacing.space4) {
            Text(title)
                .font(CalendarStyle.font(AppFont.footnote, relativeTo: .footnote))
                .foregroundStyle(Color(AppColor.textSecondary))
            Picker(title, selection: selection) {
                ForEach(values, id: \.self) { Text(verbatim: label($0)).tag($0) }
            }
            .pickerStyle(.wheel)
        }
        .frame(maxWidth: .infinity)
    }
}
