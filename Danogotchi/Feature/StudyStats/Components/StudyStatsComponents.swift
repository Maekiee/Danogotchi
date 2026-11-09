import Charts
import SwiftUI
import UIKit

// MARK: - Stats styling

extension StudyStatsCategoryKind {
    func title(for id: String?) -> String {
        switch identifier(id) {
        case "travel": return String(localized: "여행")
        case "business": return String(localized: "비즈니스")
        case "emotion": return String(localized: "감정")
        case "life": return String(localized: "일상")
        case "noun": return String(localized: "명사")
        case "verb": return String(localized: "동사")
        case "adj": return String(localized: "형용사")
        case "adv": return String(localized: "부사")
        default: return String(localized: "미분류")
        }
    }
}

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

// 통계 카드 컨테이너 UI
struct StudyStatsCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.space16) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.space20)
            .background(Color(AppColor.card))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.radius16))
    }
}

// 카드 제목·부제 UI
struct StudyStatsHeading: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.space4) {
            Text(title).font(StudyStatsStyle.font(AppFont.title3, relativeTo: .headline))
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle).font(StudyStatsStyle.font(AppFont.footnote, relativeTo: .footnote))
                    .foregroundStyle(Color(AppColor.textSecondary))
            }
        }
    }
}

// 선택 항목 안내 박스 UI
struct StudyStatsSelection: View {
    let text: String

    var body: some View {
        Text(text)
            .font(StudyStatsStyle.font(AppFont.footnote, relativeTo: .footnote))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.space12)
            .background(Color(AppColor.gray45).opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.radius8))
    }
}

// 단어 학습 카드 UI
struct StudyStatsWordCard: View {
    let word: VocabStats

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.space12) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: AppSpacing.space8) {
                    Text(StudyStatsCategoryKind.partOfSpeech.title(for: word.snapshot.partOfSpeechSnapshot))
                        .font(StudyStatsStyle.font(AppFont.label, relativeTo: .subheadline))
                        .padding(.horizontal, AppSpacing.space12)
                        .frame(minHeight: 24)
                        .overlay(Capsule().stroke(.black, lineWidth: AppBorder.regular))
                    Spacer(minLength: AppSpacing.space8)
                    Text("정답 \(word.correct) / \(word.total)회")
                        .font(StudyStatsStyle.font(AppFont.footnote, relativeTo: .footnote))
                        .multilineTextAlignment(.trailing)
                }
                Spacer(minLength: AppSpacing.space24)
                HStack(alignment: .bottom, spacing: AppSpacing.space12) {
                    VStack(alignment: .leading, spacing: AppSpacing.space4) {
                        Text(word.snapshot.wordSnapshot)
                            .font(StudyStatsStyle.font(AppFont.title1, relativeTo: .title))
                        Text(word.snapshot.meaningSnapshot)
                            .font(StudyStatsStyle.font(AppFont.footnote, relativeTo: .footnote))
                    }
                    Spacer(minLength: AppSpacing.space8)
                    Text(StudyStatsStyle.percent(word.correct, word.total))
                        .font(StudyStatsStyle.font(AppFont.largeDisplay, relativeTo: .largeTitle))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
            .padding(18)
            .foregroundStyle(.black)
            .background(Color(AppColor.pastel(for: word.snapshot.wordSnapshot)))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.radius20))
        }
        .accessibilityElement(children: .combine)
    }
}

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
                    .accessibilityLabel(kind.title(for: category.id))
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
                            Text(kind.title(for: category.id))
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
            StudyStatsSelection(text: String(localized: "\(kind.title(for: category.id)) · \(count(category.total)) · 전체의 \(percent)"))
        }
    }

    // 주제는 풀이 횟수, 품사는 고유 단어 수
    private func count(_ value: Int) -> String {
        kind == .topic ? String(localized: "\(value)회") : String(localized: "\(value)개")
    }

    private func color(_ index: Int, _ id: String) -> Color {
        kind == .topic ? Color(BookTopic(rawValue: id)?.color ?? AppColor.gray45) : StudyStatsStyle.color(index)
    }
}
