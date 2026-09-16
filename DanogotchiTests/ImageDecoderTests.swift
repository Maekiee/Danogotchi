import ImageIO
import UIKit
import XCTest
@testable import Danogotchi

final class ImageDecoderTests: XCTestCase {
    func test_heicIsValidatedAndDownsampledToPixelLimit() throws {
        try assertFixtureDecodes(fileExtension: "heic")
    }

    func test_webpIsValidatedAndDownsampledToPixelLimit() throws {
        try assertFixtureDecodes(fileExtension: "webp")
    }

    func test_imageSmallerThanPixelLimitIsNotUpscaled() throws {
        let image = try XCTUnwrap(ImageDecoder.decode(fileURL: fixtureURL("webp"), maxPixelSize: 640)?.cgImage)
        XCTAssertEqual(image.width, 320)
        XCTAssertEqual(image.height, 160)
        try assertPatternPixels(image)
    }

    func test_decodingUsesActualBytesDespiteWrongFileExtension() throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
        defer { try? FileManager.default.removeItem(at: file) }
        let data = try Data(contentsOf: fixtureURL("heic"))
        try data.write(to: file)
        XCTAssertEqual(ImageDecoder.validate(data), "heic")
        let image = try XCTUnwrap(ImageDecoder.decode(fileURL: file, maxPixelSize: 80)?.cgImage)
        XCTAssertEqual(image.width, 80)
        XCTAssertEqual(image.height, 40)
        try assertPatternPixels(image)
    }

    func test_truncatedImagePayloadsAreRejected() throws {
        for fileExtension in ["heic", "webp"] {
            let data = try Data(contentsOf: fixtureURL(fileExtension))
            XCTAssertNil(ImageDecoder.validate(Data(data.prefix(32))), fileExtension)
        }
    }

    func test_missingOrInvalidFileCannotBeDecoded() throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".heic")
        defer { try? FileManager.default.removeItem(at: file) }
        XCTAssertNil(ImageDecoder.decode(fileURL: file, maxPixelSize: 80))
        try Data("invalid image".utf8).write(to: file)
        XCTAssertNil(ImageDecoder.decode(fileURL: file, maxPixelSize: 80))
    }

    func test_dataOverloadDownsamplesTheSameBytesWithoutAFile() throws {
        for fileExtension in ["heic", "webp"] {
            let data = try Data(contentsOf: fixtureURL(fileExtension))
            let image = try XCTUnwrap(ImageDecoder.decode(data: data, maxPixelSize: 80)?.cgImage, fileExtension)
            XCTAssertEqual(image.width, 80, fileExtension)
            XCTAssertEqual(image.height, 40, fileExtension)
            try assertPatternPixels(image)
        }
        XCTAssertNil(ImageDecoder.decode(data: Data("invalid image".utf8), maxPixelSize: 80))
        XCTAssertNil(ImageDecoder.decode(data: Data(), maxPixelSize: 80))
    }

    private func fixtureURL(_ fileExtension: String) throws -> URL {
        try XCTUnwrap(Bundle(for: Self.self).url(forResource: "theme-pattern", withExtension: fileExtension))
    }

    private func assertFixtureDecodes(fileExtension: String) throws {
        let file = try fixtureURL(fileExtension)
        let data = try Data(contentsOf: file)
        XCTAssertEqual(ImageDecoder.validate(data), fileExtension)
        let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil))
        let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        XCTAssertEqual(properties[kCGImagePropertyPixelWidth] as? Int, 320)
        XCTAssertEqual(properties[kCGImagePropertyPixelHeight] as? Int, 160)

        let image = try XCTUnwrap(ImageDecoder.decode(fileURL: file, maxPixelSize: 80)?.cgImage)
        XCTAssertEqual(image.width, 80)
        XCTAssertEqual(image.height, 40)
        try assertPatternPixels(image)
        XCTAssertEqual(try Data(contentsOf: file), data, "Downsampling must not rewrite the stored image")
    }

    // 크기뿐 아니라 실제로 그린 색상도 확인해 검은 이미지가 성공으로 처리되지 않게 한다.
    private func assertPatternPixels(_ image: CGImage) throws {
        let width = image.width
        let height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        try pixels.withUnsafeMutableBytes { buffer in
            let context = try XCTUnwrap(CGContext(
                data: buffer.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
            ))
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        var colors = Set<[Bool]>()
        for y in [height / 4, height * 3 / 4] {
            for x in [width / 4, width * 3 / 4] {
                let offset = (y * width + x) * 4
                colors.insert((0..<3).map { pixels[offset + $0] > 128 })
                XCTAssertEqual(pixels[offset + 3], 255)
            }
        }
        XCTAssertEqual(colors, Set([[true, false, false], [false, true, false],
                                    [false, false, true], [true, true, false]]))
    }
}
