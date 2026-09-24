import ComposableArchitecture
import XCTest
@testable import Danogotchi

@MainActor
final class StudyReportFeatureTests: XCTestCase {
    func test_closeButtonTappedCallsOnClose() async {
        let closedCount = LockIsolated(0)
        let store = TestStore(initialState: StudyReportFeature.State()) {
            StudyReportFeature(onClose: { closedCount.withValue { $0 += 1 } })
        }

        await store.send(.closeButtonTapped)

        XCTAssertEqual(closedCount.value, 1)
    }
}
