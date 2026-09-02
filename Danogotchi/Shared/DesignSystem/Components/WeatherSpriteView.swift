import UIKit
import OSLog


struct WeatherSpriteSheet: Decodable {

    struct Clip: Decodable {
        let name: String
        let row: Int
        let frameCount: Int
        let fps: Double
        let loop: Bool
    }

    let frameWidth: Int
    let frameHeight: Int
    let clips: [Clip]

    static let manifest: WeatherSpriteSheet? = {
        guard let url = Bundle.main.url(forResource: "weather", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WeatherSpriteSheet.self, from: data)
    }()

    func clip(_ type: WeatherType) -> Clip? {
        clips.first { $0.name == type.rawValue }
    }

    func unitRects(of clip: Clip, sheetPixelSize: CGSize) -> [CGRect] {
        guard frameWidth > 0, frameHeight > 0 else { return [] }

        let columns = sheetPixelSize.width / CGFloat(frameWidth)
        let rows = sheetPixelSize.height / CGFloat(frameHeight)
        guard columns >= 1, rows >= 1,
              clip.row >= 0, CGFloat(clip.row) < rows,
              clip.frameCount > 0, CGFloat(clip.frameCount) <= columns else { return [] }

        return (0..<clip.frameCount).map { column in
            CGRect(
                x: CGFloat(column) * CGFloat(frameWidth) / sheetPixelSize.width,
                y: CGFloat(clip.row) * CGFloat(frameHeight) / sheetPixelSize.height,
                width: CGFloat(frameWidth) / sheetPixelSize.width,
                height: CGFloat(frameHeight) / sheetPixelSize.height
            )
        }
    }
}

final class WeatherSpriteView: UIView {
    static let animationKey = "weatherSprite"
    private static let sheetName = "weathersSheet"

    private var current: WeatherType?

    init() {
        super.init(frame: .zero)
        layer.magnificationFilter = .nearest
        layer.contentsGravity = .resizeAspect
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(_ type: WeatherType) {
        guard current != type || layer.animation(forKey: Self.animationKey) == nil else { return }

        guard let manifest = WeatherSpriteSheet.manifest,
              let info = manifest.clip(type),
              let sheet = UIImage(named: Self.sheetName)?.cgImage else {
            AppLogger.ui.error("날씨 스프라이트 로드 실패 — clip: \(type.rawValue, privacy: .public)")
            return
        }

        let rects = manifest.unitRects(
            of: info,
            sheetPixelSize: CGSize(width: sheet.width, height: sheet.height)
        )
        guard let firstFrame = rects.first else {
            AppLogger.ui.error("날씨 클립이 시트 격자를 벗어남 — clip: \(type.rawValue, privacy: .public)")
            return
        }

        current = type
        layer.contents = sheet
        layer.contentsRect = firstFrame
        layer.removeAnimation(forKey: Self.animationKey)

        guard rects.count > 1, info.fps > 0 else { return }
        layer.add(makeAnimation(rects: rects, clip: info), forKey: Self.animationKey)
    }

    private func makeAnimation(rects: [CGRect], clip: WeatherSpriteSheet.Clip) -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: "contentsRect")
        animation.values = rects.map { NSValue(cgRect: $0) }
        animation.keyTimes = (0...rects.count).map { NSNumber(value: Double($0) / Double(rects.count)) }
        animation.calculationMode = .discrete
        animation.duration = Double(rects.count) / clip.fps
        animation.repeatCount = clip.loop ? .infinity : 1
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        return animation
    }
}
