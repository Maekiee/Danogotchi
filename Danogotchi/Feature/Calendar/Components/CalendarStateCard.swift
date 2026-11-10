import SwiftUI

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
