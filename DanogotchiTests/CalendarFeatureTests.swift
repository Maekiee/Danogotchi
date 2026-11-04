import ComposableArchitecture
import XCTest
@testable import Danogotchi

@MainActor
final class CalendarFeatureTests: XCTestCase {
    func test_historyButtonNavigatesToHistory() async {
        let destinations = LockIsolated<[StudyReportDestination]>([])
        let store = TestStore(initialState: CalendarFeature.State()) {
            CalendarFeature(onClose: {}, onNavigate: { route in destinations.withValue { $0.append(route) } })
        }

        await store.send(.historyButtonTapped)
        await store.finish()

        XCTAssertEqual(destinations.value, [.history])
    }

    func test_closeButtonCallsOnCloseWithoutNavigating() async {
        let closeCount = LockIsolated(0)
        let destinations = LockIsolated<[StudyReportDestination]>([])
        let store = TestStore(initialState: CalendarFeature.State()) {
            CalendarFeature(onClose: { closeCount.withValue { $0 += 1 } },
                            onNavigate: { route in destinations.withValue { $0.append(route) } })
        }

        await store.send(.closeButtonTapped)
        await store.finish()

        XCTAssertEqual(closeCount.value, 1)
        XCTAssertTrue(destinations.value.isEmpty)
    }
}
