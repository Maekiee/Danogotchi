import ImageIO
import UIKit
import XCTest
@testable import Danogotchi

final class ThemeImageRendererTests: XCTestCase {
    private let fullCrop = CGRect(x: 0, y: 0, width: 1, height: 1)

    func test_renderedImageHasDownsampledPixelsAndMatchingFormat() throws {
        let data = try Data(contentsOf: themeFixtureURL("heic"))
        let result = try render(data, crop: fullCrop, target: CGSize(width: 80, height: 40))
        XCTAssertTrue(["heic", "jpg"].contains(result.fileExtension))
        XCTAssertEqual(ImageDecoder.validate(result.data), result.fileExtension)
        let image = try storedImage(result.data)
        XCTAssertEqual(image.width, 80)
        XCTAssertEqual(image.height, 40)
        try assertPatternPixels(image)
    }

    func test_renderedImageDoesNotUpscaleSmallImages() throws {
        let data = try Data(contentsOf: themeFixtureURL("heic"))
        let result = try render(data, crop: fullCrop, target: CGSize(width: 640, height: 320))
        let image = try storedImage(result.data)
        XCTAssertEqual(image.width, 320)
        XCTAssertEqual(image.height, 160)
        try assertPatternPixels(image)
    }

    func test_renderedImageAppliesOrientationWithoutRotatingTwice() throws {
        let image = try XCTUnwrap(ImageDecoder.decode(fileURL: themeFixtureURL("heic"), maxPixelSize: 320)?.cgImage)
        let data = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(data, "public.jpeg" as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, [kCGImagePropertyOrientation: 6] as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(destination))

        let result = try render(data as Data, crop: fullCrop, target: CGSize(width: 40, height: 80))
        let stored = try storedImage(result.data)
        XCTAssertEqual(stored.width, 40)
        XCTAssertEqual(stored.height, 80)
        let displayed = try XCTUnwrap(ImageDecoder.decode(data: result.data, maxPixelSize: 80)?.cgImage)
        XCTAssertEqual(displayed.width, 40)
        XCTAssertEqual(displayed.height, 80)
        try assertPatternPixels(stored)
    }

    func test_renderedImageCompositesTransparencyOnOpaqueBlack() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let data = UIGraphicsImageRenderer(size: CGSize(width: 160, height: 80), format: format).pngData { context in
            UIColor.red.withAlphaComponent(0.5).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 160, height: 80))
        }
        let result = try render(data, crop: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5), target: CGSize(width: 80, height: 40))
        XCTAssertTrue(["heic", "jpg"].contains(result.fileExtension))
        XCTAssertEqual(ImageDecoder.validate(result.data), result.fileExtension)
        let image = try storedImage(result.data)
        XCTAssertEqual(image.width, 80)
        XCTAssertEqual(image.height, 40)
        let pixel = try rgbaPixels(of: image)
        XCTAssertEqual(Double(pixel[0]), 128, accuracy: 15)
        XCTAssertLessThan(pixel[1], 15)
        XCTAssertLessThan(pixel[2], 15)
        XCTAssertEqual(pixel[3], 255)
    }

    func test_renderedImageRejectsInvalidInput() {
        XCTAssertThrowsError(try render(Data("invalid".utf8), crop: fullCrop, target: CGSize(width: 80, height: 40))) {
            XCTAssertEqual($0 as? PhotoThemeError, .unsupportedFormat)
        }
    }

    func test_selectedCropUsesOrientedCoordinatesForAllEXIFOrientations() throws {
        let image = try XCTUnwrap(ImageDecoder.decode(fileURL: themeFixtureURL("heic"), maxPixelSize: 320)?.cgImage)
        let expectedColors = [[true, false, false], [false, true, false], [true, true, false], [false, false, true],
                              [true, false, false], [false, false, true], [true, true, false], [false, true, false]]
        for orientation in 1...8 {
            let data = NSMutableData()
            let destination = try XCTUnwrap(CGImageDestinationCreateWithData(data, "public.jpeg" as CFString, 1, nil))
            CGImageDestinationAddImage(destination, image, [kCGImagePropertyOrientation: orientation] as CFDictionary)
            XCTAssertTrue(CGImageDestinationFinalize(destination))
            let target = orientation >= 5 ? CGSize(width: 40, height: 80) : CGSize(width: 80, height: 40)
            for crop in [CGRect(x: 0, y: 0, width: 0.5, height: 0.5),
                         CGRect(x: -0.5, y: -0.5, width: 1, height: 1)] {
                let result = try render(data as Data, crop: crop, target: target)
                let stored = try storedImage(result.data)
                XCTAssertEqual(stored.width, Int(target.width), "orientation: \(orientation)")
                XCTAssertEqual(stored.height, Int(target.height), "orientation: \(orientation)")
                if crop.minX < 0 {
                    try assertPixel(stored, x: 0.25, y: 0.25, rgb: [0, 0, 0])
                    let quadrant = try XCTUnwrap(stored.cropping(to: CGRect(
                        x: target.width * 0.625, y: target.height * 0.625,
                        width: target.width * 0.25, height: target.height * 0.25
                    )))
                    XCTAssertEqual(try averageColor(quadrant), expectedColors[orientation - 1], "orientation: \(orientation)")
                } else {
                    XCTAssertEqual(try averageColor(stored), expectedColors[orientation - 1], "orientation: \(orientation)")
                }
            }
        }
    }

    func test_centerCropKeepsCenterPatternAndZoomedCropDoesNotUpscale() throws {
        let data = try Data(contentsOf: themeFixtureURL("heic"))
        let center = try render(data, crop: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5), target: CGSize(width: 80, height: 40))
        try assertPatternPixels(storedImage(center.data))

        let zoomed = try render(data, crop: CGRect(x: 0.75, y: 0.5, width: 0.125, height: 0.5), target: CGSize(width: 200, height: 400))
        let image = try storedImage(zoomed.data)
        XCTAssertEqual(image.width, 40)
        XCTAssertEqual(image.height, 80)
        XCTAssertEqual(try averageColor(image), [true, true, false])
    }

    func test_zoomedOutCanvasPreservesAllFourBlackMarginsAndPatternPlacement() throws {
        let data = try Data(contentsOf: themeFixtureURL("heic"))
        let result = try render(data, crop: CGRect(x: -0.5, y: -0.5, width: 2, height: 2), target: CGSize(width: 160, height: 80))
        let image = try storedImage(result.data)
        XCTAssertEqual(image.width, 160)
        XCTAssertEqual(image.height, 80)
        for point in [CGPoint(x: 0.125, y: 0.5), CGPoint(x: 0.875, y: 0.5),
                      CGPoint(x: 0.5, y: 0.125), CGPoint(x: 0.5, y: 0.875)] {
            try assertPixel(image, x: point.x, y: point.y, rgb: [0, 0, 0])
        }
        try assertPixel(image, x: 0.375, y: 0.375, rgb: [240, 32, 32])
        try assertPixel(image, x: 0.625, y: 0.375, rgb: [32, 240, 32])
        try assertPixel(image, x: 0.375, y: 0.625, rgb: [32, 32, 240])
        try assertPixel(image, x: 0.625, y: 0.625, rgb: [240, 240, 32])
    }

    func test_insufficientSourcePixelsShrinkEntireCanvasWithoutChangingPlacement() throws {
        let data = try Data(contentsOf: themeFixtureURL("heic"))
        let result = try render(data, crop: CGRect(x: -0.5, y: -0.5, width: 2, height: 2), target: CGSize(width: 1280, height: 640))
        let image = try storedImage(result.data)
        XCTAssertEqual(image.width, 640)
        XCTAssertEqual(image.height, 320)
        try assertPixel(image, x: 0.125, y: 0.5, rgb: [0, 0, 0])
        try assertPixel(image, x: 0.375, y: 0.375, rgb: [240, 32, 32])
        try assertPixel(image, x: 0.625, y: 0.625, rgb: [240, 240, 32])
    }

    func test_photoOutsideCanvasIsClippedAndRemainingSpaceIsBlack() throws {
        let data = try Data(contentsOf: themeFixtureURL("heic"))
        let result = try render(data, crop: CGRect(x: 0.5, y: 0.5, width: 1, height: 1), target: CGSize(width: 160, height: 80))
        let image = try storedImage(result.data)
        try assertPixel(image, x: 0.25, y: 0.25, rgb: [240, 240, 32])
        try assertPixel(image, x: 0.75, y: 0.25, rgb: [0, 0, 0])
        try assertPixel(image, x: 0.25, y: 0.75, rgb: [0, 0, 0])
    }

    func test_areaTooLargeToFormACanvasIsRejected() throws {
        let data = try Data(contentsOf: themeFixtureURL("heic"))
        let unbounded = CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        XCTAssertThrowsError(try render(data, crop: unbounded, target: CGSize(width: 80, height: 40))) {
            XCTAssertEqual($0 as? PhotoThemeError, .invalidCrop)
        }
    }

    /// 저장할 수 없는 영역은 PhotoThemeCrop이 막으므로 테스트도 같은 문을 지난다
    private func render(_ data: Data, crop: CGRect, target: CGSize) throws -> (data: Data, fileExtension: String) {
        try ThemeImageRenderer.render(data: data, crop: XCTUnwrap(PhotoThemeCrop(crop)), targetPixelSize: target)
    }
}
