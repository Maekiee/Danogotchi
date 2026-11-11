import RxSwift

extension Observable {
    /// 구독마다 새 AsyncStream을 받아 메인으로 옮긴다 — AsyncStream은 한 번만 소비할 수 있다
    static func onMain(_ make: @escaping () -> AsyncStream<Element>) -> Observable<Element> {
        deferred { make().asObservable() }.observe(on: MainScheduler.instance)
    }
}
