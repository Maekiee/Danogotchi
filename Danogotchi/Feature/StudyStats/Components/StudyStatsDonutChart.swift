import Charts
import SwiftUI

// 주제·품사 비율 도넛 차트 UI
struct StudyStatsDonutChart: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let categories: [StudyStats.Category]
    let kind: StudyStatsCategoryKind
    let selected: String?
    let onSelect: (String?) -> Void
    @State private var selectedAngle: Double?

    var body: some View {
        let total = categories.reduce(0) { $0 + $1.total }
        let layout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 16)) : AnyLayout(HStackLayout(spacing: 16))
        layout {
            Chart(Array(categories.enumerated()).filter { $0.element.total > 0 }, id: \.element.id) { index, category in
                let value = "\(count(category.total)), \(StudyStatsStyle.percent(category.total, total))"
                SectorMark(angle: .value("값", category.total), innerRadius: .ratio(0.68), angularInset: 2)
                    .foregroundStyle(color(index, category.id))
                    .opacity(selected == nil || selected == category.id ? 1 : 0.45)
                    .accessibilityLabel(title(category.id))
                    .accessibilityValue(value)
            }
            .chartAngleSelection(value: $selectedAngle)
            .chartBackground { _ in
                VStack(spacing: 2) {
                    Text("\(total)").font(StudyStatsStyle.font(AppFont.title2, relativeTo: .title2))
                    Text(kind == .topic ? String(localized: "회 풀이") : String(localized: "고유 단어"))
                        .font(StudyStatsStyle.font(AppFont.caption, relativeTo: .caption))
                }.accessibilityHidden(true)
            }
            .frame(width: 126, height: 126)
            VStack(spacing: 0) {
                ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                    let value = "\(count(category.total)) · \(StudyStatsStyle.percent(category.total, total))"
                    Button { onSelect(category.id) } label: {
                        HStack(spacing: AppSpacing.space4) {
                            Circle().fill(color(index, category.id)).frame(width: 8, height: 8)
                            Text(title(category.id))
                            Spacer(minLength: 2)
                            Text(value).monospacedDigit()
                        }
                        .font(StudyStatsStyle.font(AppFont.label, relativeTo: .subheadline))
                        .fontWeight(selected == category.id ? .bold : .regular)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("studyStats.\(kind == .topic ? "topics" : "parts").\(category.id)")
                    .accessibilityAddTraits(selected == category.id ? .isSelected : [])
                }
            }
        }
        .onChange(of: selectedAngle) { _, angle in
            guard let angle else { onSelect(nil); return }
            var upperBound = 0
            for category in categories where category.total > 0 {
                upperBound += category.total
                if angle < Double(upperBound) { onSelect(category.id); return }
            }
            onSelect(categories.last(where: { $0.total > 0 })?.id)
        }
        if let category = categories.first(where: { $0.id == selected }) {
            let percent = StudyStatsStyle.percent(category.total, total)
            StudyStatsSelection(text: String(localized: "\(title(category.id)) · \(count(category.total)) · 전체의 \(percent)"))
        }
    }

    // 주제는 풀이 횟수, 품사는 고유 단어 수
    private func count(_ value: Int) -> String {
        kind == .topic ? String(localized: "\(value)회") : String(localized: "\(value)개")
    }

    private func title(_ id: String) -> String {
        kind == .topic ? StudyStatsStyle.topicTitle(id) : StudyStatsStyle.partTitle(id)
    }

    private func color(_ index: Int, _ id: String) -> Color {
        kind == .topic ? Color(BookTopic(rawValue: id)?.color ?? AppColor.gray45) : StudyStatsStyle.color(index)
    }
}
