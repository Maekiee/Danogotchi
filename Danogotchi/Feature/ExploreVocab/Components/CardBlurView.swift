import SwiftUI

struct CardBlurView: View {
    var title: String = ""
    var subtitle: String = ""
    var learningCount: Int = 0
    var progress: Double = 0.0
    var isSpeaking: Bool = false
    var isSaved: Bool = false
    var showsSaveButton: Bool = true
    var onSpeakerTap: (() -> Void)?
    var onSaveTap: (() -> Void)?
    
    var body: some View {
        ZStack {
            // 단어 · 뜻은 카드 정중앙
            VStack(spacing: 6) {
                Text(title)
                    .font(Font(AppFont.display))
                    .lineLimit(2)

                Text(subtitle)
                    .font(Font(AppFont.font(.medium, size: 18)))
            }
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)

            // 네 모서리 (좌상: 저장 / 우상: 발음 / 좌하: 학습 횟수 / 우하: 정답률)
            VStack(spacing: 0) {
                HStack {
                    if showsSaveButton {
                        Button {
                            onSaveTap?()
                        } label: {
                            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                .font(.title3)
                                .foregroundStyle(.white)
                        }
                    }

                    Spacer()

                    Button {
                        onSpeakerTap?()
                    } label: {
                        Image(systemName: "speaker.wave.2")
                            .font(.title3)
                            .foregroundStyle(isSpeaking ? Color(AppColor.black) : .white)
                            // 배경 원은 레이아웃에 영향을 주지 않아 아이콘 위치가 그대로 유지된다
                            .background(
                                Circle()
                                    .fill(.white)
                                    .frame(width: 36, height: 36)
                                    .opacity(isSpeaking ? 1 : 0)
                            )
                    }
                }

                Spacer()

                HStack(alignment: .bottom) {
                    Text("\(learningCount)번 학습")
                        .font(Font(AppFont.footnote))

                    Spacer(minLength: AppSpacing.space8)

                    HStack(alignment: .firstTextBaseline, spacing: 0) {
                        Text("\(Int(progress * 100))")
                            .font(Font(AppFont.largeDisplay))
                        Text("%")
                            .font(Font(AppFont.font(.bold, size: 14)))
                    }
                }
                .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 20)
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .background {
            TransparentBlurView(removeAllFilters: true)
                .blur(radius: 5, opaque: true)
                .background(.white.opacity(0.15))
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.radius20))
    }
}


// MARK: 투평도 조절
struct TransparentBlurView: UIViewRepresentable {
    var removeAllFilters: Bool = false
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        DispatchQueue.main.async {
            if let backdropLayer = uiView.layer.sublayers?.first {
                if removeAllFilters {
                    backdropLayer.filters = []
                } else {
                    backdropLayer.filters?.removeAll(where: { filter in
                        String(describing: filter) != "gaussianBlur"
                     })
                }
            }
        }
    }
}


// MARK: - Preview
#if DEBUG
#Preview("CardBlurView") {
    // 투명 블러 카드라 배경이 있어야 블러가 보인다 (실사용 시 테마 이미지 위에 올라감)
    ZStack {
        LinearGradient(
            colors: [.orange, .pink, .indigo],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: AppSpacing.space16) {
            CardBlurView(
                title: "apple",
                subtitle: "사과",
                learningCount: 12,
                progress: 0.65
            )

            // 발음 중 + 나의 단어장에 저장됨
            CardBlurView(
                title: "banana",
                subtitle: "바나나",
                learningCount: 3,
                progress: 0.2,
                isSpeaking: true,
                isSaved: true
            )

            // 활성 단어장이 나의 단어장 → 저장 버튼 숨김
            CardBlurView(
                title: "cherry",
                subtitle: "체리",
                learningCount: 0,
                progress: 0,
                showsSaveButton: false
            )
        }
        .padding(.horizontal, 28) // MainWordCardCollectionViewCell과 동일한 inset
    }
}
#endif
