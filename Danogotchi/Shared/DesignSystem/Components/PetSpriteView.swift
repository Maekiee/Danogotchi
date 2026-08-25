import UIKit
import OSLog


struct PetSpriteSheet: Decodable {

    struct Clip: Decodable {
        let name: String
        let row: Int
        let frameCount: Int
        let fps: Double
        let loop: Bool
        let restFrames: Int?
        let cycleSeconds: Double?

        func playbackOrder(of frames: [CGRect]) -> [CGRect] {
            guard let rest = restFrames, rest > 0, rest < frames.count,
                  let cycle = cycleSeconds, cycle > 0, fps > 0 else { return frames }

            let tail = frames.count - rest
            let repeats = max(1, Int(((cycle * fps - Double(tail)) / Double(rest)).rounded()))
            return (0..<repeats).flatMap { _ in frames.prefix(rest) } + frames.suffix(tail)
        }
    }

    let frameWidth: Int
    let frameHeight: Int
    let clips: [Clip]

    static let manifest: PetSpriteSheet? = {
        guard let url = Bundle.main.url(forResource: "pet", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(PetSpriteSheet.self, from: data)
    }()

    func clip(_ clip: PetSpriteClip) -> Clip? {
        clips.first { $0.name == clip.rawValue }
    }

    func unitRects(of clip: Clip, sheetPixelSize: CGSize) -> [CGRect] {
        guard frameWidth > 0, frameHeight > 0 else { return [] }

        let columns = sheetPixelSize.width / CGFloat(frameWidth)
        let rows = sheetPixelSize.height / CGFloat(frameHeight)
        guard columns >= 1, rows >= 1,
              clip.row >= 0, CGFloat(clip.row) < rows,
              clip.frameCount > 0, CGFloat(clip.frameCount) <= columns else { return [] }

        return (0..<clip.frameCount).map { column in
            CGRect(x: CGFloat(column) / columns,
                   y: CGFloat(clip.row) / rows,
                   width: 1 / columns,
                   height: 1 / rows)
        }
    }
}

enum PetSpriteClip: String, CaseIterable {
    case idle
    case sad
    case sleep
    case sick

    init(mood: PetMood, isDead: Bool) {
        guard !isDead else {
            self = .sleep
            return
        }

        switch mood {
        case .happy, .satisfied, .refreshed:
            self = .idle
        case .hungry, .thirsty, .bored, .unpleasant, .sad:
            self = .sad
        case .depressed:
            self = .sick
        }
    }
}

final class PetSpriteView: UIView {
    static let animationKey = "petSprite"

    private var current: (sheetName: String, clip: PetSpriteClip)?

    init() {
        super.init(frame: .zero)

        // 시트에 @2x/@3x가 없어 128px 프레임을 그대로 늘린다 — 보간하면 픽셀 아트가 뭉갠다
        layer.magnificationFilter = .nearest
        // 프레임은 정사각이지만 뷰는 스택 폭을 채워 정사각이 아니다
        layer.contentsGravity = .resizeAspect
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(sheetName: String, clip: PetSpriteClip) {
        // 백그라운드에 다녀오면 CoreAnimation이 애니메이션을 떼어간다 — 상태가 같아도 다시 붙인다
        let isSameState = current?.sheetName == sheetName && current?.clip == clip
        guard !isSameState || layer.animation(forKey: Self.animationKey) == nil else { return }

        guard let frames = frames(sheetName: sheetName, clip: clip),
              let firstFrame = frames.rects.first else { return }

        current = (sheetName, clip)
        show(sheet: frames.sheet, rect: firstFrame)

        guard frames.rects.count > 1, frames.info.fps > 0 else { return }
        layer.add(
            makeAnimation(rects: frames.info.playbackOrder(of: frames.rects), clip: frames.info),
            forKey: Self.animationKey
        )
    }
    
    // 애니메이션 없는 정적 이미지
    func renderStill(sheetName: String, clip: PetSpriteClip, frameIndex: Int) {
        guard let frames = frames(sheetName: sheetName, clip: clip),
              frames.rects.indices.contains(frameIndex) else { return }

        show(sheet: frames.sheet, rect: frames.rects[frameIndex])
    }

    /// 시트와 클립을 유닛 사각형 목록으로 바꾼다. 실패 로그는 여기 한 곳에 모은다.
    private func frames(
        sheetName: String,
        clip: PetSpriteClip
    ) -> (sheet: CGImage, rects: [CGRect], info: PetSpriteSheet.Clip)? {
        guard let manifest = PetSpriteSheet.manifest,
              let info = manifest.clip(clip),
              let sheet = UIImage(named: sheetName)?.cgImage else {
            // 아무것도 그리지 않는다. 유닛 사각형 없이 contents만 넣으면 시트 전체가 격자로 보인다.
            AppLogger.ui.error(
                "스프라이트 로드 실패 — sheet: \(sheetName, privacy: .public), clip: \(clip.rawValue, privacy: .public)"
            )
            return nil
        }

        let rects = manifest.unitRects(
            of: info,
            sheetPixelSize: CGSize(width: sheet.width, height: sheet.height)
        )
        guard !rects.isEmpty else {
            AppLogger.ui.error("클립이 시트 격자를 벗어남 — clip: \(clip.rawValue, privacy: .public)")
            return nil
        }
        return (sheet, rects, info)
    }

    private func show(sheet: CGImage, rect: CGRect) {
        layer.contents = sheet
        layer.contentsRect = rect
        layer.removeAnimation(forKey: Self.animationKey)
    }

    private func makeAnimation(rects: [CGRect], clip: PetSpriteSheet.Clip) -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: "contentsRect")
        // CGRect는 객체가 아니라 NSValue로 감싸야 KVC가 받는다
        animation.values = rects.map { NSValue(cgRect: $0) }
        // `.discrete`는 값 n개에 keyTimes n+1개를 요구한다(첫 값 0.0, 마지막 1.0) —
        // 안 주면 마지막 프레임이 자기 몫의 시간을 못 받는다
        animation.keyTimes = (0...rects.count).map { NSNumber(value: Double($0) / Double(rects.count)) }
        // 이 한 줄이 빠지면 칸이 보간돼 프레임이 스르륵 밀린다
        animation.calculationMode = .discrete
        animation.duration = Double(rects.count) / clip.fps
        animation.repeatCount = clip.loop ? .infinity : 1
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        return animation
    }
}
