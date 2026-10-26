import UIKit
import XCTest
@testable import Danogotchi

@MainActor
final class WindowAppearanceApplierTests: XCTestCase {
    func test_applySetsWindowOverrideAndSystemClearsIt() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let applier = WindowAppearanceApplier(window: window)

        applier.apply(.dark)
        XCTAssertEqual(window.overrideUserInterfaceStyle, .dark)

        // 시스템은 오버라이드를 풀어 기기 설정을 따른다
        applier.apply(.system)
        XCTAssertEqual(window.overrideUserInterfaceStyle, .unspecified)
    }
}
