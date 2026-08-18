import XCTest
@testable import Danogotchi


final class PetStatePolicyTests: XCTestCase {

    // MARK: - 돌봄 수치 감소

    func test_경과시간이_0이면_수치가_변하지_않는다() {
        let settled = PetStatePolicy.settle(makePet(), now: testBase)
        XCTAssertEqual(settled.satiety, 100, accuracy: 0.001)
        XCTAssertEqual(settled.hp, PetStatePolicy.maxHP, accuracy: 0.001)
    }

    func test_수치는_시간당_감소율만큼_줄어든다() {
        let settled = PetStatePolicy.settle(makePet(), now: hoursLater(1))
        XCTAssertEqual(settled.satiety, 99.2, accuracy: 0.001)
        XCTAssertEqual(settled.hydration, 99.0, accuracy: 0.001)
        XCTAssertEqual(settled.fun, 99.4, accuracy: 0.001)
        XCTAssertEqual(settled.cleanliness, 99.6, accuracy: 0.001)
    }

    func test_수치는_0_아래로_내려가지_않는다() {
        let settled = PetStatePolicy.settle(makePet(), now: hoursLater(1000))
        for stat in PetCareStat.allCases {
            XCTAssertEqual(settled[keyPath: stat.keyPath], 0, accuracy: 0.001, stat.title)
        }
    }

    func test_현재시각이_과거면_수치는_그대로_두고_타임스탬프만_재동기화한다() {
        let pet = makePet(satiety: 50, hp: 30)
        let past = testBase.addingTimeInterval(-10 * 3600)

        let settled = PetStatePolicy.settle(pet, now: past)

        XCTAssertEqual(settled.satiety, 50, accuracy: 0.001)
        XCTAssertEqual(settled.hp, 30, accuracy: 0.001)
        // 되돌리지 않으면 미래 시점까지 상태가 얼어붙는다
        XCTAssertEqual(settled.stateUpdatedAt, past)
    }

    // MARK: - HP 정산

    func test_무돌봄_HP_곡선() {
        let expected: [(hours: Double, hp: Double)] = [
            (24, 40), (48, 40), (72, 40), (80, 40),
            (84, 39), (96, 36), (100, 35), (400.0 / 3, 18.3333),
        ]
        for (hours, hp) in expected {
            let settled = PetStatePolicy.settle(makePet(), now: hoursLater(hours))
            XCTAssertEqual(settled.hp, hp, accuracy: 0.001, "\(hours)시간")
        }
    }

    func test_사망_경계는_157시간_46분_40초() {
        XCTAssertFalse(PetStatePolicy.settle(makePet(), now: hoursLater(157.7)).isDead)
        XCTAssertTrue(PetStatePolicy.settle(makePet(), now: hoursLater(157.78)).isDead)
        // 경계 정확값에서는 Double 누적 오차가 남을 수 있어 0 근사만 확인한다
        XCTAssertEqual(PetStatePolicy.settle(makePet(), now: hoursLater(1420.0 / 9)).hp, 0, accuracy: 1e-9)
    }

    func test_한_번_정산과_나눠_정산한_결과가_같다() {
        let once = PetStatePolicy.settle(makePet(), now: hoursLater(96))

        var stepwise = makePet()
        for step in 1...4 {
            stepwise = PetStatePolicy.settle(stepwise, now: hoursLater(Double(step) * 24))
        }

        XCTAssertEqual(once.hp, 36, accuracy: 0.001)
        XCTAssertEqual(stepwise.hp, once.hp, accuracy: 0.001)
        XCTAssertEqual(stepwise.satiety, once.satiety, accuracy: 0.001)
    }

    func test_네_수치가_모두_65_초과면_HP를_회복한다() {
        let settled = PetStatePolicy.settle(makePet(hp: 30), now: hoursLater(10))
        XCTAssertEqual(settled.hp, 35, accuracy: 0.001)
    }

    func test_HP는_40을_넘지_않는다() {
        let settled = PetStatePolicy.settle(makePet(hp: 39), now: hoursLater(10))
        XCTAssertEqual(settled.hp, PetStatePolicy.maxHP, accuracy: 0.001)
    }

    func test_최저수치가_20_초과_65_이하면_HP가_변하지_않는다() {
        let pet = makePet(satiety: 60, hydration: 60, fun: 60, cleanliness: 60, hp: 20)
        let settled = PetStatePolicy.settle(pet, now: hoursLater(10))
        XCTAssertEqual(settled.hp, 20, accuracy: 0.001)
    }

    func test_위험수치_개수만큼_HP가_깎인다() {
        // 위험 1개 → 4시간에 1칸
        let one = PetStatePolicy.settle(
            makePet(satiety: 60, hydration: 20, fun: 60, cleanliness: 60),
            now: hoursLater(4)
        )
        XCTAssertEqual(one.hp, 39, accuracy: 0.001)

        // 위험 2개 → 2시간에 1칸
        let two = PetStatePolicy.settle(
            makePet(satiety: 20, hydration: 20, fun: 60, cleanliness: 60),
            now: hoursLater(2)
        )
        XCTAssertEqual(two.hp, 39, accuracy: 0.001)

        // 위험 3개
        let three = PetStatePolicy.settle(
            makePet(satiety: 20, hydration: 20, fun: 20, cleanliness: 60),
            now: hoursLater(4)
        )
        XCTAssertEqual(three.hp, 37, accuracy: 0.001)
    }

    func test_한_경과구간_안에서_임계값을_통과하면_구간별로_적용한다() {
        // 수분 66에서 시작 → 1시간 뒤 65 통과(회복 정지), 46시간 뒤 20 통과(감소 시작)
        let pet = makePet(hydration: 66, hp: 30)
        // 0~1h 회복(+0.5), 1~46h 정지, 46~50h 감소(-0.25 × 4)
        let settled = PetStatePolicy.settle(pet, now: hoursLater(50))
        XCTAssertEqual(settled.hp, 29.5, accuracy: 0.001)
    }

    func test_회복분은_상한에_막히고_이후_피해만_남는다() {
        // 상계 후 한 번만 제한하면 버려질 회복분이 피해를 상쇄해 40이 되어버린다
        let pet = makePet(hydration: 66, hp: 40)
        let settled = PetStatePolicy.settle(pet, now: hoursLater(50))
        XCTAssertEqual(settled.hp, 39, accuracy: 0.001)
    }

    func test_사망한_펫은_HP가_회복되지_않는다() {
        let settled = PetStatePolicy.settle(makePet(hp: 0), now: hoursLater(10))
        XCTAssertTrue(settled.isDead)
        XCTAssertEqual(settled.hp, 0, accuracy: 0.001)
        // 돌봄 수치는 계속 감소한다
        XCTAssertEqual(settled.satiety, 92, accuracy: 0.001)
    }

    func test_매일_네_돌보기를_하면_7일_뒤에도_HP가_유지된다() {
        var pet = makePet()
        for day in 1...7 {
            let now = hoursLater(Double(day) * 24)
            for stat in PetCareStat.allCases {
                pet = petAfterCare(pet, stat, now)
            }
        }
        XCTAssertEqual(pet.hp, PetStatePolicy.maxHP, accuracy: 0.001)
        XCTAssertFalse(pet.isDead)
    }

    // MARK: - 기분

    func test_무돌봄_기분_전이() {
        let expected: [(hours: Double, mood: PetMood)] = [
            (0, .happy), (19.99, .happy), (20, .happy), (20.01, .satisfied),
            (34.99, .satisfied), (35, .thirsty),
            (43.74, .thirsty), (43.75, .sad),
            (68.74, .sad), (68.75, .depressed),
        ]
        for (hours, mood) in expected {
            let settled = PetStatePolicy.settle(makePet(), now: hoursLater(hours))
            XCTAssertEqual(PetStatePolicy.mood(settled), mood, "\(hours)시간")
        }
    }

    func test_자연방치_중에는_상쾌함이_나타나지_않는다() {
        // 청결이 95 이상인 12.5시간까지는 규칙 4가 행복함으로 선점한다
        for step in 0...400 {
            let settled = PetStatePolicy.settle(makePet(), now: hoursLater(Double(step) * 0.5))
            XCTAssertNotEqual(PetStatePolicy.mood(settled), .refreshed, "\(Double(step) * 0.5)시간")
        }
    }

    func test_청결을_높이면_상쾌함이_나타난다() {
        let pet = makePet(satiety: 70, hydration: 70, fun: 70, cleanliness: 100)
        XCTAssertEqual(PetStatePolicy.mood(pet), .refreshed)
    }

    func test_기분_경계값() {
        // 45 경계 — 2개가 45 이하면 우울함
        XCTAssertEqual(PetStatePolicy.mood(makePet(satiety: 45, hydration: 45)), .depressed)
        XCTAssertEqual(PetStatePolicy.mood(makePet(satiety: 45, hydration: 46)), .sad)
        // 65 경계 — 1개만 65 이하면 그 수치의 기분
        XCTAssertEqual(PetStatePolicy.mood(makePet(satiety: 65)), .hungry)
        // 청결을 95 아래로 낮춰야 상쾌함 규칙에 걸리지 않는다
        XCTAssertEqual(PetStatePolicy.mood(makePet(satiety: 66, cleanliness: 90)), .satisfied)
        // 80 경계 — 네 수치가 모두 80 이상이면 행복함
        XCTAssertEqual(PetStatePolicy.mood(makePet(satiety: 80, hydration: 80, fun: 80, cleanliness: 80)), .happy)
        XCTAssertEqual(PetStatePolicy.mood(makePet(satiety: 79, hydration: 80, fun: 80, cleanliness: 80)), .satisfied)
        // 95 경계 — 청결만 높을 때
        XCTAssertEqual(PetStatePolicy.mood(makePet(satiety: 70, hydration: 70, fun: 70, cleanliness: 95)), .refreshed)
        XCTAssertEqual(PetStatePolicy.mood(makePet(satiety: 70, hydration: 70, fun: 70, cleanliness: 94)), .satisfied)
    }

    func test_한_수치만_저하되면_그_수치의_기분이_된다() {
        XCTAssertEqual(PetStatePolicy.mood(makePet(satiety: 60)), .hungry)
        XCTAssertEqual(PetStatePolicy.mood(makePet(hydration: 60)), .thirsty)
        XCTAssertEqual(PetStatePolicy.mood(makePet(fun: 60)), .bored)
        XCTAssertEqual(PetStatePolicy.mood(makePet(cleanliness: 60)), .unpleasant)
    }

    func test_위험상태여도_기분은_한_수치_저하_수준에_머무른다() {
        // HP가 깎이고 있다는 사실은 화면의 위험 표시가 알린다
        XCTAssertEqual(PetStatePolicy.mood(makePet(satiety: 5)), .hungry)
    }

    // MARK: - 돌보기

    func test_돌보기는_정산_후_대상_수치를_25_올린다() {
        // 10시간 뒤 포만감 42 → +25
        guard case .success(let pet) = PetStatePolicy.care(makePet(satiety: 50), stat: .satiety, now: hoursLater(10)) else {
            return XCTFail("성공해야 한다")
        }
        XCTAssertEqual(pet.satiety, 67, accuracy: 0.001)
        // 다른 수치는 정산만 된다
        XCTAssertEqual(pet.hydration, 90, accuracy: 0.001)
    }

    func test_돌보기는_100을_넘지_않는다() {
        guard case .success(let pet) = PetStatePolicy.care(makePet(satiety: 79), stat: .satiety, now: hoursLater(1)) else {
            return XCTFail("성공해야 한다")
        }
        XCTAssertEqual(pet.satiety, PetStatePolicy.maxStat, accuracy: 0.001)
    }

    func test_이미_80_이상이면_안내하되_정산_결과는_저장한다() {
        // 시각을 되돌린 상황 — 수치는 그대로지만 타임스탬프는 재동기화된다
        let past = testBase.addingTimeInterval(-3600)
        let pet = makePet(satiety: PetStatePolicy.careThreshold)
        guard case .alreadyFull(let cared) = PetStatePolicy.care(pet, stat: .satiety, now: past) else {
            return XCTFail("alreadyFull이어야 한다")
        }
        XCTAssertEqual(cared.satiety, PetStatePolicy.careThreshold, accuracy: 0.001)
        XCTAssertEqual(cared.stateUpdatedAt, past)
    }

    func test_사망한_펫은_돌볼_수_없지만_정산_결과는_저장한다() {
        guard case .dead(let pet) = PetStatePolicy.care(makePet(), stat: .satiety, now: hoursLater(200)) else {
            return XCTFail("dead여야 한다")
        }
        XCTAssertEqual(pet.hp, 0, accuracy: 0.001)
        // +25가 적용되지 않았다
        XCTAssertEqual(pet.satiety, 0, accuracy: 0.001)
        XCTAssertEqual(pet.stateUpdatedAt, hoursLater(200))
    }

    // MARK: - 부활

    func test_부활은_HP와_돌봄수치를_복구한다() {
        let dead = makePet(satiety: 0, hydration: 0, fun: 0, cleanliness: 0, hp: 0)
        guard case .success(let pet) = PetStatePolicy.revive(dead, now: testBase) else {
            return XCTFail("성공해야 한다")
        }
        XCTAssertEqual(pet.hp, PetStatePolicy.maxHP, accuracy: 0.001)
        for stat in PetCareStat.allCases {
            XCTAssertGreaterThanOrEqual(pet[keyPath: stat.keyPath], PetStatePolicy.reviveFloor, stat.title)
        }
    }

    func test_부활_직후에는_HP가_곧바로_깎이지_않는다() {
        let dead = makePet(satiety: 0, hydration: 0, fun: 0, cleanliness: 0, hp: 0)
        guard case .success(let revived) = PetStatePolicy.revive(dead, now: testBase) else {
            return XCTFail("성공해야 한다")
        }
        // 50에서 가장 빠른 수분이 20에 닿는 데 30시간이 걸린다
        let after = PetStatePolicy.settle(revived, now: revived.stateUpdatedAt.addingTimeInterval(29 * 3600))
        XCTAssertEqual(after.hp, PetStatePolicy.maxHP, accuracy: 0.001)
    }

    func test_부활_페널티는_현재레벨_요구량의_10퍼센트() {
        // 레벨 1 요구량 2,105의 10% = 210
        let dead = makePet(level: 1, experience: 1_000, hp: 0)
        guard case .success(let pet) = PetStatePolicy.revive(dead, now: testBase) else {
            return XCTFail("성공해야 한다")
        }
        XCTAssertEqual(pet.experience, 790)
    }

    func test_부활_페널티는_0_아래로_내려가지_않는다() {
        // 차감량(210)보다 적게 모았어도 레벨은 유지된다
        let dead = makePet(level: 1, experience: 100, hp: 0)
        guard case .success(let pet) = PetStatePolicy.revive(dead, now: testBase) else {
            return XCTFail("성공해야 한다")
        }
        XCTAssertEqual(pet.level, 1)
        XCTAssertEqual(pet.experience, 0)
        XCTAssertEqual(PetLevelPolicy.progress(pet), 0, accuracy: 0.001)
    }

    func test_진행률_0퍼센트에서_부활하면_레벨이_한_단계_내려간다() {
        let dead = makePet(level: 2, experience: 0, hp: 0)
        guard case .success(let pet) = PetStatePolicy.revive(dead, now: testBase) else {
            return XCTFail("성공해야 한다")
        }
        XCTAssertEqual(pet.level, 1)
        // 내려간 레벨의 경험치도 복원하지 않는다
        XCTAssertEqual(pet.experience, 0)
        XCTAssertEqual(PetLevelPolicy.progress(pet), 0, accuracy: 0.001)
    }

    func test_레벨0에서는_더_내려가지_않는다() {
        let dead = makePet(level: 0, experience: 0, hp: 0)
        guard case .success(let pet) = PetStatePolicy.revive(dead, now: testBase) else {
            return XCTFail("성공해야 한다")
        }
        XCTAssertEqual(pet.level, 0)
        XCTAssertEqual(pet.experience, 0)
    }

    func test_승급을_미뤄_초과분이_쌓여도_요구량의_10퍼센트만_깎는다() {
        let dead = makePet(level: 0, experience: 2_500, hp: 0)
        guard case .success(let pet) = PetStatePolicy.revive(dead, now: testBase) else {
            return XCTFail("성공해야 한다")
        }
        XCTAssertEqual(pet.experience, 2_400)
        // 초과분이 남아 차감 후에도 게이지가 100%다
        XCTAssertTrue(PetLevelPolicy.canLevelUp(pet))
    }

    func test_살아있는_펫은_부활할_수_없지만_정산_결과는_저장한다() {
        guard case .alive(let pet) = PetStatePolicy.revive(makePet(), now: hoursLater(10)) else {
            return XCTFail("alive여야 한다")
        }
        XCTAssertEqual(pet.stateUpdatedAt, hoursLater(10))
        XCTAssertEqual(pet.satiety, 92, accuracy: 0.001)
    }

    func test_부활을_두_번_요청해도_경험치가_한_번만_깎인다() {
        let dead = makePet(level: 1, experience: 1_000, hp: 0)
        guard case .success(let first) = PetStatePolicy.revive(dead, now: testBase) else {
            return XCTFail("성공해야 한다")
        }
        guard case .alive(let second) = PetStatePolicy.revive(first, now: testBase) else {
            return XCTFail("두 번째는 alive여야 한다")
        }
        XCTAssertEqual(second.experience, 790)
    }
}
