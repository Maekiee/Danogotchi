import SwiftUI

struct CardBlurView: View {
    
    var title: String = ""
    var subtitle: String = ""
    var learningCount: Int = 0
    var progress: Double = 0.0
    var onSpeakerTap: (() -> Void)?
    var onModifyTap: (() -> Void)?
    
    var body: some View {
        VStack {
            Button {
                // 액션
                print("다다다다닫")
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.black.opacity(0.8))
                    .padding(.vertical, 4)
                    .padding(.horizontal, 12)
                    .background(
                        Color.white.opacity(0.2)
                            .background(.ultraThinMaterial)
                    )
                    .cornerRadius(16)
            }
            .buttonStyle(.plain)
            
            VStack {
                HStack {
                    Text(title)
                        .font(.title)
                    Button {
                        onSpeakerTap?()
                        print("버튼 버튼")
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                    }
                }
                Text(subtitle)
                Text("\(learningCount)번 학습")
                Gauge(value: 0.7) {
                    
                }
            }
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .background {
                TransparentBlurView(removeAllFilters: true)
                    .blur(radius: 6, opaque: true)
                    .background(.white.opacity(0.15))
            }.clipShape(RoundedRectangle(cornerRadius: 20))
        }
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
