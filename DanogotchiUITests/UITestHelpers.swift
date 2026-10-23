import XCTest

/// 새 UI 테스트들이 공유하는 실행·조회 도우미. 기존 파일의 private 헬퍼는 그대로 둔다
extension XCUIApplication {
    /// 첫 설치 상태로 실행한다. 시스템 버튼 문구(취소·닫기)를 한국어로 고정
    static func launchFresh(seed: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        var arguments = ["-uiTestingReset", "-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        if let seed { arguments.insert(seed, at: 1) }
        app.launchArguments = arguments
        app.launch()
        dismissSystemAlertIfNeeded()
        return app
    }

    /// 온보딩을 건너뛰고 여행 단어장을 학습 중인 탐색 화면으로 실행한다
    static func launchMainFlow() -> XCUIApplication {
        let app = launchFresh(seed: "-uiTestingMainFlow")
        XCTAssertTrue(app.buttons["explore.library"].waitForExistence(timeout: 10))
        return app
    }

    /// 셀·커스텀 뷰처럼 요소 타입을 못 박기 어려운 식별자를 찾는다
    func element(_ identifier: String) -> XCUIElement {
        descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// 알림·위치 권한 알럿은 시뮬레이터에 한 번 결정되면 다시 묻지 않는다 — 있으면 거절한다
    static func dismissSystemAlertIfNeeded(timeout: TimeInterval = 3) {
        let alert = XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.firstMatch
        guard alert.waitForExistence(timeout: timeout) else { return }
        let deny = alert.buttons.matching(
            NSPredicate(format: "label IN %@", ["허용 안 함", "Don't Allow", "Don’t Allow"])
        ).firstMatch
        if deny.exists {
            deny.tap()
        } else {
            // 첫 버튼이 "허용 안 함"인 알림 권한 알럿
            alert.buttons.element(boundBy: 0).tap()
        }
    }

    /// 오프라인이면 테마 검색 실패 알림이 뜬다 — 흐름과 무관하므로 닫는다
    func dismissNetworkAlertIfNeeded() {
        let alert = alerts["알림"]
        if alert.waitForExistence(timeout: 2) {
            alert.buttons["확인"].tap()
        }
    }

    func scroll(to element: XCUIElement, maxSwipes: Int = 10) {
        for _ in 0..<maxSwipes where !element.isHittable {
            swipeUp()
        }
        XCTAssertTrue(element.isHittable, "스크롤로 도달하지 못함: \(element)")
    }
}

extension XCUIElement {
    func waitForDisappearance(timeout: TimeInterval = 5) -> Bool {
        wait(NSPredicate(format: "exists == false"), timeout: timeout)
    }

    func waitForValue(_ value: String, timeout: TimeInterval = 5) -> Bool {
        wait(NSPredicate(format: "value == %@", value), timeout: timeout)
    }

    func waitForLabel(_ label: String, timeout: TimeInterval = 5) -> Bool {
        wait(NSPredicate(format: "label == %@", label), timeout: timeout)
    }

    func waitForEnabled(_ enabled: Bool, timeout: TimeInterval = 5) -> Bool {
        wait(NSPredicate(format: "isEnabled == %@", NSNumber(value: enabled)), timeout: timeout)
    }

    private func wait(_ predicate: NSPredicate, timeout: TimeInterval) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
