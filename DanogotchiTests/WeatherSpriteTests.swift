import XCTest
@testable import Danogotchi


/// 매니페스트(`weather.json`)와 시트 에셋이 어긋나면 화면에 빈 칸이 조용히 렌더된다.
/// 실제로 한 번 어긋나 있었다 — 그 불일치를 테스트에서 잡는 게 이 파일의 목적이다.
final class WeatherSpriteTests: XCTestCase {

    private func loadManifest() throws -> WeatherSpriteSheet {
        try XCTUnwrap(WeatherSpriteSheet.manifest, "weather.json을 번들에서 읽지 못했다")
    }

    private func loadSheet() throws -> CGImage {
        try XCTUnwrap(UIImage(named: "weathersSheet")?.cgImage, "weathersSheet 로드 실패")
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

    func test_모든_날씨_프레임은_격자_안에_여백을_두고_본체가_정렬된다() throws {
        let manifest = try loadManifest()
        let sheet = try loadSheet()
        let pixels = try RGBAImage(sheet)

        XCTAssertEqual(sheet.width, manifest.frameWidth * 8)
        XCTAssertEqual(sheet.height, manifest.frameHeight * 7)

        for row in 0..<7 {
            let frames = (0..<8).map { column in
                CGRect(
                    x: CGFloat(column * manifest.frameWidth),
                    y: CGFloat(row * manifest.frameHeight),
                    width: CGFloat(manifest.frameWidth),
                    height: CGFloat(manifest.frameHeight)
                )
            }
            let reference = try XCTUnwrap(pixels.bodyFeature(in: frames[0], row: row))

            for (column, frame) in frames.enumerated() {
                let bounds = try XCTUnwrap(pixels.alphaBounds(in: frame))
                XCTAssertGreaterThanOrEqual(bounds.minX - frame.minX, 2, "row \(row), column \(column): 왼쪽 여백")
                XCTAssertGreaterThanOrEqual(bounds.minY - frame.minY, 2, "row \(row), column \(column): 위쪽 여백")
                XCTAssertGreaterThanOrEqual(frame.maxX - bounds.maxX, 2, "row \(row), column \(column): 오른쪽 여백")
                XCTAssertGreaterThanOrEqual(frame.maxY - bounds.maxY, 2, "row \(row), column \(column): 아래쪽 여백")

                let candidate = try XCTUnwrap(pixels.bodyFeature(in: frame, row: row))
                let alignment = bestAlignmentOffset(reference: reference, candidate: candidate)
                XCTAssertGreaterThan(alignment.score, 0.8, "row \(row), column \(column): 본체 상관도")
                XCTAssertLessThanOrEqual(abs(alignment.dx), 1, "row \(row), column \(column): 가로 지터")
                XCTAssertLessThanOrEqual(abs(alignment.dy), 1, "row \(row), column \(column): 세로 지터")
            }
        }
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

private struct RGBAImage {
    private enum PixelError: Error {
        case contextCreationFailed
    }

    let width: Int
    let height: Int
    private let pixels: [UInt8]

    init(_ image: CGImage) throws {
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let rendered = pixels.withUnsafeMutableBytes { buffer in
            guard let address = buffer.baseAddress,
                  let context = CGContext(
                    data: address,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: width * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue
                        | CGImageAlphaInfo.premultipliedLast.rawValue
                  ) else { return false }

            context.draw(
                image,
                in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
            )
            return true
        }
        guard rendered else { throw PixelError.contextCreationFailed }

        self.width = width
        self.height = height
        self.pixels = pixels
    }

    func alphaBounds(in rect: CGRect, alphaGreaterThan threshold: UInt8 = 0) -> CGRect? {
        var minimumX = Int(rect.maxX)
        var minimumY = Int(rect.maxY)
        var maximumX = Int(rect.minX) - 1
        var maximumY = Int(rect.minY) - 1

        for y in Int(rect.minY)..<Int(rect.maxY) {
            for x in Int(rect.minX)..<Int(rect.maxX) where alpha(x: x, y: y) > threshold {
                minimumX = min(minimumX, x)
                minimumY = min(minimumY, y)
                maximumX = max(maximumX, x)
                maximumY = max(maximumY, y)
            }
        }
        guard maximumX >= minimumX, maximumY >= minimumY else { return nil }
        return CGRect(
            x: minimumX,
            y: minimumY,
            width: maximumX - minimumX + 1,
            height: maximumY - minimumY + 1
        )
    }

    func bodyFeature(in rect: CGRect, row: Int) -> [Double]? {
        guard let bounds = alphaBounds(in: rect, alphaGreaterThan: 16) else { return nil }
        let frameWidth = Int(rect.width)
        let frameHeight = Int(rect.height)
        let bodyBottom = row <= 3
            ? Int(bounds.minY + (bounds.height * 0.65).rounded())
            : Int(rect.maxY)
        var result = [Double](repeating: 0, count: frameWidth * frameHeight)

        for localY in 0..<frameHeight {
            let y = Int(rect.minY) + localY
            guard y < bodyBottom else { continue }
            for localX in 0..<frameWidth {
                let x = Int(rect.minX) + localX
                guard alpha(x: x, y: y) > 16 else { continue }
                let offset = pixelOffset(x: x, y: y)
                result[localY * frameWidth + localX] =
                    Double(pixels[offset]) * 0.2126
                    + Double(pixels[offset + 1]) * 0.7152
                    + Double(pixels[offset + 2]) * 0.0722
            }
        }
        return result
    }

    private func pixelOffset(x: Int, y: Int) -> Int {
        (y * width + x) * 4
    }

    private func alpha(x: Int, y: Int) -> UInt8 {
        pixels[pixelOffset(x: x, y: y) + 3]
    }
}

private func bestAlignmentOffset(
    reference: [Double],
    candidate: [Double],
    frameSize: Int = 216
) -> (dx: Int, dy: Int, score: Double) {
    let referenceNorm = sqrt(reference.reduce(0) { $0 + $1 * $1 })
    let candidateNorm = sqrt(candidate.reduce(0) { $0 + $1 * $1 })
    var best = (dx: 0, dy: 0, score: -Double.infinity)

    for dy in -2...2 {
        for dx in -2...2 {
            var product = 0.0
            for y in 0..<frameSize {
                let candidateY = y - dy
                guard candidateY >= 0, candidateY < frameSize else { continue }
                for x in 0..<frameSize {
                    let candidateX = x - dx
                    guard candidateX >= 0, candidateX < frameSize else { continue }
                    product += reference[y * frameSize + x]
                        * candidate[candidateY * frameSize + candidateX]
                }
            }
            let score = product / (referenceNorm * candidateNorm)
            let currentDistance = abs(dx) + abs(dy)
            let bestDistance = abs(best.dx) + abs(best.dy)
            if score > best.score || (score == best.score && currentDistance < bestDistance) {
                best = (dx, dy, score)
            }
        }
    }
    return best
}
