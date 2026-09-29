import Charts
import SwiftUI
import UIKit

// MARK: - Report styling

extension StudyReportPeriod {
    var title: String {
        switch self {
        case .week: return "최근 7일"
        case .month: return "이번 달"
        case .all: return "전체"
        }
    }
}

extension StudyReportCategoryKind {
    var title: String { self == .topic ? "주제" : "품사" }

    func title(for id: String?) -> String {
        switch identifier(id) {
        case "travel": return "여행"
        case "business": return "비즈니스"
        case "emotion": return "감정"
        case "life": return "일상"
        case "noun": return "명사"
        case "verb": return "동사"
        case "adj": return "형용사"
        case "adv": return "부사"
        default: return "미분류"
        }
    }
}

enum StudyReportStyle {
    static func font(_ font: UIFont, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(font.fontName, size: font.pointSize, relativeTo: style)
    }

    static func percent(_ numerator: Int, _ denominator: Int) -> String {
        guard denominator > 0 else { return "—" }
        return "\(Int((Double(numerator) / Double(denominator) * 100).rounded()))%"
    }

    static func date(_ date: Date, calendar: Calendar, format: String = "M.d") -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
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

struct StudyReportCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.space16) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.space20)
            .background(colorScheme == .dark ? Color(uiColor: .secondarySystemGroupedBackground) : Color(AppColor.card))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.radius16))
    }
}

struct StudyReportHeading: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.space4) {
            Text(title).font(StudyReportStyle.font(AppFont.title3, relativeTo: .headline))
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle).font(StudyReportStyle.font(AppFont.footnote, relativeTo: .footnote))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct StudyReportSelection: View {
    let text: String

    var body: some View {
        Text(text)
            .font(StudyReportStyle.font(AppFont.footnote, relativeTo: .footnote))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.space12)
            .background(Color(AppColor.gray45).opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.radius8))
    }
}

struct StudyReportWordCard: View {
    let word: StudyReport.Word

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.space12) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: AppSpacing.space8) {
                    Text(StudyReportCategoryKind.partOfSpeech.title(for: word.snapshot.partOfSpeechSnapshot))
                        .font(StudyReportStyle.font(AppFont.label, relativeTo: .subheadline))
                        .padding(.horizontal, AppSpacing.space12)
                        .frame(minHeight: 24)
                        .overlay(Capsule().stroke(.black, lineWidth: AppBorder.regular))
                    Spacer(minLength: AppSpacing.space8)
                    Text("정답 \(word.correct) / \(word.total)회")
                        .font(StudyReportStyle.font(AppFont.footnote, relativeTo: .footnote))
                        .multilineTextAlignment(.trailing)
                }
                Spacer(minLength: AppSpacing.space24)
                HStack(alignment: .bottom, spacing: AppSpacing.space12) {
                    VStack(alignment: .leading, spacing: AppSpacing.space4) {
                        Text(word.snapshot.wordSnapshot)
                            .font(StudyReportStyle.font(AppFont.title1, relativeTo: .title))
                        Text(word.snapshot.meaningSnapshot)
                            .font(StudyReportStyle.font(AppFont.footnote, relativeTo: .footnote))
                    }
                    Spacer(minLength: AppSpacing.space8)
                    Text(StudyReportStyle.percent(word.correct, word.total))
                        .font(StudyReportStyle.font(AppFont.largeDisplay, relativeTo: .largeTitle))
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

struct StudyReportHorizontalBar: View {
    let value: Int
    let maximum: Int
    var color: Color = Color(AppColor.primary)

    var body: some View {
        Chart {
            BarMark(xStart: .value("시작", 0), xEnd: .value("횟수", max(1, maximum)), y: .value("항목", ""))
                .foregroundStyle(Color(AppColor.gray45).opacity(0.15))
            BarMark(xStart: .value("시작", 0), xEnd: .value("횟수", value), y: .value("항목", ""))
                .foregroundStyle(color)
        }
        .chartXScale(domain: 0...max(1, maximum))
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 8)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }
}

struct StudyReportAnswerBar: View {
    let total: Int
    let wrong: Int

    var body: some View {
        let correct = total - wrong
        GeometryReader { geometry in
            let width = geometry.size.width
            let correctWidth = wrong == 0 ? width : correct == 0 ? 0 : min(
                max(width * CGFloat(correct) / CGFloat(total), min(70, width / 2)),
                width - min(52, width / 2)
            )
            HStack(spacing: 0) {
                if total == 0 {
                    Color(AppColor.gray45).opacity(0.15)
                        .frame(width: width, height: 20)
                } else {
                    if correct > 0 {
                        Text("\(correct)")
                            .foregroundStyle(.black)
                            .frame(width: correctWidth, height: 20)
                            .background(Color(AppColor.appGreen))
                    }
                    if wrong > 0 {
                        Text("\(wrong)")
                            .foregroundStyle(.white)
                            .frame(width: width - correctWidth, height: 20)
                            .background(Color(AppColor.appRed))
                    }
                }
            }
            .font(StudyReportStyle.font(AppFont.font(.medium, size: 11), relativeTo: .caption))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .clipShape(Capsule())
        }
        .frame(height: 20)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("정답 \(correct)회, 오답 \(wrong)회")
    }
}

struct StudyReportCategoryBars: View {
    let categories: [StudyReport.Category]
    let kind: StudyReportCategoryKind
    var showsMistakes = false
    let selected: String?
    let onSelect: (String) -> Void

    private var sorted: [StudyReport.Category] {
        categories.sorted {
            let left = showsMistakes ? $0.wrong : $0.total
            let right = showsMistakes ? $1.wrong : $1.total
            return left == right ? $0.id < $1.id : left > right
        }
    }

    var body: some View {
        let maximum = max(1, categories.map { showsMistakes ? $0.wrong : $0.total }.max() ?? 0)
        let total = categories.reduce(0) { $0 + $1.total }
        VStack(spacing: AppSpacing.space12) {
            ForEach(sorted) { group in
                Button { onSelect(group.id) } label: {
                    VStack(alignment: .leading, spacing: AppSpacing.space8) {
                        HStack {
                            Text(kind.title(for: group.id))
                            Spacer()
                            if showsMistakes && group.total > 0 {
                                Text("전체 \(group.total)회 · 오답률 \(StudyReportStyle.percent(group.wrong, group.total))")
                                    .font(StudyReportStyle.font(AppFont.footnote, relativeTo: .footnote))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            } else if !showsMistakes {
                                Text("\(group.total)회").monospacedDigit()
                            }
                            if selected == group.id { Image(systemName: "checkmark.circle.fill") }
                        }
                        if showsMistakes {
                            StudyReportAnswerBar(total: group.total, wrong: group.wrong)
                        } else {
                            StudyReportHorizontalBar(
                                value: group.total,
                                maximum: maximum,
                                color: Color(AppColor.primary).opacity(selected == nil || selected == group.id ? 1 : 0.5)
                            )
                        }
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("studyReport.\(showsMistakes ? "mistakes" : "topics").\(group.id)")
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(selected == group.id ? .isSelected : [])
            }
            if !showsMistakes {
                HStack { Text("0회"); Spacer(); Text("\(maximum)회") }
                    .font(StudyReportStyle.font(AppFont.caption, relativeTo: .caption))
                    .foregroundStyle(.secondary)
            }
            if let group = categories.first(where: { $0.id == selected }), !showsMistakes || group.total > 0 {
                StudyReportSelection(text: showsMistakes
                    ? "\(kind.title(for: group.id)) · 오답 \(group.wrong) / 풀이 \(group.total)회 · \(StudyReportStyle.percent(group.wrong, group.total))"
                    : "\(kind.title(for: group.id)) · \(group.total)회 풀이 · 전체의 \(StudyReportStyle.percent(group.total, total))")
            }
            // else { StudyReportSelection(text: "\(kind.title)를 누르면 \(showsMistakes ? "오답 내역" : "풀이 비중")을 확인할 수 있어요.") }
        }
    }
}

struct StudyReportActivityChart: View {
    let report: StudyReport
    @Binding var selected: Date?

    private var selection: Binding<Int?> {
        Binding(
            get: { report.activity.firstIndex { $0.date == selected } },
            set: { index in
                selected = index.flatMap { report.activity.indices.contains($0) ? report.activity[$0].date : nil }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.space12) {
            GeometryReader { geometry in
                ScrollView(.horizontal) {
                    Chart(Array(report.activity.enumerated()), id: \.element.id) { index, day in
                        BarMark(x: .value("날짜", index), y: .value("고유 단어", day.count), width: .ratio(0.65))
                            .foregroundStyle(Color(AppColor.primary).opacity(selected == day.date ? 1 : 0.45))
                            .cornerRadius(4)
                            .accessibilityLabel(StudyReportStyle.date(day.date, calendar: report.calendar, format: "yyyy년 M월 d일"))
                            .accessibilityValue("학습 단어 \(day.count)개")
                    }
                    .chartXScale(domain: -0.5...Double(max(1, report.activity.count)) - 0.5)
                    .chartYScale(domain: 0...max(1, report.activity.map(\.count).max() ?? 0))
                    .chartXAxis {
                        AxisMarks(values: Array(report.activity.indices)) { value in
                            AxisValueLabel {
                                if let index = value.as(Int.self), report.activity.indices.contains(index) {
                                    Text(StudyReportStyle.date(report.activity[index].date, calendar: report.calendar,
                                                              format: report.period == .all ? "yy.M" : "M.d"))
                                }
                            }
                        }
                    }
                    .chartYAxis { AxisMarks(position: .leading) }
                    .chartXSelection(value: selection)
                    .frame(width: max(geometry.size.width, CGFloat(report.activity.count) * 44), height: 180)
                }
                .defaultScrollAnchor(.trailing)
            }
            .frame(height: 190)
            if let day = report.activity.first(where: { $0.date == selected }) {
                StudyReportSelection(text: "\(StudyReportStyle.date(day.date, calendar: report.calendar, format: report.period == .all ? "yyyy년 M월" : "M월 d일")) · 학습한 단어 \(day.count)개")
            }
            // else { StudyReportSelection(text: "막대를 누르면 학습한 단어 수를 확인할 수 있어요.") }
            // Text("같은 단어를 여러 \(report.period == .all ? "달" : "날") 학습할 수 있어 막대의 합과 기간 전체 단어 수는 달라요.")
            //     .font(StudyReportStyle.font(AppFont.footnote, relativeTo: .footnote))
            //     .foregroundStyle(.secondary)
        }
    }
}

struct StudyReportSessionChart: View {
    let report: StudyReport
    @Binding var selected: Int?

    var body: some View {
        if report.sessions.isEmpty {
            StudyReportSelection(text: "완료한 회차가 아직 없어요.\n회차별 기록은 리포트 기능 도입 이후 모든 답변을 저장한 퀴즈부터 표시돼요.")
        } else {
            Chart(Array(report.sessions.enumerated()), id: \.element.id) { index, session in
                if report.sessions.count > 1 {
                    LineMark(x: .value("회차", index), y: .value("정답률", session.accuracy * 100))
                        .foregroundStyle(Color(AppColor.primary))
                }
                PointMark(x: .value("회차", index), y: .value("정답률", session.accuracy * 100))
                    .foregroundStyle(Color(AppColor.primary))
                    .symbolSize(selected == index ? 90 : 40)
                    .accessibilityLabel(StudyReportStyle.date(session.completedAt, calendar: report.calendar, format: "M월 d일 HH:mm"))
                    .accessibilityValue("정답 \(session.correct) / \(session.total)문제, \(StudyReportStyle.percent(session.correct, session.total))")
            }
            .chartYScale(domain: 0...100)
            .chartXScale(domain: -0.5...Double(report.sessions.count) - 0.5)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 50, 100]) { value in
                    AxisGridLine()
                    AxisValueLabel { if let rate = value.as(Int.self) { Text("\(rate)%") } }
                }
            }
            .chartXAxis {
                AxisMarks(values: Array(Set([0, report.sessions.count / 2, report.sessions.count - 1])).sorted()) { value in
                    AxisValueLabel {
                        if let index = value.as(Int.self), report.sessions.indices.contains(index) {
                            Text(StudyReportStyle.date(report.sessions[index].completedAt, calendar: report.calendar))
                        }
                    }
                }
            }
            .chartXSelection(value: $selected)
            .frame(height: 180)
            if let selected, report.sessions.indices.contains(selected) {
                let session = report.sessions[selected]
                StudyReportSelection(text: "\(StudyReportStyle.date(session.completedAt, calendar: report.calendar, format: "M.d HH:mm")) · 정답 \(session.correct) / \(session.total)문제 · \(StudyReportStyle.percent(session.correct, session.total))")
            }
        }
    }
}

struct StudyReportPartsChart: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let report: StudyReport
    let selected: String?
    let onSelect: (String?) -> Void
    @State private var selectedAngle: Double?

    var body: some View {
        if report.words.isEmpty {
            StudyReportSelection(text: "선택한 기간에 학습한 단어가 없어요.")
        } else {
            let layout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 16)) : AnyLayout(HStackLayout(spacing: 16))
            layout {
                Chart(Array(report.parts.enumerated()).filter { $0.element.total > 0 }, id: \.element.id) { index, part in
                    SectorMark(angle: .value("단어", part.total), innerRadius: .ratio(0.68), angularInset: 2)
                        .foregroundStyle(StudyReportStyle.color(index))
                        .opacity(selected == nil || selected == part.id ? 1 : 0.45)
                        .accessibilityLabel(StudyReportCategoryKind.partOfSpeech.title(for: part.id))
                        .accessibilityValue("\(part.total)개, \(StudyReportStyle.percent(part.total, report.words.count))")
                }
                .chartAngleSelection(value: $selectedAngle)
                .chartBackground { _ in
                    VStack(spacing: 2) {
                        Text("\(report.words.count)").font(StudyReportStyle.font(AppFont.title2, relativeTo: .title2))
                        Text("고유 단어").font(StudyReportStyle.font(AppFont.caption, relativeTo: .caption))
                    }.accessibilityHidden(true)
                }
                .frame(width: 126, height: 126)
                VStack(spacing: 0) {
                    ForEach(Array(report.parts.enumerated()), id: \.element.id) { index, part in
                        Button { onSelect(part.id) } label: {
                            HStack(spacing: AppSpacing.space4) {
                                Circle().fill(StudyReportStyle.color(index)).frame(width: 8, height: 8)
                                Text(StudyReportCategoryKind.partOfSpeech.title(for: part.id))
                                Spacer(minLength: 2)
                                Text("\(part.total)개 · \(StudyReportStyle.percent(part.total, report.words.count))")
                                    .monospacedDigit()
                            }
                            .font(StudyReportStyle.font(AppFont.label, relativeTo: .subheadline))
                            .fontWeight(selected == part.id ? .bold : .regular)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selected == part.id ? .isSelected : [])
                    }
                }
            }
            .onChange(of: selectedAngle) { _, angle in
                guard let angle else { onSelect(nil); return }
                var upperBound = 0
                for part in report.parts where part.total > 0 {
                    upperBound += part.total
                    if angle < Double(upperBound) { onSelect(part.id); return }
                }
                onSelect(report.parts.last(where: { $0.total > 0 })?.id)
            }
            if let part = report.parts.first(where: { $0.id == selected }) {
                StudyReportSelection(text: "\(StudyReportCategoryKind.partOfSpeech.title(for: part.id)) · \(part.total) / \(report.words.count)개 · \(StudyReportStyle.percent(part.total, report.words.count))")
            }
            // else { StudyReportSelection(text: "품사를 누르면 비율을 확인할 수 있어요.") }
        }
    }
}
