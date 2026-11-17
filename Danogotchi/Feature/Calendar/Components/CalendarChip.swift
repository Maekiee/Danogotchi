import SwiftUI

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
