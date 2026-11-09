import SwiftUI
import UIKit

// 캘린더 공통 스타일 (글꼴·퍼센트·날짜·농도 색)
enum CalendarStyle {
    static func font(_ font: UIFont, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(font.fontName, size: font.pointSize, relativeTo: style)
    }

    static func percentValue(_ numerator: Int, _ denominator: Int) -> Int {
        denominator > 0 ? Int((Double(numerator) / Double(denominator) * 100).rounded()) : 0
    }

    // 로케일 순서를 따르는 템플릿 형식 (예: MMMdE → 10월 7일 (화))
    static func formatter(_ template: String, calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: Bundle.main.preferredLocalizations.first ?? "ko")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter
    }

    static func date(_ date: Date, calendar: Calendar, template: String) -> String {
        formatter(template, calendar: calendar).string(from: date)
    }

    // 농도 1~4단계 색, 0단계는 화면마다 다르다
    static func levelColor(_ level: Int) -> Color {
        Color(AppColor.grass).opacity([0, 0.25, 0.5, 0.75, 1][min(max(level, 0), 4)])
    }

    static func partTitle(_ rawValue: String?) -> String {
        switch PartOfSpeech(rawValue: rawValue ?? "") {
        case .noun: return String(localized: "명사")
        case .verb: return String(localized: "동사")
        case .adj: return String(localized: "형용사")
        case .adv: return String(localized: "부사")
        case nil: return String(localized: "미분류")
        }
    }
}

// 캘린더 카드 컨테이너 UI
struct CalendarCard<Content: View>: View {
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

// 제목·부제 UI
struct CalendarHeading: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.space4) {
            Text(title).font(CalendarStyle.font(AppFont.title3, relativeTo: .headline))
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle).font(CalendarStyle.font(AppFont.footnote, relativeTo: .footnote))
                    .foregroundStyle(Color(AppColor.textSecondary))
            }
        }
    }
}

// 안내 박스 UI
struct CalendarSelection: View {
    let text: String

    var body: some View {
        Text(text)
            .font(CalendarStyle.font(AppFont.footnote, relativeTo: .footnote))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.space12)
            .background(Color(AppColor.gray45).opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.radius8))
    }
}

// 로딩·빈·실패 상태 UI
struct CalendarStateCard: View {
    enum Kind { case loading, empty, failed }

    let kind: Kind
    var onRetry: () -> Void = {}

    var body: some View {
        switch kind {
        case .loading:
            VStack(spacing: AppSpacing.space16) {
                ProgressView("학습 기록을 불러오고 있어요.").padding()
                // 잔디·달력 카드 자리
                ForEach([158, 440], id: \.self) { height in
                    RoundedRectangle(cornerRadius: AppRadius.radius16)
                        .fill(Color(AppColor.gray45).opacity(0.12)).frame(height: CGFloat(height))
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity)
        case .empty:
            CalendarCard {
                Image(systemName: "book.closed").font(.largeTitle).foregroundStyle(Color(AppColor.primary))
                CalendarHeading(title: String(localized: "학습을 시작하면 잔디와 달력이 채워져요"))
            }
        case .failed:
            CalendarCard {
                Image(systemName: "exclamationmark.circle").font(.largeTitle)
                CalendarHeading(
                    title: String(localized: "기록을 불러오지 못했어요"),
                    subtitle: String(localized: "잠시 후 다시 시도해 주세요. 저장된 학습 기록은 그대로 남아 있어요.")
                )
                Button("다시 시도", action: onRetry)
                    .buttonStyle(.borderedProminent).tint(Color(AppColor.primary))
                    .frame(minHeight: 44)
            }
        }
    }
}

// 연속 학습·총 학습일 칩 UI
struct CalendarChip: View {
    let systemImage: String
    let text: String
    let accessibilityText: String

    var body: some View {
        HStack(spacing: AppSpacing.space4) {
            Image(systemName: systemImage)
            Text(text).monospacedDigit()
        }
        .font(CalendarStyle.font(AppFont.label, relativeTo: .subheadline))
        .foregroundStyle(Color(AppColor.grass))
        .padding(.horizontal, AppSpacing.space12)
        .frame(minHeight: 32)
        .background(Color(AppColor.grass).opacity(0.12), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }
}

// 날짜별 단어 카드 UI (단어장 상세 카드 모양, 북마크 없음)
struct CalendarWordCard: View {
    let word: VocabStats

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(CalendarStyle.partTitle(word.snapshot.partOfSpeechSnapshot))
                .font(CalendarStyle.font(AppFont.label, relativeTo: .subheadline))
                .padding(.horizontal, AppSpacing.space12)
                .frame(minHeight: 24)
                .overlay(Capsule().strokeBorder(Color(AppColor.black), lineWidth: AppBorder.regular))
            Spacer(minLength: AppSpacing.space8)
            HStack(alignment: .bottom, spacing: AppSpacing.space8) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(word.snapshot.wordSnapshot)
                        .font(CalendarStyle.font(AppFont.title1, relativeTo: .title))
                        .lineLimit(2)
                    Text("\(word.snapshot.meaningSnapshot) · \(word.total)번 학습")
                        .font(CalendarStyle.font(AppFont.footnote, relativeTo: .footnote))
                }
                Spacer(minLength: 0)
                (Text("\(CalendarStyle.percentValue(word.correct, word.total))")
                    .font(CalendarStyle.font(AppFont.largeDisplay, relativeTo: .largeTitle))
                 + Text(verbatim: "%").font(CalendarStyle.font(AppFont.font(.bold, size: 14), relativeTo: .footnote)))
                    .monospacedDigit()
                    .fixedSize()
            }
        }
        .padding(.top, 18)
        .padding(.horizontal, 18)
        .padding(.bottom, AppSpacing.space20)
        // 접근성 글자 크기에서 글자가 잘리지 않도록 최소 높이로 둔다
        .frame(maxWidth: .infinity, minHeight: 168, alignment: .leading)
        .foregroundStyle(Color(AppColor.black))
        .background(Color(AppColor.pastel(for: word.snapshot.wordSnapshot)))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.radius20))
    }
}

// 단어 상세 시트 카드 UI, 그날 풀이라 "이날" 접두어
struct CalendarWordDetailCard: View {
    let word: VocabStats

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: AppSpacing.space8) {
                Text(CalendarStyle.partTitle(word.snapshot.partOfSpeechSnapshot))
                    .font(CalendarStyle.font(AppFont.label, relativeTo: .subheadline))
                    .padding(.horizontal, AppSpacing.space12)
                    .frame(minHeight: 24)
                    .overlay(Capsule().strokeBorder(.black, lineWidth: AppBorder.regular))
                Spacer(minLength: AppSpacing.space8)
                Text("이날 정답 \(word.correct) / \(word.total)회")
                    .font(CalendarStyle.font(AppFont.footnote, relativeTo: .footnote))
                    .multilineTextAlignment(.trailing)
            }
            Spacer(minLength: AppSpacing.space24)
            HStack(alignment: .bottom, spacing: AppSpacing.space12) {
                VStack(alignment: .leading, spacing: AppSpacing.space4) {
                    Text(word.snapshot.wordSnapshot)
                        .font(CalendarStyle.font(AppFont.title1, relativeTo: .title))
                    Text(word.snapshot.meaningSnapshot)
                        .font(CalendarStyle.font(AppFont.footnote, relativeTo: .footnote))
                }
                Spacer(minLength: AppSpacing.space8)
                Text("\(CalendarStyle.percentValue(word.correct, word.total))%")
                    .font(CalendarStyle.font(AppFont.largeDisplay, relativeTo: .largeTitle))
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
        .accessibilityElement(children: .combine)
    }
}
