import Foundation

/// 구독마다 새 AsyncStream을 만들어 같은 값을 모두에게 보낸다
final class AsyncBroadcaster<Element: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuations: [UUID: AsyncStream<Element>.Continuation] = [:]

    /// current가 있으면 구독 즉시 현재 값을 먼저 보낸다
    /// 읽히지 않은 값은 마지막 하나만 남긴다 — 변경 신호·최신 값 용도라 쌓을 필요가 없다
    func stream(current: (() -> Element)? = nil) -> AsyncStream<Element> {
        let (stream, continuation) = AsyncStream.makeStream(of: Element.self, bufferingPolicy: .bufferingNewest(1))
        let id = UUID()
        continuation.onTermination = { [weak self] _ in
            guard let self else { return }
            self.lock.withLock { _ = self.continuations.removeValue(forKey: id) }
        }
        lock.withLock {
            if let current { continuation.yield(current()) }
            continuations[id] = continuation
        }
        return stream
    }

    func send(_ value: Element) {
        lock.withLock { continuations.values.forEach { $0.yield(value) } }
    }
}
