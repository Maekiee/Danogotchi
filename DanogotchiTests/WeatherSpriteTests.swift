import XCTest
@testable import Danogotchi


/// 매니페스트(`weather.json`)와 시트 에셋이 어긋나면 화면에 빈 칸이 조용히 렌더된다.
/// 실제로 한 번 어긋나 있었다 — 그 불일치를 테스트에서 잡는 게 이 파일의 목적이다.
final class WeatherSpriteTests: XCTestCase {

    private func loadManifest() throws -> WeatherSpriteSheet {
        try XCTUnwrap(WeatherSpriteSheet.manifest, "weather.json을 번들에서 읽지 못했다")
    }

    private func loadSheet() throws -> CGImage {
        try XCTUnwrap(UIImage(named: "weatherBackgroundSheet")?.cgImage, "weatherBackgroundSheet 로드 실패")
    }

    func test_날씨_일곱_종류가_모두_시트_격자_안에_들어간다() throws {
        let manifest = try loadManifest()
        let sheet = try loadSheet()
        let size = CGSize(width: sheet.width, height: sheet.height)

        for type in WeatherType.allCases {
            let clip = try XCTUnwrap(manifest.clip(type), "\(type.rawValue)가 매니페스트에 없다")

            // 격자를 벗어나면 unitRects가 빈 배열을 준다 — 프레임 수가 그대로 나와야 정상이다
            XCTAssertEqual(
                manifest.unitRects(of: clip, sheetPixelSize: size).count,
                clip.frameCount,
                "\(type.rawValue) 프레임 수 불일치"
            )
        }
    }

    func test_유닛_사각형은_선언된_프레임_크기를_사용한다() throws {
        let manifest = try loadManifest()
        let clip = WeatherSpriteSheet.Clip(
            name: "test",
            row: 1,
            frameCount: 2,
            fps: 1,
            loop: false
        )
        let sheet = try loadSheet()
        let rects = manifest.unitRects(
            of: clip,
            sheetPixelSize: CGSize(width: sheet.width, height: sheet.height)
        )

        XCTAssertEqual(rects.count, clip.frameCount)
        // 같은 클립은 같은 행에 머문다
        XCTAssertEqual(Set(rects.map { $0.minY }).count, 1)

        let width = CGFloat(manifest.frameWidth) / CGFloat(sheet.width)
        let height = CGFloat(manifest.frameHeight) / CGFloat(sheet.height)
        for (index, rect) in rects.enumerated() {
            XCTAssertEqual(rect.width, width, accuracy: .ulpOfOne)
            XCTAssertEqual(rect.minX, CGFloat(index) * width, accuracy: .ulpOfOne)
            XCTAssertEqual(rect.height, height, accuracy: .ulpOfOne)
            XCTAssertEqual(rect.minY, height, accuracy: .ulpOfOne)
        }
        XCTAssertEqual(
            try XCTUnwrap(rects.last).maxX,
            CGFloat(clip.frameCount) * width,
            accuracy: .ulpOfOne
        )
    }

    func test_배경은_1200x800_프레임_4열_7행으로_빈틈없이_채워진다() throws {
        let manifest = try loadManifest()
        let sheet = try loadSheet()
        XCTAssertEqual(manifest.frameWidth, 1200)
        XCTAssertEqual(manifest.frameHeight, 800)
        XCTAssertEqual(sheet.width, 4800)
        XCTAssertEqual(sheet.height, 5600)

        let types: [WeatherType] = [
            .thunderstorm, .drizzle, .rain, .snow, .atmosphere, .clear, .clouds
        ]
        for (row, type) in types.enumerated() {
            let clip = try XCTUnwrap(manifest.clip(type))
            XCTAssertEqual(clip.row, row)
            XCTAssertEqual(clip.frameCount, 4)
            XCTAssertEqual(clip.fps, 4)
            XCTAssertTrue(clip.loop)
            let rects = manifest.unitRects(
                of: clip,
                sheetPixelSize: CGSize(width: sheet.width, height: sheet.height)
            )
            XCTAssertEqual(rects.count, 4)
            for (column, rect) in rects.enumerated() {
                XCTAssertEqual(rect.minX, Double(column) / 4, accuracy: 0.000001)
                XCTAssertEqual(rect.minY, Double(row) / 7, accuracy: 0.000001)
                XCTAssertEqual(rect.width, 0.25, accuracy: 0.000001)
                XCTAssertEqual(rect.height, 1.0 / 7.0, accuracy: 0.000001)
                XCTAssertLessThanOrEqual(rect.maxX, 1.0 + 0.000001)
                XCTAssertLessThanOrEqual(rect.maxY, 1.0 + 0.000001)
            }
        }

        let context = try XCTUnwrap(CGContext(
            data: nil, width: sheet.width, height: sheet.height,
            bitsPerComponent: 8, bytesPerRow: sheet.width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue
                | CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.draw(sheet, in: CGRect(x: 0, y: 0, width: sheet.width, height: sheet.height))
        let pixels = try XCTUnwrap(context.data).assumingMemoryBound(to: UInt8.self)
        let hasTransparency = stride(from: 3, to: sheet.width * sheet.height * 4, by: 4)
            .contains { pixels[$0] != 255 }
        XCTAssertFalse(hasTransparency, "배경에 투명한 픽셀이 있다")
    }

    func test_매니페스트가_시트_격자를_벗어나면_아무_프레임도_주지_않는다() throws {
        let manifest = try loadManifest()
        let clip = try XCTUnwrap(manifest.clip(.clouds))

        // 시트가 한 칸짜리인데 클립이 row 6을 가리키는 상황
        let rects = manifest.unitRects(
            of: clip,
            sheetPixelSize: CGSize(width: manifest.frameWidth, height: manifest.frameHeight)
        )

        XCTAssertTrue(rects.isEmpty)
    }

    func test_애니메이션은_프레임을_칸_단위로_끊어_무한_반복한다() throws {
        let manifest = try loadManifest()
        let clip = try XCTUnwrap(manifest.clip(.rain))

        let view = WeatherSpriteView()
        view.render(.rain)

        let animation = try XCTUnwrap(
            view.layer.animation(forKey: WeatherSpriteView.animationKey) as? CAKeyframeAnimation
        )

        XCTAssertEqual(view.layer.contentsGravity, .resize)
        XCTAssertEqual(animation.duration, 1, accuracy: .ulpOfOne)
        XCTAssertEqual(animation.keyPath, "contentsRect")
        // 보간되면 칸이 스르륵 밀린다 — 이 한 줄이 프레임을 튀게 만든다
        XCTAssertEqual(animation.calculationMode, .discrete)
        XCTAssertEqual(animation.values?.count, clip.frameCount)
        // discrete는 값 n개에 keyTimes n+1개를 요구한다
        XCTAssertEqual(animation.keyTimes?.count, clip.frameCount + 1)
        XCTAssertEqual(animation.duration, Double(clip.frameCount) / clip.fps, accuracy: .ulpOfOne)
        XCTAssertEqual(animation.repeatCount, .infinity)
    }

    func test_같은_날씨로_다시_렌더하면_애니메이션을_재시작하지_않는다() {
        let view = WeatherSpriteView()

        view.render(.snow)
        let first = view.layer.animation(forKey: WeatherSpriteView.animationKey)
        view.render(.snow)

        // 화면 재진입마다 날씨를 다시 받는다 — 매번 새로 붙이면 클립이 처음으로 튄다
        XCTAssertTrue(first === view.layer.animation(forKey: WeatherSpriteView.animationKey))
    }

    func test_날씨가_바뀌면_애니메이션을_갈아끼운다() {
        let view = WeatherSpriteView()

        view.render(.snow)
        let snow = view.layer.animation(forKey: WeatherSpriteView.animationKey)
        view.render(.clear)

        XCTAssertFalse(snow === view.layer.animation(forKey: WeatherSpriteView.animationKey))
    }

    func test_매니페스트_클립_이름이_날씨_케이스와_일대일이다() throws {
        let manifest = try loadManifest()

        // 아트 행이 없는 케이스가 늘면 빈 칸이 렌더된다
        XCTAssertEqual(
            Set(manifest.clips.map { $0.name }),
            Set(WeatherType.allCases.map { $0.rawValue })
        )
        XCTAssertEqual(Set(manifest.clips.map { $0.row }).count, manifest.clips.count)
    }
}
