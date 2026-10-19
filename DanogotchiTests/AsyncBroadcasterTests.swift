import XCTest
@testable import Danogotchi

final class AsyncBroadcasterTests: XCTestCase {
    func test_모든_구독자가_같은_값을_받는다() async {
        let broadcaster = AsyncBroadcaster<Int>()
        var first = broadcaster.stream().makeAsyncIterator()
        var second = broadcaster.stream().makeAsyncIterator()

        broadcaster.send(1)

        let firstValue = await first.next()
        let secondValue = await second.next()
        XCTAssertEqual(firstValue, 1)
        XCTAssertEqual(secondValue, 1)
    }

    func test_current를_주면_구독_직후_현재_값을_먼저_받는다() async {
        let broadcaster = AsyncBroadcaster<Int>()
        var values = broadcaster.stream(current: { 7 }).makeAsyncIterator()

        let initial = await values.next()
        broadcaster.send(8)
        let next = await values.next()

        XCTAssertEqual(initial, 7)
        XCTAssertEqual(next, 8)
    }

    func test_종료한_구독은_값을_받지_않고_나머지는_계속_받는다() async {
        let broadcaster = AsyncBroadcaster<Int>()
        var kept = broadcaster.stream().makeAsyncIterator()
        let dropped = broadcaster.stream()
        let consumer = Task {
            var count = 0
            for await _ in dropped { count += 1 }
            return count
        }
        consumer.cancel()
        let droppedCount = await consumer.value

        broadcaster.send(1)

        let keptValue = await kept.next()
        XCTAssertEqual(droppedCount, 0)
        XCTAssertEqual(keptValue, 1)
    }

    func test_읽지_않은_값은_마지막_하나만_남긴다() async {
        let broadcaster = AsyncBroadcaster<Int>()
        var values = broadcaster.stream().makeAsyncIterator()

        broadcaster.send(1)
        broadcaster.send(2)
        broadcaster.send(3)

        let latest = await values.next()
        XCTAssertEqual(latest, 3)
    }
}
