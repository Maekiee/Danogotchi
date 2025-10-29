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
            Spacer().frame(height: 32)
            HStack(alignment: .lastTextBaseline) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Button {
                    onSpeakerTap?()
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
            }
            Spacer().frame(height: 4)
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.white)
                .fontWeight(.medium)
            
            Text("\(learningCount)번 학습")
                .font(.caption)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .fontWeight(.regular)
                .background(.black.opacity(0.4))
                .clipShape(Capsule())
            
            Spacer()
            HStack {
                SimpleGaugeBar(progress: progress)
    
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .fontWeight(.regular)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .background {
            TransparentBlurView(removeAllFilters: true)
                .blur(radius: 5, opaque: true)
                .background(.white.opacity(0.15))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(alignment: .topTrailing) {
            Button {
                onModifyTap?()
            } label: {
                Image(systemName: "ellipsis")
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        Color.white.opacity(0.2)
                            .background(.ultraThinMaterial)
                    )
                    .cornerRadius(16)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(12)
        }
    }
}




struct SimpleGaugeBar: View {
    var progress: Double // 0.0 ~ 1.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 배경
                Capsule()
                    .fill(Color.white.opacity(0.2))
                
                // 진행 바
                Capsule()
                    .fill(SwiftUIAppColor.oxfordBlue)
                    .frame(width: geometry.size.width * progress)
            }
        }
        .frame(height: 8)
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
