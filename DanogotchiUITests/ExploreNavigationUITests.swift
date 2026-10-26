import XCTest

/// 탐색 화면의 진입 버튼들 — 학습 리포트 열기/닫기, 발음 버튼
@MainActor
final class ExploreNavigationUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func test_studyReportOpensFromExploreAndCloseReturns() {
        let app = XCUIApplication.launchMainFlow()
        app.buttons["explore.studyReport"].tap()
        XCTAssertTrue(app.navigationBars["학습 리포트"].waitForExistence(timeout: 10))
        // 학습 기록이 없는 첫 설치 상태
        XCTAssertTrue(app.staticTexts["첫 학습을 기다리고 있어요"].waitForExistence(timeout: 5))

        app.buttons["학습 리포트 닫기"].tap()
        XCTAssertTrue(app.buttons["explore.library"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars["학습 리포트"].exists)
    }

    func test_speakButtonOnVisibleCardIsTappable() throws {
        let app = XCUIApplication.launchMainFlow()
        let speak = try XCTUnwrap(
            app.buttons.matching(identifier: "explore.speak").allElementsBoundByIndex.first { $0.isHittable }
        )
        XCTAssertEqual(speak.value as? String, "대기")
        speak.tap()
        // 발음 길이는 TTS에 달려 있어 "발음 중" 또는 이미 끝난 "대기" 둘 중 하나다
        XCTAssertTrue(["발음 중", "대기"].contains(speak.value as? String ?? ""), String(describing: speak.value))
    }

    /// 단어 카드는 사진 위 오버레이라 라이트·다크에서 블러 배경이 같아야 한다
    func test_wordCardBlurLooksSameInLightAndDark() throws {
        // 앱 배경은 모드를 따르므로 실제 테마 이미지를 깔아 카드 뒤를 두 모드에서 같게 만든다
        let app = XCUIApplication()
        app.launchArguments = [
            "-uiTestingReset", "-uiTestingMainFlow", "-uiTestingSolidTheme",
            "-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"
        ]
        app.launch()
        XCUIApplication.dismissSystemAlertIfNeeded()
        XCTAssertTrue(app.buttons["explore.library"].waitForExistence(timeout: 10))

        chooseAppearance(["라이트"], in: app)
        let light = try cardBackgroundColor(in: app, name: "light")
        chooseAppearance(["다크"], in: app)
        let dark = try cardBackgroundColor(in: app, name: "dark")

        for (channel, pair) in zip(["red", "green", "blue"], zip(light, dark)) {
            XCTAssertEqual(pair.0, pair.1, accuracy: 0.01, "카드 배경 \(channel) 채널이 라이트·다크에서 다름")
        }
    }

    private func chooseAppearance(_ labels: [String], in app: XCUIApplication) {
        app.buttons["explore.setting"].tap()
        let control = app.segmentedControls["setting.appearanceControl"]
        XCTAssertTrue(control.waitForExistence(timeout: 5))
        labels.forEach { control.buttons[$0].tap() }
        app.buttons["setting.close"].tap()
        XCTAssertTrue(app.buttons["setting.close"].waitForDisappearance())
        XCTAssertTrue(app.buttons["explore.library"].waitForExistence(timeout: 5))
    }

    /// 보이는 카드 윗줄에서 저장·발음 버튼 사이 빈 배경의 평균색(RGB, 0~1)
    private func cardBackgroundColor(in app: XCUIApplication, name: String) throws -> [CGFloat] {
        let speak = try XCTUnwrap(
            app.buttons.matching(identifier: "explore.speak").allElementsBoundByIndex.first { $0.isHittable }
        )
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "card-\(name)"
        add(attachment)

        let image = try XCTUnwrap(screenshot.image.cgImage)
        let scale = CGFloat(image.width) / app.frame.width
        let region = CGRect(x: speak.frame.minX - 110, y: speak.frame.minY, width: 80, height: speak.frame.height)
        let pixelRegion = CGRect(
            x: region.minX * scale, y: region.minY * scale, width: region.width * scale, height: region.height * scale
        ).integral
        let cropped = try XCTUnwrap(image.cropping(to: pixelRegion))

        let width = cropped.width, height = cropped.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        try pixels.withUnsafeMutableBytes { buffer in
            let context = try XCTUnwrap(CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ))
            context.draw(cropped, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        return (0..<3).map { channel in
            let sum = stride(from: channel, to: pixels.count, by: 4).reduce(0) { $0 + Int(pixels[$1]) }
            return CGFloat(sum) / CGFloat(width * height) / 255
        }
    }
}
