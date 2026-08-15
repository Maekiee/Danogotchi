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

    func test_처음에는_펫이_없다() {
        XCTAssertNil(repository.readPet())
        XCTAssertEqual(petCount(), 0)
    }

    func test_생성한_펫을_모든_필드_그대로_다시_읽는다() {
        let pet = makePet(
            level: 3,
            totalExperience: 640,
            satiety: 71.5,
            hydration: 62.25,
            fun: 48,
            cleanliness: 19.75,
            hp: 27.5,
            stateUpdatedAt: hoursAgo(5)
        )
        _ = repository.createPet(pet)

        guard let saved = repository.readPet() else { return XCTFail("펫 저장 실패") }
        XCTAssertEqual(saved.id, pet.id)
        XCTAssertEqual(saved.type, pet.type)
        XCTAssertEqual(saved.name, pet.name)
        XCTAssertEqual(saved.level, 3)
        XCTAssertEqual(saved.totalExperience, 640)
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
        let first = try XCTUnwrap(repository.createPet(makePet(name: "첫째")))
        let second = try XCTUnwrap(repository.createPet(makePet(name: "둘째")))

        XCTAssertEqual(second.id, first.id)
        XCTAssertEqual(second.name, "첫째")
        XCTAssertEqual(petCount(), 1)
    }

    func test_전체_저장이_정산_결과를_그대로_덮어쓴다() throws {
        let pet = try XCTUnwrap(repository.createPet(makePet(satiety: 60, stateUpdatedAt: hoursAgo(10))))
        let settled = PetStatePolicy.settle(pet, now: Date())

        repository.updatePet(settled)

        guard let saved = repository.readPet() else { return XCTFail("펫 저장 실패") }
        XCTAssertEqual(saved.satiety, settled.satiety, accuracy: 0.0001)
        XCTAssertEqual(saved.hp, settled.hp, accuracy: 0.0001)
        XCTAssertEqual(
            saved.stateUpdatedAt.timeIntervalSince1970,
            settled.stateUpdatedAt.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    func test_경험치_가산은_다른_필드를_건드리지_않는다() {
        let stateUpdatedAt = hoursAgo(24)
        _ = repository.createPet(
            makePet(totalExperience: 40, satiety: 30, hp: 12, stateUpdatedAt: stateUpdatedAt)
        )

        XCTAssertEqual(repository.addExperience(60), 100)

        guard let saved = repository.readPet() else { return XCTFail("펫 저장 실패") }
        XCTAssertEqual(saved.totalExperience, 100)
        XCTAssertEqual(saved.satiety, 30)
        XCTAssertEqual(saved.hp, 12)
        XCTAssertEqual(
            saved.stateUpdatedAt.timeIntervalSince1970,
            stateUpdatedAt.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    func test_펫이_없으면_경험치_가산은_nil을_돌려준다() {
        XCTAssertNil(repository.addExperience(10))
    }

    // MARK: - FetchPetStateUseCase

    func test_조회는_정산_결과를_저장한다() {
        _ = repository.createPet(makePet(stateUpdatedAt: hoursAgo(24)))
        let useCase = DefaultFetchPetStateUseCase(petRepository: repository)

        guard let info = useCase.execute() else { return XCTFail("조회 실패") }

        // 24시간 방치 — 포만감 100 - 24 × 0.8
        XCTAssertEqual(info.pet.satiety, 80.8, accuracy: 0.01)
        XCTAssertEqual(repository.readPet()?.satiety ?? 0, 80.8, accuracy: 0.01)
        XCTAssertEqual(
            repository.readPet()?.stateUpdatedAt.timeIntervalSinceNow ?? -1, 0, accuracy: 1
        )
    }

    func test_펫이_없으면_조회는_nil을_돌려준다() {
        XCTAssertNil(DefaultFetchPetStateUseCase(petRepository: repository).execute())
    }

    func test_연속_조회가_같은_경과를_두_번_적용하지_않는다() {
        _ = repository.createPet(makePet(stateUpdatedAt: hoursAgo(24)))
        let useCase = DefaultFetchPetStateUseCase(petRepository: repository)

        let first = useCase.execute()
        let second = useCase.execute()

        XCTAssertEqual(second?.pet.satiety ?? 0, first?.pet.satiety ?? -1, accuracy: 0.01)
    }

    // MARK: - CarePetUseCase

    func test_돌보기는_감소분_위에_25를_더해_저장한다() {
        _ = repository.createPet(makePet(satiety: 50, stateUpdatedAt: hoursAgo(24)))
        let useCase = DefaultCarePetUseCase(petRepository: repository)

        let result = useCase.execute(stat: .satiety)

        // 50 - 24 × 0.8 = 30.8 → +25
        XCTAssertNil(result?.rejection)
        XCTAssertEqual(repository.readPet()?.satiety ?? 0, 55.8, accuracy: 0.01)
    }

    /// 감소가 계속 일어나므로 "이미 100"은 경과 시간이 `0` 이하일 때만 성립한다 —
    /// 기기 시각을 미래로 옮겼다 되돌린 상황이다. 거절돼도 타임스탬프 재동기화는 저장돼야 한다.
    func test_이미_100이면_거절하지만_정산분은_저장한다() {
        _ = repository.createPet(makePet(stateUpdatedAt: Date().addingTimeInterval(60)))
        let useCase = DefaultCarePetUseCase(petRepository: repository)

        let result = useCase.execute(stat: .satiety)

        XCTAssertEqual(result?.rejection, .alreadyFull)
        XCTAssertEqual(repository.readPet()?.satiety ?? 0, 100)
        XCTAssertEqual(
            repository.readPet()?.stateUpdatedAt.timeIntervalSinceNow ?? -1, 0, accuracy: 1
        )
    }

    func test_사망_상태에서_돌보기는_거절되지만_정산분은_저장한다() {
        _ = repository.createPet(makePet(satiety: 50, hp: 0, stateUpdatedAt: hoursAgo(24)))
        let useCase = DefaultCarePetUseCase(petRepository: repository)

        let result = useCase.execute(stat: .satiety)

        XCTAssertEqual(result?.rejection, .dead)
        // 회복분 25는 붙지 않고 감소분만 저장된다
        XCTAssertEqual(repository.readPet()?.satiety ?? 0, 30.8, accuracy: 0.01)
        XCTAssertEqual(repository.readPet()?.hp ?? -1, 0)
    }

    // MARK: - LevelUpPetUseCase

    func test_경험치가_부족하면_직접_호출해도_레벨이_오르지_않는다() {
        _ = repository.createPet(makePet(totalExperience: 99, stateUpdatedAt: hoursAgo(1)))
        let useCase = DefaultLevelUpPetUseCase(petRepository: repository)

        let result = useCase.execute()

        XCTAssertEqual(result?.rejection, .notEnoughExperience)
        XCTAssertEqual(repository.readPet()?.level, 0)
    }

    func test_레벨업은_초과_경험치를_보존한다() {
        _ = repository.createPet(makePet(totalExperience: 250, stateUpdatedAt: hoursAgo(1)))
        let useCase = DefaultLevelUpPetUseCase(petRepository: repository)

        let result = useCase.execute()

        XCTAssertNil(result?.rejection)
        XCTAssertEqual(repository.readPet()?.level, 1)
        XCTAssertEqual(repository.readPet()?.totalExperience, 250)
        // 레벨 1 진행분 150 / 요구량 200
        XCTAssertEqual(result?.info.currentExperience, 150)
        XCTAssertEqual(result?.info.requiredExperience, 200)
    }

    // MARK: - RevivePetUseCase

    func test_부활은_HP와_수치와_페널티를_한_번에_저장한다() {
        _ = repository.createPet(
            makePet(
                level: 1,
                totalExperience: 250,
                satiety: 0, hydration: 0, fun: 0, cleanliness: 0,
                hp: 0,
                stateUpdatedAt: hoursAgo(24)
            )
        )
        let useCase = DefaultRevivePetUseCase(petRepository: repository)

        let result = useCase.execute()

        XCTAssertNil(result?.rejection)
        guard let saved = repository.readPet() else { return XCTFail("펫 저장 실패") }
        XCTAssertEqual(saved.hp, PetStatePolicy.maxHP)
        for stat in PetCareStat.allCases {
            XCTAssertGreaterThanOrEqual(saved[keyPath: stat.keyPath], PetStatePolicy.reviveFloor)
        }
        // 레벨 1 요구량 200의 10%
        XCTAssertEqual(saved.totalExperience, 230)
        XCTAssertEqual(saved.level, 1)
    }

    func test_살아_있으면_부활을_거절한다() {
        _ = repository.createPet(makePet(stateUpdatedAt: hoursAgo(1)))
        let useCase = DefaultRevivePetUseCase(petRepository: repository)

        let result = useCase.execute()

        XCTAssertEqual(result?.rejection, .alive)
        XCTAssertEqual(repository.readPet()?.hp ?? -1, PetStatePolicy.maxHP)
    }

    // MARK: - CreatePetUseCase

    func test_생성은_모든_수치를_최대로_시작한다() throws {
        let useCase = DefaultCreatePetUseCase(petRepository: repository)

        let pet = try XCTUnwrap(useCase.execute(type: .sprout, name: "새싹"))

        XCTAssertEqual(pet.name, "새싹")
        XCTAssertEqual(pet.level, 0)
        XCTAssertEqual(pet.totalExperience, 0)
        XCTAssertEqual(pet.hp, PetStatePolicy.maxHP)
        for stat in PetCareStat.allCases {
            XCTAssertEqual(pet[keyPath: stat.keyPath], PetStatePolicy.maxStat)
        }
    }

    func test_생성을_두_번_호출해도_펫은_한_마리다() throws {
        let useCase = DefaultCreatePetUseCase(petRepository: repository)

        let first = try XCTUnwrap(useCase.execute(type: .sprout, name: "새싹"))
        let second = try XCTUnwrap(useCase.execute(type: .sprout, name: "다른이름"))

        XCTAssertEqual(second.id, first.id)
        XCTAssertEqual(second.name, "새싹")
        XCTAssertEqual(petCount(), 1)
    }

    // MARK: - IsPetCreatedUseCase

    func test_펫_존재_여부는_생성_전후로_바뀐다() {
        let useCase = DefaultIsPetCreatedUseCase(petRepository: repository)

        XCTAssertFalse(useCase.execute())

        _ = repository.createPet(makePet())

        XCTAssertTrue(useCase.execute())
    }

    // MARK: - EarnExperienceUseCase

    private func makeEarnExperienceUseCase() -> DefaultEarnExperienceUseCase {
        DefaultEarnExperienceUseCase(
            learningHistoryRepository: DefaultLearningHistoryRepository(context: context),
            petRepository: repository
        )
    }

    func test_경험치_적립은_totalExperience만_올리고_정산_시각을_보존한다() {
        let stateUpdatedAt = hoursAgo(24)
        _ = repository.createPet(makePet(hp: 20, stateUpdatedAt: stateUpdatedAt))

        let gain = makeEarnExperienceUseCase().commit(earned: 30, correct: 2, total: 4)

        XCTAssertEqual(gain.totalPoint, 30)
        guard let saved = repository.readPet() else { return XCTFail("펫 저장 실패") }
        XCTAssertEqual(saved.totalExperience, 30)
        XCTAssertEqual(saved.hp, 20)
        XCTAssertEqual(
            saved.stateUpdatedAt.timeIntervalSince1970,
            stateUpdatedAt.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    func test_펫이_없으면_적립은_0을_돌려준다() {
        let gain = makeEarnExperienceUseCase().commit(earned: 30, correct: 4, total: 4)

        XCTAssertEqual(gain.totalPoint, 0)
        // 산정 자체는 정상이므로 획득량과 보너스는 그대로 돌려준다
        XCTAssertEqual(gain.earned, 30)
        XCTAssertEqual(gain.perfectBonus, 4)
    }
}
