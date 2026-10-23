import Foundation

protocol DatabasePreparing {
    /// 저장소 로드·마이그레이션·초기 시드. 멱등이라 재시도해도 안전하다.
    func prepareIfNeeded() throws
}
