import UIKit
import XCTest
@testable import Danogotchi

/// 배경 이미지 처리 전·후 측정용. 픽스처·조건은 Fixtures/ImagePipeline/image-pipeline-fixtures.md
/// 측정 구간: 메모리에 올라온 Data → 화면에 그릴 수 있는 이미지 (네트워크·파일 읽기 제외)
final class ImagePipelineMeasurementTests: XCTestCase {
    /// CDN 픽스처를 받은 화면 크기 — iPhone 17 Pro nativeBounds
    private static let screenPixelSize = CGSize(width: 1206, height: 2622)
    /// 앱과 같은 규칙: MainDIContainer.backgroundMaxPixelSize = Int(screenPixelSize.height)
    private static let maxPixelSize = Int(screenPixelSize.height)
    private static let imageCount = 5

    private var measureOptions: XCTMeasureOptions {
        let options = XCTMeasureOptions()
        options.iterationCount = 10
        return options
    }

    /// 전: 원본(urls.full) JPEG를 UIImage(data:) + preparingForDisplay()로 원본 해상도 강제 디코딩
    func test_before_originalJPEGDecodedAtFullResolution() throws {
        let images = try fixtures(kind: "original", fileExtension: "jpg")
        // 측정 전 확인: 원본 해상도 그대로 디코딩되는지
        let first = try XCTUnwrap(UIImage(data: images[0])?.preparingForDisplay()?.cgImage)
        XCTAssertEqual(first.width * first.height, 4000 * 5600)

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()], options: measureOptions) {
            for data in images {
                // 한 장씩 해제 — 앱은 배경을 한 번에 한 장만 들고 있다
                autoreleasepool {
                    XCTAssertNotNil(UIImage(data: data)?.preparingForDisplay())
                }
            }
        }
    }

    /// 후: CDN 리사이즈 HEIC를 ImageDecoder.decode(data:maxPixelSize:)로 디코딩
    func test_after_cdnHEICDecodedWithImageDecoder() throws {
        let images = try fixtures(kind: "cdn", fileExtension: "heic")
        // 측정 전 확인: 앱이 쓰는 maxPixelSize 이하로 디코딩되는지
        let first = try XCTUnwrap(ImageDecoder.decode(data: images[0], maxPixelSize: Self.maxPixelSize)?.cgImage)
        XCTAssertLessThanOrEqual(max(first.width, first.height), Self.maxPixelSize)

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()], options: measureOptions) {
            for data in images {
                autoreleasepool {
                    XCTAssertNotNil(ImageDecoder.decode(data: data, maxPixelSize: Self.maxPixelSize))
                }
            }
        }
    }

    /// 기준선: 같은 측정을 빈 블록으로 — Memory Peak Physical에 포함된 프로세스 기본 메모리 확인용
    func test_baseline_emptyBlock() {
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()], options: measureOptions) {}
    }

    private func fixtures(kind: String, fileExtension: String) throws -> [Data] {
        try (1...Self.imageCount).map { index in
            let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "pipeline-\(index)-\(kind)",
                                                                 withExtension: fileExtension))
            return try Data(contentsOf: url)
        }
    }
}
