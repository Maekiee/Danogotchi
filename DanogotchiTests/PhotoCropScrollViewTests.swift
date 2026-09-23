import UIKit
import XCTest
@testable import Danogotchi

@MainActor
final class PhotoCropScrollViewTests: XCTestCase {
    func test_initialCenterCropZoomAndMovementMatchImageCoordinates() throws {
        let view = try makeView()
        assertCrop(try XCTUnwrap(view.cropRect), CGRect(x: 0.375, y: 0, width: 0.25, height: 1))
        XCTAssertEqual(view.minimumZoomScale, 0.0625, accuracy: 0.0001)
        XCTAssertEqual(view.maximumZoomScale, 4, accuracy: 0.0001)
        XCTAssertEqual(view.backgroundColor, .black)
        XCTAssertFalse(view.bounces)
        XCTAssertFalse(view.bouncesZoom)

        view.setZoomScale(2, animated: false)
        view.setContentOffset(CGPoint(x: 400, y: 160), animated: false)
        assertCrop(try XCTUnwrap(view.cropRect), CGRect(x: 0.625, y: 0.5, width: 0.125, height: 0.5))
    }

    func test_sameImageAndLayoutPreserveSelectionButNewImageResetsIt() throws {
        let view = try makeView()
        let image = try fixtureImage()
        view.setImage(image)
        view.layoutIfNeeded()
        view.accessibilityIncrement()
        XCTAssertTrue(view.accessibilityScroll(.up))
        XCTAssertTrue(view.accessibilityScroll(.left))
        let crop = try XCTUnwrap(view.cropRect)
        view.setImage(image)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        assertCrop(try XCTUnwrap(view.cropRect), crop)

        view.frame.size = CGSize(width: 160, height: 320)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        assertCrop(try XCTUnwrap(view.cropRect), crop)

        view.setImage(try fixtureImage())
        view.layoutIfNeeded()
        assertCrop(try XCTUnwrap(view.cropRect), CGRect(x: 0.375, y: 0, width: 0.25, height: 1))
    }

    func test_initialImageCanMoveInEveryDirectionWithoutSnappingBack() throws {
        let view = try makeView()
        let initial = try XCTUnwrap(view.cropRect)
        for offset in [CGPoint(x: 80, y: 0), CGPoint(x: 160, y: 0),
                       CGPoint(x: 120, y: -40), CGPoint(x: 120, y: 40)] {
            view.setContentOffset(offset, animated: false)
            let moved = try XCTUnwrap(view.cropRect)
            XCTAssertNotEqual(moved, initial)
            view.setNeedsLayout()
            view.layoutIfNeeded()
            assertCrop(try XCTUnwrap(view.cropRect), moved)
            XCTAssertEqual(view.zoomScale, 1)
        }
    }

    func test_accessibilityZoomAndMovementUseFullCanvasRange() throws {
        let view = try makeView()
        for _ in 0..<20 { view.accessibilityIncrement() }
        XCTAssertEqual(view.zoomScale, view.maximumZoomScale, accuracy: 0.0001)
        for _ in 0..<30 { view.accessibilityDecrement() }
        XCTAssertEqual(view.zoomScale, view.minimumZoomScale, accuracy: 0.0001)
        // 최소 배율에선 contentOffset 1픽셀(1/3pt)이 이미지 폭의 1/60이라 원점만 느슨하게 본다
        assertCrop(try XCTUnwrap(view.cropRect), CGRect(x: -1.5, y: -7.5, width: 4, height: 16),
                   originAccuracy: 0.1)
        for direction in [UIAccessibilityScrollDirection.left, .right, .up, .down] {
            let before = try XCTUnwrap(view.cropRect)
            XCTAssertTrue(view.accessibilityScroll(direction))
            XCTAssertNotEqual(view.cropRect, before)
            for _ in 0..<200 { XCTAssertTrue(view.accessibilityScroll(direction)) }
            let crop = try XCTUnwrap(view.cropRect)
            switch direction {
            case .left: XCTAssertEqual(crop.maxX, 0, accuracy: 0.0001)
            case .right: XCTAssertEqual(crop.minX, 1, accuracy: 0.0001)
            case .up: XCTAssertEqual(crop.maxY, 0, accuracy: 0.0001)
            case .down: XCTAssertEqual(crop.minY, 1, accuracy: 0.0001)
            default: XCTFail("Unexpected direction")
            }
        }
    }

    func test_resizingPreservesSelectionCenterAndZoomRelativeToFill() throws {
        let view = try makeView()
        view.accessibilityIncrement()
        view.setContentOffset(CGPoint(x: 40, y: -40), animated: false)
        let before = try XCTUnwrap(view.cropRect)
        view.frame.size = CGSize(width: 160, height: 80)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        let after = try XCTUnwrap(view.cropRect)
        XCTAssertEqual(after.midX, before.midX, accuracy: 0.0001)
        XCTAssertEqual(after.midY, before.midY, accuracy: 0.0001)
        XCTAssertEqual(view.zoomScale, 0.5 * 1.25, accuracy: 0.0001)
    }

    func test_disabledEditingAlsoBlocksAccessibilityActions() throws {
        let view = try makeView()
        let before = try XCTUnwrap(view.cropRect)
        view.isUserInteractionEnabled = false
        view.accessibilityIncrement()
        view.accessibilityDecrement()
        XCTAssertFalse(view.accessibilityScroll(.up))
        XCTAssertFalse(view.isScrollEnabled)
        assertCrop(try XCTUnwrap(view.cropRect), before)
        view.isUserInteractionEnabled = true
        XCTAssertTrue(view.isScrollEnabled)
        XCTAssertTrue(view.accessibilityScroll(.up))
        XCTAssertNotEqual(view.cropRect, before)
    }

    func test_selectedPreviewRegionIsTheRegionEncodedForStorage() throws {
        let view = try makeView()
        view.setZoomScale(2, animated: false)
        view.setContentOffset(CGPoint(x: 400, y: 160), animated: false)
        let result = try ThemeImageRenderer.render(data: Data(contentsOf: themeFixtureURL("heic")),
                                                   crop: XCTUnwrap(PhotoThemeCrop(XCTUnwrap(view.cropRect))),
                                                   targetPixelSize: CGSize(width: 80, height: 160))
        let image = try XCTUnwrap(UIImage(data: result.data)?.cgImage)
        XCTAssertEqual(image.width, 40)
        XCTAssertEqual(image.height, 80)
        let pixel = try rgbaPixels(of: image)
        XCTAssertEqual(pixel.prefix(3).map { $0 > 128 }, [true, true, false])
    }

    func test_smallMovedPreviewMatchesSavedPatternAndBlackMargins() throws {
        let view = try makeView()
        view.setZoomScale(0.125, animated: false)
        view.setContentOffset(CGPoint(x: -10, y: -40), animated: false)
        let crop = try XCTUnwrap(view.cropRect)
        assertCrop(crop, CGRect(x: -0.25, y: -2, width: 2, height: 8))
        let result = try ThemeImageRenderer.render(data: Data(contentsOf: themeFixtureURL("heic")),
                                                   crop: XCTUnwrap(PhotoThemeCrop(crop)),
                                                   targetPixelSize: CGSize(width: 80, height: 160))
        let saved = try XCTUnwrap(UIImage(data: result.data)?.cgImage)
        XCTAssertEqual(saved.width, 80)
        XCTAssertEqual(saved.height, 160)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        // CALayer.render(in:)은 레이어 bounds 원점(contentOffset)을 적용하지 않는다
        let preview = try XCTUnwrap(UIGraphicsImageRenderer(size: view.bounds.size, format: format).image { context in
            context.cgContext.translateBy(x: -view.contentOffset.x, y: -view.contentOffset.y)
            view.layer.render(in: context.cgContext)
        }.cgImage)
        let points = [CGPoint(x: 20, y: 45), CGPoint(x: 40, y: 45),
                      CGPoint(x: 20, y: 55), CGPoint(x: 40, y: 55),
                      CGPoint(x: 5, y: 50), CGPoint(x: 60, y: 50),
                      CGPoint(x: 30, y: 20), CGPoint(x: 30, y: 100)]
        for point in points {
            var colors: [[UInt8]] = []
            for image in [preview, saved] {
                let pixelImage = try XCTUnwrap(image.cropping(to: CGRect(origin: point, size: CGSize(width: 1, height: 1))))
                colors.append(try rgbaPixels(of: pixelImage))
            }
            for channel in 0..<4 {
                XCTAssertEqual(Double(colors[0][channel]), Double(colors[1][channel]), accuracy: 20, "\(point)")
            }
        }
    }

    private func makeView() throws -> PhotoCropScrollView {
        let view = PhotoCropScrollView(frame: CGRect(x: 0, y: 0, width: 80, height: 160))
        view.setImage(try fixtureImage())
        view.layoutIfNeeded()
        return view
    }

    private func fixtureImage() throws -> UIImage {
        try XCTUnwrap(ImageDecoder.decode(fileURL: themeFixtureURL("heic"), maxPixelSize: 320))
    }

    private func assertCrop(_ actual: CGRect, _ expected: CGRect, originAccuracy: CGFloat = 0.0001,
                            file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(actual.minX, expected.minX, accuracy: originAccuracy, file: file, line: line)
        XCTAssertEqual(actual.minY, expected.minY, accuracy: originAccuracy, file: file, line: line)
        XCTAssertEqual(actual.width, expected.width, accuracy: 0.0001, file: file, line: line)
        XCTAssertEqual(actual.height, expected.height, accuracy: 0.0001, file: file, line: line)
    }
}
