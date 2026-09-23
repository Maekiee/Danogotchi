import ImageIO
import UIKit
import XCTest

/// 픽스처 번들을 찾기 위한 앵커
private final class TestBundleAnchor {}

/// 네 분면이 빨강·초록·파랑·노랑인 320×160 패턴 픽스처
func themeFixtureURL(_ fileExtension: String,
                     file: StaticString = #filePath, line: UInt = #line) throws -> URL {
    try XCTUnwrap(Bundle(for: TestBundleAnchor.self).url(forResource: "theme-pattern", withExtension: fileExtension),
                  file: file, line: line)
}

func storedImage(_ data: Data, file: StaticString = #filePath, line: UInt = #line) throws -> CGImage {
    let source = try XCTUnwrap(CGImageSourceCreateWithData(data as CFData, nil), file: file, line: line)
    return try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil), file: file, line: line)
}

/// CGImage를 RGBA 바이트로 읽는다 — 1×1로 그리면 그 영역의 평균색이다
func rgbaPixels(of image: CGImage, width: Int = 1, height: Int = 1,
                file: StaticString = #filePath, line: UInt = #line) throws -> [UInt8] {
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    try pixels.withUnsafeMutableBytes { buffer in
        let context = try XCTUnwrap(CGContext(
            data: buffer.baseAddress, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        ), file: file, line: line)
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    }
    return pixels
}

func averageColor(_ image: CGImage) throws -> [Bool] {
    try rgbaPixels(of: image).prefix(3).map { $0 > 128 }
}

/// 정규화 좌표 한 점의 색을 확인한다
func assertPixel(_ image: CGImage, x: CGFloat, y: CGFloat, rgb: [Double],
                 file: StaticString = #filePath, line: UInt = #line) throws {
    let sample = try XCTUnwrap(image.cropping(to: CGRect(x: floor(CGFloat(image.width) * x),
                                                        y: floor(CGFloat(image.height) * y), width: 1, height: 1)),
                               file: file, line: line)
    let pixel = try rgbaPixels(of: sample, file: file, line: line)
    for channel in 0..<3 {
        XCTAssertEqual(Double(pixel[channel]), rgb[channel], accuracy: 20, file: file, line: line)
    }
    XCTAssertEqual(pixel[3], 255, file: file, line: line)
}

// 크기뿐 아니라 실제로 그린 색상도 확인해 검은 이미지가 성공으로 처리되지 않게 한다.
func assertPatternPixels(_ image: CGImage, file: StaticString = #filePath, line: UInt = #line) throws {
    let width = image.width
    let height = image.height
    let pixels = try rgbaPixels(of: image, width: width, height: height, file: file, line: line)

    var colors = Set<[Bool]>()
    for y in [height / 4, height * 3 / 4] {
        for x in [width / 4, width * 3 / 4] {
            let offset = (y * width + x) * 4
            colors.insert((0..<3).map { pixels[offset + $0] > 128 })
            XCTAssertEqual(pixels[offset + 3], 255, file: file, line: line)
        }
    }
    XCTAssertEqual(colors, Set([[true, false, false], [false, true, false],
                                [false, false, true], [true, true, false]]), file: file, line: line)
}
