import XCTest
import CoreData
@testable import Danogotchi


final class PetPersistenceTests: XCTestCase {

    private var context: NSManagedObjectContext!
    private var repository: DefaultPetRepository!

    override func setUp() {
        super.setUp()
        context = makeInMemoryContext()
        repository = DefaultPetRepository(context: context)
    }

    override func tearDown() {
        repository = nil
        context = nil
        super.tearDown()
    }

    private func petCount() -> Int {
        ((try? context.fetch(PetEntity.fetchRequest())) ?? []).count
    }

    // MARK: - Repository

    func test_처음에는_펫이_없다() throws {
        XCTAssertNil(try repository.readPet())
        XCTAssertEqual(petCount(), 0)
    }

    func test_생성한_펫을_모든_필드_그대로_다시_읽는다() throws {
        let pet = makePet(
            level: 3,
            experience: 640,
            satiety: 71.5,
            hydration: 62.25,
            fun: 48,
            cleanliness: 19.75,
            hp: 27.5,
            stateUpdatedAt: hoursAgo(5)
        )
        _ = try repository.createPet(pet)

        guard let saved = try repository.readPet() else { return XCTFail("펫 저장 실패") }
        XCTAssertEqual(saved.id, pet.id)
        XCTAssertEqual(saved.type, pet.type)
        XCTAssertEqual(saved.name, pet.name)
        XCTAssertEqual(saved.level, 3)
        XCTAssertEqual(saved.experience, 640)
        XCTAssertEqual(saved.satiety, 71.5)
        XCTAssertEqual(saved.hydration, 62.25)
        XCTAssertEqual(saved.fun, 48)
        XCTAssertEqual(saved.cleanliness, 19.75)
        XCTAssertEqual(saved.hp, 27.5)
        XCTAssertEqual(
            saved.stateUpdatedAt.timeIntervalSince1970,
            pet.stateUpdatedAt.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    func test_이미_펫이_있으면_새로_만들지_않고_기존_펫을_돌려준다() throws {
        let first = try XCTUnwrap(try repository.createPet(makePet(name: "첫째")))
        let second = try XCTUnwrap(try repository.createPet(makePet(name: "둘째")))

        XCTAssertEqual(second.id, first.id)
        XCTAssertEqual(second.name, "첫째")
        XCTAssertEqual(petCount(), 1)
    }

    func test_전체_저장이_정산_결과를_그대로_덮어쓴다() throws {
        let pet = try XCTUnwrap(try repository.createPet(makePet(satiety: 60, stateUpdatedAt: hoursAgo(10))))
        let settled = PetStatePolicy.settle(pet, now: Date())

        try repository.updatePet(settled)

        guard let saved = try repository.readPet() else { return XCTFail("펫 저장 실패") }
        XCTAssertEqual(saved.satiety, settled.satiety, accuracy: 0.0001)
        XCTAssertEqual(saved.hp, settled.hp, accuracy: 0.0001)
        XCTAssertEqual(
            saved.stateUpdatedAt.timeIntervalSince1970,
            settled.stateUpdatedAt.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    func test_경험치_가산은_다른_필드를_건드리지_않는다() throws {
        let stateUpdatedAt = hoursAgo(24)
        _ = try repository.createPet(
            makePet(experience: 40, satiety: 30, hp: 12, stateUpdatedAt: stateUpdatedAt)
        )

        XCTAssertEqual(try repository.addExperience(60), 100)

        guard let saved = try repository.readPet() else { return XCTFail("펫 저장 실패") }
        XCTAssertEqual(saved.experience, 100)
        XCTAssertEqual(saved.satiety, 30)
        XCTAssertEqual(saved.hp, 12)
        XCTAssertEqual(
            saved.stateUpdatedAt.timeIntervalSince1970,
            stateUpdatedAt.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    func test_펫이_없으면_경험치_가산은_실패한다() throws {
        XCTAssertThrowsError(try repository.addExperience(10))
    }

    // MARK: - FetchPetStateUseCase

    func test_조회는_정산_결과를_저장한다() throws {
        _ = try repository.createPet(makePet(stateUpdatedAt: hoursAgo(24)))
        let useCase = DefaultFetchPetStateUseCase(petRepository: repository)

        guard let info = try useCase.execute() else { return XCTFail("조회 실패") }

        // 24시간 방치 — 포만감 100 - 24 × 0.8
        XCTAssertEqual(info.pet.satiety, 80.8, accuracy: 0.01)
        XCTAssertEqual(try repository.readPet()?.satiety ?? 0, 80.8, accuracy: 0.01)
        XCTAssertEqual(
            try repository.readPet()?.stateUpdatedAt.timeIntervalSinceNow ?? -1, 0, accuracy: 1
        )
    }

    func test_펫이_없으면_조회는_nil을_돌려준다() throws {
        XCTAssertNil(try DefaultFetchPetStateUseCase(petRepository: repository).execute())
    }

    func test_연속_조회가_같은_경과를_두_번_적용하지_않는다() throws {
        _ = try repository.createPet(makePet(stateUpdatedAt: hoursAgo(24)))
        let useCase = DefaultFetchPetStateUseCase(petRepository: repository)

        let first = try useCase.execute()
        let second = try useCase.execute()

        XCTAssertEqual(second?.pet.satiety ?? 0, first?.pet.satiety ?? -1, accuracy: 0.01)
    }

    // MARK: - CarePetUseCase

    func test_돌보기는_감소분_위에_25를_더해_저장한다() throws {
        _ = try repository.createPet(makePet(satiety: 50, stateUpdatedAt: hoursAgo(24)))
        let useCase = DefaultCarePetUseCase(petRepository: repository)

        let result = try useCase.execute(stat: .satiety)

        // 50 - 24 × 0.8 = 30.8 → +25
        XCTAssertNil(result?.rejection)
        XCTAssertEqual(try repository.readPet()?.satiety ?? 0, 55.8, accuracy: 0.01)
    }

    /// 감소가 계속 일어나므로 "이미 100"은 경과 시간이 `0` 이하일 때만 성립한다 —
    /// 기기 시각을 미래로 옮겼다 되돌린 상황이다. 거절돼도 타임스탬프 재동기화는 저장돼야 한다.
    func test_이미_100이면_거절하지만_정산분은_저장한다() throws {
        _ = try repository.createPet(makePet(stateUpdatedAt: Date().addingTimeInterval(60)))
        let useCase = DefaultCarePetUseCase(petRepository: repository)

        let result = try useCase.execute(stat: .satiety)

        XCTAssertEqual(result?.rejection, .alreadyFull)
        XCTAssertEqual(try repository.readPet()?.satiety ?? 0, 100)
        XCTAssertEqual(
            try repository.readPet()?.stateUpdatedAt.timeIntervalSinceNow ?? -1, 0, accuracy: 1
        )
    }

    func test_사망_상태에서_돌보기는_거절되지만_정산분은_저장한다() throws {
        _ = try repository.createPet(makePet(satiety: 50, hp: 0, stateUpdatedAt: hoursAgo(24)))
        let useCase = DefaultCarePetUseCase(petRepository: repository)

        let result = try useCase.execute(stat: .satiety)

        XCTAssertEqual(result?.rejection, .dead)
        // 회복분 25는 붙지 않고 감소분만 저장된다
        XCTAssertEqual(try repository.readPet()?.satiety ?? 0, 30.8, accuracy: 0.01)
        XCTAssertEqual(try repository.readPet()?.hp ?? -1, 0)
    }

    // MARK: - LevelUpPetUseCase

    func test_경험치가_부족하면_직접_호출해도_레벨이_오르지_않는다() throws {
        _ = try repository.createPet(makePet(experience: 999, stateUpdatedAt: hoursAgo(1)))
        let useCase = DefaultLevelUpPetUseCase(petRepository: repository)

        let result = try useCase.execute()

        XCTAssertEqual(result?.rejection, .notEnoughExperience)
        XCTAssertEqual(try repository.readPet()?.level, 0)
    }

    func test_레벨업은_초과_경험치를_버린다() throws {
        _ = try repository.createPet(makePet(experience: 2_500, stateUpdatedAt: hoursAgo(1)))
        let useCase = DefaultLevelUpPetUseCase(petRepository: repository)

        let result = try useCase.execute()

        XCTAssertNil(result?.rejection)
        XCTAssertEqual(try repository.readPet()?.level, 1)
        // 요구량 1,000을 넘긴 1,500은 이월되지 않는다
        XCTAssertEqual(try repository.readPet()?.experience, 0)
        XCTAssertEqual(result?.info.progress ?? -1, 0, accuracy: 0.001)
        XCTAssertEqual(result?.info.canLevelUp, false)
    }

    // MARK: - AdjustPetLevelUseCase

    func test_테스트용_레벨_조절은_경험치를_두고_정책_범위_안에서만_움직인다() throws {
        _ = try repository.createPet(makePet(experience: 500, stateUpdatedAt: hoursAgo(1)))
        let useCase = DefaultAdjustPetLevelUseCase(petRepository: repository)

        _ = try useCase.execute(delta: -1)
        XCTAssertEqual(try repository.readPet()?.level, 0)

        _ = try useCase.execute(delta: 1)
        XCTAssertEqual(try repository.readPet()?.level, 1)
        // 요구 경험치를 건너뛰기만 하고 경험치 자체는 그대로 둔다
        XCTAssertEqual(try repository.readPet()?.experience, 500)

        _ = try useCase.execute(delta: PetLevelPolicy.maxLevel + 5)
        XCTAssertEqual(try repository.readPet()?.level, PetLevelPolicy.maxLevel)
    }

    // MARK: - RevivePetUseCase

    func test_부활은_HP와_수치와_페널티를_한_번에_저장한다() throws {
        _ = try repository.createPet(
            makePet(
                level: 1,
                experience: 1_000,
                satiety: 0, hydration: 0, fun: 0, cleanliness: 0,
                hp: 0,
                stateUpdatedAt: hoursAgo(24)
            )
        )
        let useCase = DefaultRevivePetUseCase(petRepository: repository)

        let result = try useCase.execute()

        XCTAssertNil(result?.rejection)
        guard let saved = try repository.readPet() else { return XCTFail("펫 저장 실패") }
        XCTAssertEqual(saved.hp, PetStatePolicy.maxHP)
        for stat in PetCareStat.allCases {
            XCTAssertGreaterThanOrEqual(saved[keyPath: stat.keyPath], PetStatePolicy.reviveFloor)
        }
        // 레벨 1 요구량 2,105의 10%
        XCTAssertEqual(saved.experience, 790)
        XCTAssertEqual(saved.level, 1)
    }

    func test_살아_있으면_부활을_거절한다() throws {
        _ = try repository.createPet(makePet(stateUpdatedAt: hoursAgo(1)))
        let useCase = DefaultRevivePetUseCase(petRepository: repository)

        let result = try useCase.execute()

        XCTAssertEqual(result?.rejection, .alive)
        XCTAssertEqual(try repository.readPet()?.hp ?? -1, PetStatePolicy.maxHP)
    }

    // MARK: - CreatePetUseCase

    func test_생성은_모든_수치를_최대로_시작한다() throws {
        let useCase = DefaultCreatePetUseCase(petRepository: repository)

        let pet = try XCTUnwrap(try useCase.execute(type: .sprout, name: "새싹"))

        XCTAssertEqual(pet.name, "새싹")
        XCTAssertEqual(pet.level, 0)
        XCTAssertEqual(pet.experience, 0)
        XCTAssertEqual(pet.hp, PetStatePolicy.maxHP)
        for stat in PetCareStat.allCases {
            XCTAssertEqual(pet[keyPath: stat.keyPath], PetStatePolicy.initialStat)
        }
    }

    func test_생성을_두_번_호출해도_펫은_한_마리다() throws {
        let useCase = DefaultCreatePetUseCase(petRepository: repository)

        let first = try XCTUnwrap(try useCase.execute(type: .sprout, name: "새싹"))
        let second = try XCTUnwrap(try useCase.execute(type: .sprout, name: "다른이름"))

        XCTAssertEqual(second.id, first.id)
        XCTAssertEqual(second.name, "새싹")
        XCTAssertEqual(petCount(), 1)
    }

    // MARK: - IsPetCreatedUseCase

    func test_펫_존재_여부는_생성_전후로_바뀐다() throws {
        let useCase = DefaultIsPetCreatedUseCase(petRepository: repository)

        XCTAssertFalse(try useCase.execute())

        _ = try repository.createPet(makePet())

        XCTAssertTrue(try useCase.execute())
    }

    // MARK: - EarnExperienceUseCase

    private func makeEarnExperienceUseCase() -> DefaultEarnExperienceUseCase {
        DefaultEarnExperienceUseCase(
            learningHistoryRepository: DefaultLearningHistoryRepository(context: context),
            petRepository: repository
        )
    }

    func test_경험치_적립은_경험치만_올리고_정산_시각을_보존한다() throws {
        let stateUpdatedAt = hoursAgo(24)
        _ = try repository.createPet(makePet(hp: 20, stateUpdatedAt: stateUpdatedAt))

        let gain = try makeEarnExperienceUseCase().commit(earned: 30, correct: 2, total: 4)

        XCTAssertEqual(gain.total, 30)
        guard let saved = try repository.readPet() else { return XCTFail("펫 저장 실패") }
        XCTAssertEqual(saved.experience, 30)
        XCTAssertEqual(saved.hp, 20)
        XCTAssertEqual(
            saved.stateUpdatedAt.timeIntervalSince1970,
            stateUpdatedAt.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    func test_펫이_없으면_획득_성공을_반환하지_않는다() throws {
        XCTAssertThrowsError(try makeEarnExperienceUseCase().commit(earned: 30, correct: 4, total: 4))
        XCTAssertNil(try repository.readPet())
    }
}
