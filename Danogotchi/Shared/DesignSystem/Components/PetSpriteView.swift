import UIKit
import OSLog


/// `pet.json` — 프레임 크기와 클립 목록. 시트 8장이 같은 격자를 쓰므로 매니페스트 한 장으로 전부 커버된다.
struct PetSpriteSheet: Decodable {

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

    /// ponytail: 번들 루트가 플랫이라 `pet.json`도 전역 이름이다.
    /// 펫이 2종 이상 되면 폴더 참조로 옮기고 펫별 경로를 받게 바꾼다.
    static let manifest: PetSpriteSheet? = {
        guard let url = Bundle.main.url(forResource: "pet", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(PetSpriteSheet.self, from: data)
    }()

    func clip(_ clip: PetSpriteClip) -> Clip? {
        clips.first { $0.name == clip.rawValue }
    }

    /// 시트 픽셀 크기를 프레임 크기로 나눠 격자 칸 수를 얻는다 — 열·행 수를 코드에 박지 않는다.
    /// 결과는 `contentsRect`가 쓰는 유닛 좌표(`0...1`)다.
    func unitRects(of clip: Clip, sheetPixelSize: CGSize) -> [CGRect] {
        guard frameWidth > 0, frameHeight > 0 else { return [] }

        let columns = sheetPixelSize.width / CGFloat(frameWidth)
        let rows = sheetPixelSize.height / CGFloat(frameHeight)
        // 매니페스트가 시트보다 큰 격자를 가리키면 빈 칸을 렌더하게 된다 — 그리지 않는다
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


/// 재생할 클립. rawValue는 `pet.json`의 `name`과 일치해야 한다.
///
/// 시트는 이 4행이 전부다 — 눈 깜박임은 별도 클립이 아니라 `idle` 시퀀스 안에 접혀 있고,
/// 돌보기 성공 리액션(`happy`) 행은 아직 없다.
enum PetSpriteClip: String, CaseIterable {
    case idle
    case sad
    case sleep
    case sick

    /// 기분 9종과 사망 여부를 클립 4종으로 접는다. 대응이 1:1이 아니므로 여기서 한 번만 정한다.
    /// `switch`가 망라적이라 `PetMood`에 케이스가 늘면 컴파일이 깨진다.
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


/// 스프라이트 시트 한 장에서 프레임 한 칸만 잘라 보여주고, 그 칸을 프레임 단위로 옮겨 애니메이션한다.
///
/// `contentsRect`는 보간되는 속성이라 그냥 애니메이션하면 칸이 스르륵 밀린다 —
/// `CAKeyframeAnimation`의 `.discrete`가 값을 붙잡아 칸 단위로 튀게 만든다.
/// CoreAnimation이 렌더 스레드에서 돌리므로 타이머·`CADisplayLink`도, 그걸 멈출 코드도 없다.
final class PetSpriteView: UIView {

    static let animationKey = "petSprite"

    /// 마지막으로 반영한 상태. 같으면 다시 시작하지 않는다 —
    /// `render`는 돌보기 탭마다 불리므로 매번 새로 붙이면 클립이 처음으로 튄다.
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
        layer.add(makeAnimation(rects: frames.rects, clip: frames.info), forKey: Self.animationKey)
    }

    /// 애니메이션 없이 한 칸만 세워둔다 — 알 선택 화면은 정지 이미지를 쓴다.
    /// `current`는 건드리지 않는다 — 애니메이션 재시작 방지 전용이고 정지 뷰는 `render`를 부르지 않는다.
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
