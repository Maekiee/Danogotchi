import Foundation


enum PetCareResult {
    case success(Pet)
    /// 대상 수치가 이미 100 — 정산 결과는 저장해야 하므로 Pet을 함께 돌려준다
    case alreadyFull(Pet)
    /// 정산 결과 사망 — 요청한 돌보기는 적용하지 않지만 정산 결과는 저장한다
    case dead(Pet)
}


enum PetReviveResult {
    case success(Pet)
    /// 살아 있어 부활할 수 없다 — 정산 결과만 저장한다
    case alive(Pet)
}


/// 저장된 수치와 `stateUpdatedAt` 하나로 시간 경과를 정산하고 기분·부활을 판정한다.
/// 백그라운드 작업이나 상시 타이머 없이 화면 조회·포그라운드 복귀·돌보기·레벨업 시점에만 호출된다.
/// 밸런스 상수는 조정할 때 열 파일이 하나로 유지되도록 전부 여기 모은다.
enum PetStatePolicy {

    static let maxStat: Double = 100
    static let maxHP: Double = 40
    static let careRecovery: Double = 25

    /// 이 값 이하로 내려간 수치 하나당 HP가 깎인다
    static let dangerThreshold: Double = 20
    /// 네 수치가 전부 이 값을 넘을 때만 HP가 회복된다
    static let healthyThreshold: Double = 65
    static let hpRecoveryPerHour: Double = 0.5
    static let hpDamagePerDangerStatPerHour: Double = 0.25

    /// 기분 판정 임계값
    static let depressedThreshold: Double = 45
    static let happyThreshold: Double = 80
    static let refreshedThreshold: Double = 95

    /// 부활 시 돌봄 수치를 여기까지 끌어올린다. HP가 변하지 않는 구간이라 돌볼 여유가 생긴다.
    static let reviveFloor: Double = 50
    /// 부활 시 현재 레벨 요구 경험치의 이 비율을 차감한다
    static let revivePenaltyRate = 0.1

    static func hourlyDecay(_ stat: PetCareStat) -> Double {
        switch stat {
        case .satiety:
            return 0.8
        case .hydration:
            return 1.0
        case .fun:
            return 0.6
        case .cleanliness:
            return 0.4
        }
    }
}


// MARK: - 정산

extension PetStatePolicy {

    /// 모든 액션이 가장 먼저 부르는 정산 진입점. 돌봄 수치와 HP를 같은 경과 구간으로 한 번에 처리한다.
    static func settle(_ pet: Pet, now: Date) -> Pet {
        var settled = pet
        settled.stateUpdatedAt = now

        let elapsedHours = now.timeIntervalSince(pet.stateUpdatedAt) / 3600
        // 기기 시각을 미래로 옮겼다 원복한 경우. 타임스탬프만 현재로 재동기화한다 —
        // 되돌리지 않으면 그 미래 시점까지 상태가 완전히 얼어붙는다.
        guard elapsedHours > 0 else { return settled }

        // 사망 후에는 자동 회복하지 않는다. 부활만 HP를 복구한다.
        if !pet.isDead {
            settled.hp = settledHP(pet, elapsedHours: elapsedHours)
        }
        for stat in PetCareStat.allCases {
            settled[keyPath: stat.keyPath] = decayed(pet, stat, elapsedHours)
        }
        return settled
    }

    private static func decayed(_ pet: Pet, _ stat: PetCareStat, _ hours: Double) -> Double {
        max(0, pet[keyPath: stat.keyPath] - hours * hourlyDecay(stat))
    }

    /// 각 수치가 임계값을 통과한 시각으로 구간을 쪼개 회복·정지·감소를 시간순으로 적용한다.
    /// 조회 시점의 최종 수치 하나로 전체 경과시간을 소급 계산하면 회복 구간이 감소로 뒤집힌다.
    private static func settledHP(_ pet: Pet, elapsedHours: Double) -> Double {
        var hp = pet.hp
        let points = boundaries(pet, elapsedHours: elapsedHours)

        for (start, end) in zip(points, points.dropFirst()) {
            // 구간 안에서는 어떤 수치도 임계값을 넘지 않으므로 중간값으로 변화율을 정할 수 있다
            let rate = hpChangePerHour(pet, at: (start + end) / 2)
            // 구간마다 제한한다. 전체 회복량과 피해량을 상계한 뒤 마지막에 한 번만 자르면
            // 상한에 막혀 버려질 회복분이 피해를 상쇄해 버린다.
            hp = min(maxHP, max(0, hp + rate * (end - start)))
            if hp <= 0 { return 0 }
        }
        return hp
    }

    /// 정산 구간의 경계 — 시작·끝과 각 수치가 `healthyThreshold`·`dangerThreshold`를 통과한 시각
    private static func boundaries(_ pet: Pet, elapsedHours: Double) -> [Double] {
        var points: Set<Double> = [0, elapsedHours]
        for stat in PetCareStat.allCases {
            let saved = pet[keyPath: stat.keyPath]
            for threshold in [healthyThreshold, dangerThreshold] where saved > threshold {
                let crossed = (saved - threshold) / hourlyDecay(stat)
                if crossed > 0, crossed < elapsedHours { points.insert(crossed) }
            }
        }
        return points.sorted()
    }

    private static func hpChangePerHour(_ pet: Pet, at hours: Double) -> Double {
        let values = PetCareStat.allCases.map { decayed(pet, $0, hours) }
        let dangerCount = values.filter { $0 <= dangerThreshold }.count

        if dangerCount > 0 {
            return -hpDamagePerDangerStatPerHour * Double(dangerCount)
        }
        if values.allSatisfy({ $0 > healthyThreshold }) {
            return hpRecoveryPerHour
        }
        return 0
    }
}


// MARK: - 기분

extension PetStatePolicy {

    /// 정산된 수치에서 매번 계산한다. 판정 순서가 곧 우선순위라 재배열하면 결과가 달라진다.
    /// 사망 여부와 위험 상태는 반영하지 않는다 — 사망 UI와 위험 표시가 따로 알린다.
    static func mood(_ pet: Pet) -> PetMood {
        let values = PetCareStat.allCases.map { (stat: $0, value: pet[keyPath: $0.keyPath]) }
        let low = values.filter { $0.value <= healthyThreshold }

        if values.filter({ $0.value <= depressedThreshold }).count >= 2 { return .depressed }
        if low.count >= 2 { return .sad }
        if low.count == 1 {
            switch low[0].stat {
            case .satiety:
                return .hungry
            case .hydration:
                return .thirsty
            case .fun:
                return .bored
            case .cleanliness:
                return .unpleasant
            }
        }
        if values.allSatisfy({ $0.value >= happyThreshold }) { return .happy }
        // 위 규칙이 이미 네 수치 모두 healthyThreshold 초과를 보장하므로 나머지 수치의 하한은 두지 않는다
        if pet.cleanliness >= refreshedThreshold { return .refreshed }
        return .satisfied
    }
}


// MARK: - 돌보기

extension PetStatePolicy {

    /// 먼저 정산한 뒤 대상 수치만 올린다.
    /// 어느 결과든 정산된 Pet을 돌려주므로 호출부는 항상 저장한다 — 저장하지 않으면 경과 시간이 유실된다.
    static func care(_ pet: Pet, stat: PetCareStat, now: Date) -> PetCareResult {
        var settled = settle(pet, now: now)

        if settled.isDead { return .dead(settled) }
        if settled[keyPath: stat.keyPath] >= maxStat { return .alreadyFull(settled) }

        settled[keyPath: stat.keyPath] = min(maxStat, settled[keyPath: stat.keyPath] + careRecovery)
        return .success(settled)
    }
}


// MARK: - 부활

extension PetStatePolicy {

    /// 사망 상태에서만 HP·돌봄 수치를 복구하고 경험치 페널티를 매긴다.
    /// 중복 요청은 첫 저장 뒤 `hp > 0`이 되어 `.alive`로 걸러지므로 추가 차감이 없다.
    static func revive(_ pet: Pet, now: Date) -> PetReviveResult {
        var settled = settle(pet, now: now)
        guard settled.isDead else { return .alive(settled) }

        settled.hp = maxHP
        // 사망 시점 수치를 그대로 두면 네 수치가 전부 바닥이라 부활 직후 다시 깎여 재사망만 반복된다
        for stat in PetCareStat.allCases {
            settled[keyPath: stat.keyPath] = max(reviveFloor, settled[keyPath: stat.keyPath])
        }
        applyRevivePenalty(&settled)
        return .success(settled)
    }

    /// 현재 레벨에서 모은 경험치가 있으면 요구량의 10%를 깎고, 없으면 레벨을 한 단계 내린다.
    /// 레벨업을 미뤄 초과 경험치가 쌓여 있어도 현재 레벨 요구량 기준으로만 차감한다.
    private static func applyRevivePenalty(_ pet: inout Pet) {
        guard PetLevelPolicy.currentExperience(pet) > 0 else {
            guard pet.level > 0 else { return }
            pet.level -= 1
            pet.totalExperience = PetLevelPolicy.levelStartExperience(level: pet.level)
            return
        }
        let required = PetLevelPolicy.requiredExperience(level: pet.level)
        let penalty = Int(Double(required) * revivePenaltyRate)
        pet.totalExperience = max(
            PetLevelPolicy.levelStartExperience(level: pet.level),
            pet.totalExperience - penalty
        )
    }
}
