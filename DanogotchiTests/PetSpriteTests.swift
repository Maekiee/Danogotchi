import XCTest
@testable import Danogotchi


/// 매니페스트(`pet.json`)와 시트 에셋이 어긋나면 화면에 빈 칸이 조용히 렌더된다.
/// 그 불일치를 테스트에서 잡는 게 이 파일의 목적이다.
final class PetSpriteTests: XCTestCase {

    private func loadManifest() throws -> PetSpriteSheet {
        try XCTUnwrap(PetSpriteSheet.manifest, "pet.json을 번들에서 읽지 못했다")
    }

    func test_매니페스트가_번들에서_디코드된다() throws {
        let manifest = try loadManifest()

        XCTAssertGreaterThan(manifest.frameWidth, 0)
        XCTAssertGreaterThan(manifest.frameHeight, 0)
        XCTAssertFalse(manifest.clips.isEmpty)
    }

    func test_쓰는_클립은_모든_레벨의_시트_격자_안에_들어간다() throws {
        let manifest = try loadManifest()

        for clip in PetSpriteClip.allCases {
            let clipInfo = try XCTUnwrap(manifest.clip(clip), "\(clip.rawValue)가 매니페스트에 없다")

            for level in 0...PetLevelPolicy.maxLevel {
                let name = PetType.sprout.sheetName(level: level)
                let sheet = try XCTUnwrap(UIImage(named: name)?.cgImage, "\(name) 로드 실패")

                let rects = manifest.unitRects(
                    of: clipInfo,
                    sheetPixelSize: CGSize(width: sheet.width, height: sheet.height)
                )

                // 격자를 벗어나면 unitRects가 빈 배열을 준다 — 프레임 수가 그대로 나와야 정상이다
                XCTAssertEqual(rects.count, clipInfo.frameCount, "\(name) / \(clip.rawValue) 프레임 수 불일치")
            }
        }
    }

    func test_유닛_사각형은_한_행을_가로로_훑는다() throws {
        let manifest = try loadManifest()
        let clipInfo = try XCTUnwrap(manifest.clip(.idle))
        // 격자 크기는 아트가 쥔다 — 실제 시트에서 읽어야 시트가 바뀔 때 이 테스트까지 깨지지 않는다
        let sheet = try XCTUnwrap(UIImage(named: PetType.sprout.sheetName(level: 0))?.cgImage)
        let rects = manifest.unitRects(
            of: clipInfo,
            sheetPixelSize: CGSize(width: sheet.width, height: sheet.height)
        )

        XCTAssertEqual(rects.count, clipInfo.frameCount)
        // 같은 클립은 같은 행에 머문다
        XCTAssertEqual(Set(rects.map { $0.minY }).count, 1)

        // 프레임 폭만큼 오른쪽으로 한 칸씩 나아간다
        let width = CGFloat(manifest.frameWidth) / CGFloat(sheet.width)
        for (index, rect) in rects.enumerated() {
            XCTAssertEqual(rect.width, width, accuracy: .ulpOfOne)
            XCTAssertEqual(rect.minX, CGFloat(index) * width, accuracy: .ulpOfOne)
        }
    }

    func test_매니페스트가_시트_격자를_벗어나면_아무_프레임도_주지_않는다() throws {
        let manifest = try loadManifest()
        let clipInfo = try XCTUnwrap(manifest.clip(.sick))

        // 시트가 한 칸짜리인데 클립이 row 2를 가리키는 상황
        let rects = manifest.unitRects(
            of: clipInfo,
            sheetPixelSize: CGSize(width: manifest.frameWidth, height: manifest.frameHeight)
        )

        XCTAssertTrue(rects.isEmpty)
    }

    func test_애니메이션은_프레임을_칸_단위로_끊어_무한_반복한다() throws {
        let manifest = try loadManifest()
        let idle = try XCTUnwrap(manifest.clip(.idle))
        let name = PetType.sprout.sheetName(level: 0)
        let sheet = try XCTUnwrap(UIImage(named: name)?.cgImage)
        // 재생 길이는 시트 칸 수가 아니라 playbackOrder가 늘려놓은 순서를 따른다
        let playback = idle.playbackOrder(of: manifest.unitRects(
            of: idle,
            sheetPixelSize: CGSize(width: sheet.width, height: sheet.height)
        ))

        let view = PetSpriteView()
        view.render(sheetName: name, clip: .idle)

        let animation = try XCTUnwrap(
            view.layer.animation(forKey: PetSpriteView.animationKey) as? CAKeyframeAnimation
        )

        XCTAssertEqual(animation.keyPath, "contentsRect")
        // 보간되면 칸이 스르륵 밀린다 — 이 한 줄이 프레임을 튀게 만든다
        XCTAssertEqual(animation.calculationMode, .discrete)
        XCTAssertEqual(animation.values?.count, playback.count)
        // discrete는 값 n개에 keyTimes n+1개를 요구한다
        XCTAssertEqual(animation.keyTimes?.count, playback.count + 1)
        XCTAssertEqual(animation.duration, Double(playback.count) / idle.fps, accuracy: .ulpOfOne)
        XCTAssertEqual(animation.repeatCount, .infinity)
    }

    func test_쉬는_자세를_여러_번_돌린_뒤_꼬리를_한_번_붙인다() throws {
        let manifest = try loadManifest()
        let idle = try XCTUnwrap(manifest.clip(.idle))
        let rest = try XCTUnwrap(idle.restFrames, "idle에 쉬는 구간이 없다")
        let cycle = try XCTUnwrap(idle.cycleSeconds, "idle에 목표 주기가 없다")

        let sheet = try XCTUnwrap(UIImage(named: PetType.sprout.sheetName(level: 0))?.cgImage)
        let frames = manifest.unitRects(
            of: idle,
            sheetPixelSize: CGSize(width: sheet.width, height: sheet.height)
        )
        let playback = idle.playbackOrder(of: frames)

        // 꼬리는 정확히 한 번, 맨 뒤에만 붙는다 — 깜박임이 두 번 돌면 여기서 깨진다
        let tail = Array(frames.suffix(from: rest))
        XCTAssertEqual(Array(playback.suffix(tail.count)), tail)

        let head = playback.dropLast(tail.count)
        XCTAssertEqual(head.count % rest, 0)
        for (index, rect) in head.enumerated() {
            XCTAssertEqual(rect, frames[index % rest], "쉬는 루프 \(index)번째 칸이 어긋났다")
        }

        // 주기는 쉬는 루프 한 바퀴(rest/fps) 단위로만 떨어지므로 목표에 정확히 맞을 수 없다.
        // 그 한 바퀴보다 더 벗어났다면 반올림이 잘못된 것이다.
        let duration = Double(playback.count) / idle.fps
        XCTAssertEqual(duration, cycle, accuracy: Double(rest) / idle.fps)
    }

    func test_쉬는_구간이_없는_클립은_전_프레임을_그대로_돌린다() throws {
        let manifest = try loadManifest()
        let sleep = try XCTUnwrap(manifest.clip(.sleep))
        let sheet = try XCTUnwrap(UIImage(named: PetType.sprout.sheetName(level: 0))?.cgImage)
        let frames = manifest.unitRects(
            of: sleep,
            sheetPixelSize: CGSize(width: sheet.width, height: sheet.height)
        )

        XCTAssertNil(sleep.restFrames)
        XCTAssertEqual(sleep.playbackOrder(of: frames), frames)
    }

    func test_정지_렌더는_지정한_칸만_세우고_애니메이션을_붙이지_않는다() throws {
        let manifest = try loadManifest()
        let idle = try XCTUnwrap(manifest.clip(.idle))
        let name = PetType.sprout.sheetName(level: 0)
        let sheet = try XCTUnwrap(UIImage(named: name)?.cgImage)
        let rects = manifest.unitRects(
            of: idle,
            sheetPixelSize: CGSize(width: sheet.width, height: sheet.height)
        )
        // 알 선택 화면이 2번째 칸을 쓴다
        XCTAssertGreaterThan(rects.count, 1)

        let view = PetSpriteView()
        view.renderStill(sheetName: name, clip: .idle, frameIndex: 1)

        XCTAssertEqual(view.layer.contentsRect, rects[1])
        XCTAssertNil(view.layer.animation(forKey: PetSpriteView.animationKey))
    }

    func test_같은_상태로_다시_렌더하면_애니메이션을_재시작하지_않는다() {
        let view = PetSpriteView()
        let sheetName = PetType.sprout.sheetName(level: 0)

        view.render(sheetName: sheetName, clip: .idle)
        let first = view.layer.animation(forKey: PetSpriteView.animationKey)
        view.render(sheetName: sheetName, clip: .idle)

        // 돌보기 탭마다 render가 불린다 — 매번 새로 붙이면 클립이 처음으로 튄다
        XCTAssertTrue(first === view.layer.animation(forKey: PetSpriteView.animationKey))
    }

    func test_클립이_바뀌면_애니메이션을_갈아끼운다() {
        let view = PetSpriteView()
        let sheetName = PetType.sprout.sheetName(level: 0)

        view.render(sheetName: sheetName, clip: .idle)
        let idleAnimation = view.layer.animation(forKey: PetSpriteView.animationKey)
        view.render(sheetName: sheetName, clip: .sick)

        XCTAssertFalse(idleAnimation === view.layer.animation(forKey: PetSpriteView.animationKey))
    }

    func test_사망하면_기분과_무관하게_sleep을_재생한다() {
        for mood in PetMood.allCases {
            XCTAssertEqual(PetSpriteClip(mood: mood, isDead: true), .sleep, mood.rawValue)
        }
    }

    func test_기분_아홉_종류가_클립_네_종류로_접힌다() {
        let expected: [PetMood: PetSpriteClip] = [
            .happy: .idle,
            .satisfied: .idle,
            .refreshed: .idle,
            .hungry: .sad,
            .thirsty: .sad,
            .bored: .sad,
            .unpleasant: .sad,
            .sad: .sad,
            .depressed: .sick,
        ]

        // 기분이 늘어나면 이 표도 같이 늘어나야 한다
        XCTAssertEqual(expected.count, PetMood.allCases.count)

        for mood in PetMood.allCases {
            XCTAssertEqual(PetSpriteClip(mood: mood, isDead: false), expected[mood], mood.rawValue)
        }
    }

    /// 깜박임은 `idle` 시퀀스에 접혀 있고 `happy` 행은 아직 없다 — 아트 없이 케이스가 늘면 빈 칸이 렌더된다
    func test_아트가_없는_클립은_케이스로_두지_않는다() {
        XCTAssertNil(PetSpriteClip(rawValue: "blink"))
        XCTAssertNil(PetSpriteClip(rawValue: "happy"))
    }
}
