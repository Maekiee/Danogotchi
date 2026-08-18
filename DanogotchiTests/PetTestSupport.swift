import Foundation
import CoreData
@testable import Danogotchi


/// 정책 함수가 `now`를 인자로 받으므로 고정 시각만 있으면 된다 — Clock 추상화는 만들지 않는다.
let testBase = Date(timeIntervalSince1970: 1_700_000_000)

func hoursLater(_ hours: Double) -> Date {
    testBase.addingTimeInterval(hours * 3600)
}

/// UseCase는 내부에서 `Date()`를 쓰므로 저장소 테스트는 실제 현재 시각 기준으로 경과를 심는다.
func hoursAgo(_ hours: Double) -> Date {
    Date().addingTimeInterval(-hours * 3600)
}

/// 컨테이너마다 모델을 다시 로드하면 같은 엔티티를 여러 NSEntityDescription이 주장한다는 경고가 난다.
private let testModel = NSPersistentContainer(name: "Model").managedObjectModel

/// 테스트마다 빈 스토어를 만든다. `CoreDataStack` 싱글턴은 건드리지 않는다.
func makeInMemoryContext() -> NSManagedObjectContext {
    let container = NSPersistentContainer(name: "Model", managedObjectModel: testModel)
    let description = NSPersistentStoreDescription()
    description.type = NSInMemoryStoreType
    container.persistentStoreDescriptions = [description]
    container.loadPersistentStores { _, error in
        precondition(error == nil, "인메모리 스토어 로드 실패: \(String(describing: error))")
    }
    return container.viewContext
}

func makePet(
    name: String = "테스트",
    level: Int = 0,
    experience: Int = 0,
    satiety: Double = 100,
    hydration: Double = 100,
    fun: Double = 100,
    cleanliness: Double = 100,
    hp: Double = PetStatePolicy.maxHP,
    stateUpdatedAt: Date = testBase
) -> Pet {
    Pet(
        id: UUID(),
        type: .sprout,
        name: name,
        level: level,
        experience: experience,
        satiety: satiety,
        hydration: hydration,
        fun: fun,
        cleanliness: cleanliness,
        hp: hp,
        stateUpdatedAt: stateUpdatedAt,
        createAt: testBase
    )
}

/// 결과 종류와 무관하게 정산된 Pet을 꺼낸다 — 어느 결과든 저장 대상이다.
func petAfterCare(_ pet: Pet, _ stat: PetCareStat, _ now: Date) -> Pet {
    switch PetStatePolicy.care(pet, stat: stat, now: now) {
    case .success(let updated), .alreadyFull(let updated), .dead(let updated):
        return updated
    }
}
