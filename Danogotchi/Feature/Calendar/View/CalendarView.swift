import ComposableArchitecture
import SwiftUI

struct CalendarView: View {
    let store: StoreOf<CalendarFeature>
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.space16) {
                if let calendar = store.calendar, let month = store.displayedMonth {
                    CalendarCard {
                        CalendarHeatmap(calendar: calendar, selected: store.selectedDate) { store.send(.heatmapTapped($0)) }
                    }
                    chips(calendar)
                    CalendarCard {
                        CalendarMonthGrid(calendar: calendar, month: month, selected: store.selectedDate) {
                            store.send(.dateTapped($0))
                        }
                        controls(calendar, month: month)
                        if !calendar.days.isEmpty {
                            Text("날짜를 누르면 그날 학습한 단어를 볼 수 있어요")
                                .font(CalendarStyle.font(AppFont.footnote, relativeTo: .footnote))
                                .foregroundStyle(Color(AppColor.textSecondary))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    // 다시 읽기 실패는 기존 화면을 두고 선택 영역 위에 알린다
                    if store.loadStatus == .failed {
                        CalendarStateCard(kind: .failed) { store.send(.refresh) }
                    }
                    selection(calendar, month: month)
                } else if store.loadStatus == .failed {
                    CalendarStateCard(kind: .failed) { store.send(.refresh) }
                } else {
                    CalendarStateCard(kind: .loading)
                }
            }
            .padding(AppSpacing.space20)
        }
        .background(Color(AppColor.background).ignoresSafeArea())
        .foregroundStyle(Color(AppColor.textPrimary))
        .font(CalendarStyle.font(AppFont.body))
        .navigationTitle("캘린더")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { store.send(.closeButtonTapped) } label: {
                    Image(systemName: "xmark").frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("학습 통계 닫기")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { store.send(.statsButtonTapped) } label: {
                    HStack(spacing: 3) {
                        Text("학습 통계")
                        Image(systemName: "chevron.right")
                    }
                    .frame(minHeight: 44)
                }
                .accessibilityLabel("학습 통계")
                .accessibilityIdentifier("calendar.stats")
            }
        }
        .task { store.send(.appeared) }
        .onDisappear { store.send(.disappeared) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.send(.refresh) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in store.send(.refresh) }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in store.send(.refresh) }
    }

    private func chips(_ calendar: StudyCalendar) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: AppSpacing.space8))
            : AnyLayout(HStackLayout(spacing: AppSpacing.space8))
        return layout {
            CalendarChip(systemImage: "flame", text: String(localized: "\(calendar.streak)일 연속"),
                         accessibilityText: String(localized: "연속 학습 \(calendar.streak)일"))
            CalendarChip(systemImage: "calendar", text: String(localized: "총 \(calendar.studiedDayCount)일 학습"),
                         accessibilityText: String(localized: "총 학습일 \(calendar.studiedDayCount)일"))
        }
    }

    // 월 메뉴 · 오늘 · ‹ ›, 접근성 글자 크기에서는 두 줄
    private func controls(_ calendar: StudyCalendar, month: Date) -> some View {
        let isEmpty = calendar.days.isEmpty
        let isToday = month == calendar.currentMonth && store.selectedDate == calendar.today
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: AppSpacing.space8))
            : AnyLayout(HStackLayout(spacing: AppSpacing.space8))
        return layout {
            Menu {
                Picker("월 선택", selection: Binding(get: { month }, set: { store.send(.monthPicked($0)) })) {
                    ForEach(calendar.months, id: \.self) { item in
                        Text(CalendarStyle.date(item, calendar: calendar.calendar, template: "yMMM")).tag(item)
                    }
                }
            } label: {
                HStack(spacing: AppSpacing.space4) {
                    Text(CalendarStyle.date(month, calendar: calendar.calendar, template: "yMMM"))
                        .font(CalendarStyle.font(AppFont.bodyEmphasis))
                        .monospacedDigit()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(AppColor.textSecondary))
                }
                .padding(.horizontal, AppSpacing.space12)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color(AppColor.gray45).opacity(0.12), in: Capsule())
            }
            .accessibilityIdentifier("calendar.month")
            HStack(spacing: AppSpacing.space8) {
                controlButton(disabled: isEmpty || isToday, action: .todayTapped) {
                    Text("오늘").font(CalendarStyle.font(AppFont.label, relativeTo: .subheadline))
                        .padding(.horizontal, AppSpacing.space12)
                        .frame(minHeight: 44)
                }
                controlButton(disabled: month <= calendar.earliestMonth, action: .monthMoved(-1)) {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("이전 달")
                controlButton(disabled: month >= calendar.currentMonth, action: .monthMoved(1)) {
                    Image(systemName: "chevron.right").font(.system(size: 16, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("다음 달")
            }
        }
    }

    private func controlButton<Label: View>(disabled: Bool, action: CalendarFeature.Action,
                                            @ViewBuilder label: () -> Label) -> some View {
        Button { store.send(action) } label: {
            label().background(Color(AppColor.gray45).opacity(0.12), in: Capsule())
        }
        .buttonStyle(CalendarControlStyle())
        .disabled(disabled)
    }

    @ViewBuilder
    private func selection(_ calendar: StudyCalendar, month: Date) -> some View {
        if calendar.days.isEmpty {
            CalendarStateCard(kind: .empty)
        } else if let date = store.selectedDate {
            if let day = calendar.days[date] {
                let accuracy = CalendarStyle.percentValue(day.correctCount, day.answerCount)
                CalendarHeading(
                    title: CalendarStyle.date(date, calendar: calendar.calendar, template: "MMMdE"),
                    subtitle: String(localized: "단어 \(day.words.count)개 · 정답률 \(accuracy)% · 퀴즈 \(day.quizCount)회")
                )
                ForEach(day.words) { word in
                    Button { store.send(.wordTapped(word.id)) } label: { CalendarWordCard(word: word) }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                }
            } else {
                CalendarSelection(text: date == calendar.today
                    ? String(localized: "오늘은 아직 학습 기록이 없어요")
                    : String(localized: "이날은 학습 기록이 없어요"))
            }
        } else if !calendar.days.keys.contains(where: { calendar.month(of: $0) == month }) {
            CalendarSelection(text: String(localized: "이 달에는 학습 기록이 없어요"))
        }
    }
}

// 비활성은 버튼 전체 40%, plain 스타일의 시스템 흐림과 겹치지 않게 직접 그린다
private struct CalendarControlStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.4)
    }
}

#Preview {
    NavigationStack {   // 툴바를 보려면 필요
        CalendarView(store: Store(initialState: CalendarFeature.State()) {
            CalendarFeature(
                fetch: { now, calendar in try DefaultFetchCalendarUseCase.aggregate([], now: now, calendar: calendar) },
                reportError: { _ in }, onClose: {}, onNavigate: { _ in }
            )
        })
    }
}
