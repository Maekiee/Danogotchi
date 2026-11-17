import Foundation

/// Crashlytics custom key 값. 값의 종류가 적도록 구간·단계로 묶는다
enum CrashContext {
    static func vocabCountBucket(_ count: Int) -> String {
        switch count {
        case ..<1: return "0"
        case 1...50: return "1-50"
        case 51...200: return "51-200"
        default: return "201+"
        }
    }

    /// 저장된 펫은 마지막 정산 시점 값이라 지금 기준으로 정산해 본다 — 저장하지 않는다
    static func petStage(_ pet: Pet?, now: Date) -> String {
        guard let pet else { return "none" }
        let settled = PetStatePolicy.settle(pet, now: now)
        return settled.isDead ? "dead" : String(settled.level)
    }
}
