import ComposableArchitecture
import SwiftUI

struct StudyStatsView: View {
    let store: StoreOf<StudyStatsFeature>
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.space16) {
                if let stats = store.stats, stats.totalAnswers > 0 {
                    StudyStatsCard {
                        let layout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 20))
                            : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
                        layout {
                            Button { store.send(.wordsTapped) } label: {
                                VStack(alignment: .leading, spacing: AppSpacing.space8) {
                                    Text("누적 학습 단어 ›").font(StudyStatsStyle.font(AppFont.label, relativeTo: .subheadline))
                                    Text("\(stats.words.count)개")
                                        .font(StudyStatsStyle.font(AppFont.display, relativeTo: .largeTitle)).monospacedDigit()
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .accessibilityElement(children: .combine)
                            }
                            .buttonStyle(.plain)
                            .disabled(store.loadStatus == .failed)
                            VStack(alignment: .leading, spacing: AppSpacing.space8) {
                                Text("총 정답률").font(StudyStatsStyle.font(AppFont.label, relativeTo: .subheadline))
                                Text(StudyStatsStyle.percent(stats.totalCorrect, stats.totalAnswers))
                                    .font(StudyStatsStyle.font(AppFont.display, relativeTo: .largeTitle)).monospacedDigit()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityElement(children: .combine)
                        }
                    }
                }

                switch store.loadStatus {
                // 첫 진입만 스켈레톤, 이후 로딩은 이전 통계 유지
                case .loading where store.stats == nil:
                    VStack(spacing: AppSpacing.space16) {
                        ProgressView("학습 기록을 불러오고 있어요.").padding()
                        ForEach(0..<3) { _ in
                            RoundedRectangle(cornerRadius: AppRadius.radius16)
                                .fill(Color(AppColor.gray45).opacity(0.12)).frame(height: 150)
                                .accessibilityHidden(true)
                        }
                    }.frame(maxWidth: .infinity)
                case .failed:
                    StudyStatsCard {
                        Image(systemName: "exclamationmark.circle").font(.largeTitle)
                        StudyStatsHeading(
                            title: String(localized: "기록을 불러오지 못했어요"),
                            subtitle: String(localized: "잠시 후 다시 시도해 주세요. 저장된 학습 기록은 그대로 남아 있어요.")
                        )
                        Button("다시 시도") { store.send(.refresh) }
                            .buttonStyle(.borderedProminent).tint(Color(AppColor.primary))
                            .frame(minHeight: 44)
                    }
                case .idle, .loading:
                    if let stats = store.stats {
                        if stats.totalAnswers == 0 {
                            StudyStatsCard {
                                Image(systemName: "book.closed").font(.largeTitle).foregroundStyle(Color(AppColor.primary))
                                StudyStatsHeading(
                                    title: String(localized: "첫 학습을 기다리고 있어요"),
                                    subtitle: String(localized: "퀴즈에서 답변을 저장하면 학습량과 정답률을 확인할 수 있어요.")
                                )
                            }
                        } else {
                            StudyStatsCard {
                                StudyStatsHeading(title: String(localized: "주제별 학습 비중"), subtitle: String(localized: "풀이 횟수 기준"))
                                StudyStatsDonutChart(categories: stats.topics, kind: .topic, selected: store.selectedTopic) {
                                    store.send(.topicSelected($0))
                                }
                            }

                            StudyStatsCard {
                                StudyStatsHeading(title: String(localized: "학습 단어의 품사"), subtitle: String(localized: "고유 단어 기준"))
                                StudyStatsDonutChart(categories: stats.parts, kind: .partOfSpeech, selected: store.selectedPart) {
                                    store.send(.partSelected($0))
                                }
                            }

                            StudyStatsCard {
                                let threshold = store.mistakeThreshold
                                let words = stats.mistakeWords.filter(threshold.contains)
                                StudyStatsHeading(
                                    title: String(localized: "많이 틀린 단어"),
                                    subtitle: String(localized: "정답률 \(threshold.rawValue)% 이하 · \(words.count)개")
                                )
                                Picker(
                                    "정답률 기준",
                                    selection: Binding(get: { store.mistakeThreshold }, set: { store.send(.mistakeThresholdChanged($0)) })
                                ) {
                                    ForEach(StudyStatsMistakeThreshold.allCases, id: \.self) { Text("\($0.rawValue)% 이하").tag($0) }
                                }
                                .pickerStyle(.segmented)
                                .accessibilityIdentifier("studyStats.mistakeThreshold")
                                if words.isEmpty {
                                    StudyStatsSelection(text: String(localized: "정답률 \(threshold.rawValue)% 이하인 단어가 없어요"))
                                } else {
                                    LazyVStack(spacing: 0) {
                                        ForEach(Array(words.enumerated()), id: \.element.id) { index, word in
                                            if index > 0 { Divider() }
                                            Button { store.send(.wordTapped(word.id)) } label: {
                                                VStack(alignment: .leading, spacing: AppSpacing.space4) {
                                                    HStack(alignment: .firstTextBaseline, spacing: AppSpacing.space8) {
                                                        Text(word.snapshot.wordSnapshot)
                                                            .font(StudyStatsStyle.font(AppFont.bodyEmphasis))
                                                        Spacer(minLength: 0)
                                                        Text("오답 \(word.total - word.correct)회")
                                                            .font(StudyStatsStyle.font(AppFont.label, relativeTo: .subheadline))
                                                            .monospacedDigit()
                                                    }
                                                    Group {
                                                        Text(word.snapshot.meaningSnapshot)
                                                        let percent = StudyStatsStyle.percent(word.correct, word.total)
                                                        Text("정답률 \(percent) · 전체 \(word.total)회 풀이").monospacedDigit()
                                                    }
                                                    .font(StudyStatsStyle.font(AppFont.footnote, relativeTo: .footnote))
                                                    .foregroundStyle(Color(AppColor.textSecondary))
                                                }
                                                .padding(.top, index == 0 ? 0 : AppSpacing.space12)
                                                .padding(.bottom, index == words.count - 1 ? 0 : AppSpacing.space12)
                                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                                .contentShape(Rectangle())
                                            }
                                            .buttonStyle(.plain)
                                            .accessibilityElement(children: .combine)
                                            .accessibilityIdentifier("studyStats.mistake.\(index + 1)")
                                        }
                                    }
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
        .font(StudyStatsStyle.font(AppFont.body))
        .navigationTitle("학습 통계")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { store.send(.closeButtonTapped) } label: {
                    Image(systemName: "xmark").frame(minWidth: 40, minHeight: 40)
                }
                .accessibilityLabel("학습 통계 닫기")
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
