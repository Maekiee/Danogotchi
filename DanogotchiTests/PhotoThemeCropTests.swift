import CoreGraphics
import XCTest
@testable import Danogotchi

final class PhotoThemeCropTests: XCTestCase {
    func test_areaOverlappingTheSourceIsAccepted() {
        // 여백을 포함해 원본 밖으로 나간 구도도 사진이 보이면 저장할 수 있다
        for rect in [CGRect(x: 0, y: 0, width: 1, height: 1),
                     CGRect(x: 0.25, y: 0.1, width: 0.5, height: 0.8),
                     CGRect(x: -0.5, y: -0.25, width: 2, height: 1.5),
                     CGRect(x: 0.5, y: 0.5, width: 1, height: 1)] {
            XCTAssertEqual(PhotoThemeCrop(rect)?.rect, rect, "\(rect)")
        }
    }

    func test_emptyDetachedOrNonFiniteAreaIsRejected() {
        for rect in [CGRect.zero,
                     CGRect(x: -1, y: 0, width: 1, height: 1),
                     CGRect(x: 1, y: 0, width: 0.5, height: 1),
                     CGRect(x: 0, y: -1, width: 1, height: 1),
                     CGRect(x: 0, y: 1, width: 1, height: 1),
                     CGRect(x: 0, y: 0, width: -1, height: 1),
                     CGRect(x: 0, y: 0, width: 1, height: -1),
                     CGRect(x: CGFloat.nan, y: 0, width: 1, height: 1),
                     CGRect(x: 0, y: CGFloat.nan, width: 1, height: 1),
                     CGRect(x: 0, y: 0, width: CGFloat.infinity, height: 1)] {
            XCTAssertNil(PhotoThemeCrop(rect), "\(rect)")
        }
    }
}
