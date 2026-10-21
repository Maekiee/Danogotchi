import ComposableArchitecture
import SwiftUI

struct StudyReportView: View {
    let store: StoreOf<StudyReportFeature>
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.space16) {
                if let report = store.report {
                    StudyReportCard {
                        let layout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 20))
                            : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
                        layout {
                            Button { store.send(.wordsTapped(.all)) } label: {
                                VStack(alignment: .leading, spacing: AppSpacing.space8) {
                                    Text("누적 학습 단어 ›").font(StudyReportStyle.font(AppFont.label, relativeTo: .subheadline))
                                    Text("\(report.allWords.count)개")
                                        .font(StudyReportStyle.font(AppFont.display, relativeTo: .largeTitle)).monospacedDigit()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityElement(children: .combine)
                            }
                            .buttonStyle(.plain)
                            .disabled(store.loadStatus == .failed)
                            VStack(alignment: .leading, spacing: AppSpacing.space8) {
                                Text("총 정답률").font(StudyReportStyle.font(AppFont.label, relativeTo: .subheadline))
                                Text(StudyReportStyle.percent(report.totalCorrect, report.totalAnswers))
                                    .font(StudyReportStyle.font(AppFont.display, relativeTo: .largeTitle)).monospacedDigit()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityElement(children: .combine)
                        }
                        Divider()
                        VStack(alignment: .leading, spacing: AppSpacing.space12) {
                            Text("\(report.streak)일 연속 학습")
                                .font(StudyReportStyle.font(AppFont.headline, relativeTo: .headline))
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible()), count: dynamicTypeSize.isAccessibilitySize ? 4 : 7)
                            ) {
                                ForEach(report.recentDays) { day in
                                    let date = StudyReportStyle.date(
                                        day.date, calendar: report.calendar, format: String(localized: "M월 d일")
                                    )
                                    VStack(spacing: AppSpacing.space8) {
                                        Text(StudyReportStyle.date(day.date, calendar: report.calendar, format: "E"))
                                        Image(systemName: day.hasStudied ? "checkmark.circle.fill" : "minus.circle")
                                            .foregroundStyle(day.hasStudied ? Color(AppColor.primary) : Color(AppColor.gray45))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .accessibilityElement(children: .ignore)
                                    .accessibilityLabel(
                                        "\(date), \(day.hasStudied ? String(localized: "학습함") : String(localized: "학습 안 함"))"
                                    )
                                }
                            }
                            .font(StudyReportStyle.font(AppFont.label, relativeTo: .subheadline))
                        }
                    }
                    let periodLayout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 12))
                        : AnyLayout(HStackLayout(spacing: 12))
                    periodLayout {
                        ForEach([
                            (String(localized: "최근 7일 학습 단어"), report.weekWordCount),
                            (String(localized: "이번 달 학습 단어"), report.monthWordCount)
                        ], id: \.0) { item in
                            StudyReportCard {
                                VStack(alignment: .leading, spacing: AppSpacing.space8) {
                                    Text(item.0).font(StudyReportStyle.font(AppFont.label, relativeTo: .subheadline))
                                    Text("\(item.1)개")
                                        .font(StudyReportStyle.font(AppFont.display, relativeTo: .largeTitle)).monospacedDigit()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityElement(children: .combine)
                            }
                        }
                    }
                }

                Picker("분석 기간", selection: Binding(get: { store.period }, set: { store.send(.periodChanged($0)) })) {
                    ForEach(StudyReportPeriod.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("studyReport.period")

                switch store.loadStatus {
                // 첫 진입만 스켈레톤, 이후 로딩은 이전 리포트 유지
                case .loading where store.report == nil:
                    VStack(spacing: AppSpacing.space16) {
                        ProgressView("학습 기록을 불러오고 있어요.").padding()
                        ForEach(0..<3) { _ in
                            RoundedRectangle(cornerRadius: AppRadius.radius16)
                                .fill(Color(AppColor.gray45).opacity(0.12)).frame(height: 150)
                                .accessibilityHidden(true)
                        }
                    }.frame(maxWidth: .infinity)
                case .failed:
                    StudyReportCard {
                        Image(systemName: "exclamationmark.circle").font(.largeTitle)
                        StudyReportHeading(
                            title: String(localized: "기록을 불러오지 못했어요"),
                            subtitle: String(localized: "잠시 후 다시 시도해 주세요. 저장된 학습 기록은 그대로 남아 있어요.")
                        )
                        Button("다시 시도") { store.send(.refresh) }
                            .buttonStyle(.borderedProminent).tint(Color(AppColor.primary))
                            .frame(minHeight: 44)
                    }
                case .idle, .loading:
                    if let report = store.report {
                        if report.totalAnswers == 0 {
                            StudyReportCard {
                                Image(systemName: "book.closed").font(.largeTitle).foregroundStyle(Color(AppColor.primary))
                                StudyReportHeading(
                                    title: String(localized: "첫 학습을 기다리고 있어요"),
                                    subtitle: String(localized: "퀴즈에서 답변을 저장하면 학습량과 정답률을 확인할 수 있어요.")
                                )
                            }
                        } else {
                            if report.periodAnswerCount == 0 {
                                StudyReportSelection(text: String(localized: "선택한 기간에 학습 기록이 없어요. 다른 기간을 선택해 보세요."))
                            }

                            StudyReportCard {
                                StudyReportHeading(title: String(localized: "학습한 단어 수"))
                                StudyReportActivityChart(report: report, selected: Binding(
                                    get: { store.selectedActivity }, set: { store.send(.activitySelected($0)) }
                                ))
                            }

                            StudyReportCard {
                                StudyReportHeading(title: String(localized: "회차별 정답률"))
                                StudyReportSessionChart(report: report, selected: Binding(
                                    get: { store.selectedSession }, set: { store.send(.sessionSelected($0)) }
                                ))
                            }

                            StudyReportCard {
                                StudyReportHeading(title: String(localized: "주제별 학습 비중"))
                                StudyReportCategoryBars(categories: report.topics, kind: .topic, selected: store.selectedTopic) {
                                    store.send(.topicSelected($0))
                                }
                            }

                            StudyReportCard {
                                StudyReportHeading(title: String(localized: "학습 단어의 품사"))
                                StudyReportPartsChart(report: report, selected: store.selectedPart) { store.send(.partSelected($0)) }
                                    .id(report.period)
                            }

                            StudyReportCard {
                                StudyReportHeading(title: String(localized: "많이 틀린 종류"))
                                // subtitle: "오답 횟수 기준"
                                Picker(
                                    "오답 분류",
                                    selection: Binding(get: { store.mistakeKind }, set: { store.send(.mistakeKindChanged($0)) })
                                ) {
                                    ForEach(StudyReportCategoryKind.allCases, id: \.self) { Text($0.title).tag($0) }
                                }.pickerStyle(.segmented)
                                    .accessibilityIdentifier("studyReport.mistakeKind")
                                StudyReportCategoryBars(
                                    categories: store.mistakeKind == .topic ? report.topics : report.mistakesByPart,
                                    kind: store.mistakeKind, showsMistakes: true, selected: store.selectedMistake
                                ) { store.send(.mistakeSelected($0)) }
                            }

                            StudyReportCard {
                                HStack(alignment: .top) {
                                    StudyReportHeading(title: String(localized: "많이 맞힌 단어"))
                                    Spacer()
                                    Button("전체 보기") { store.send(.wordsTapped(store.period)) }
                                        .font(StudyReportStyle.font(AppFont.label, relativeTo: .subheadline))
                                        .frame(minHeight: 44)
                                }
                                if report.words.isEmpty {
                                    StudyReportSelection(text: String(localized: "선택한 기간에 학습한 단어가 없어요."))
                                }
                                ForEach(Array(report.words.prefix(5).enumerated()), id: \.element.id) { index, word in
                                    Button { store.send(.wordTapped(word.id)) } label: {
                                        HStack(alignment: .top, spacing: AppSpacing.space12) {
                                            Text("\(index + 1)").foregroundStyle(.secondary)
                                            VStack(alignment: .leading, spacing: AppSpacing.space8) {
                                                HStack { Text(word.snapshot.wordSnapshot).bold(); Spacer(); Text("\(word.correct)회") }
                                                Text(word.snapshot.meaningSnapshot).foregroundStyle(.secondary)
                                                StudyReportHorizontalBar(value: word.correct, maximum: report.words.first?.correct ?? 1)
                                                Text("정답률 \(StudyReportStyle.percent(word.correct, word.total)) · 전체 \(word.total)회 풀이")
                                                    .font(StudyReportStyle.font(AppFont.footnote, relativeTo: .footnote))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }.contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityIdentifier("studyReport.rank.\(index + 1)")
                                    .accessibilityElement(children: .combine)
                                }
                            }
                        }
                    }
                }
            }
            .padding(AppSpacing.space20)
        }
        .background(Color(AppColor.background).ignoresSafeArea())
        .foregroundStyle(Color(AppColor.textPrimary))
        .font(StudyReportStyle.font(AppFont.body))
        .navigationTitle("학습 리포트")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { store.send(.closeButtonTapped) } label: {
                    Image(systemName: "xmark").frame(minWidth: 40, minHeight: 40)
                }
                .accessibilityLabel("학습 리포트 닫기")
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
}
