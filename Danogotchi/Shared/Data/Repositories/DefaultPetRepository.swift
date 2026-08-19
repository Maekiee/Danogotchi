import Foundation
import CoreData
import OSLog

final class DefaultPetRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    /// 불변식상 1마리지만, 중복이 생겨도 항상 같은(가장 오래된) 한 마리를 보도록 정렬한다.
    private func fetchPetEntity() -> PetEntity? {
        let request = PetEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "createAt", ascending: true)
        ]
        request.fetchLimit = 1

        return try? context.fetch(request).first
    }

    /// 생성 실패를 화면까지 알려야 해서 성공 여부를 돌려준다. 나머지 호출부는 결과를 쓰지 않는다.
    @discardableResult
    private func saveContext() -> Bool {
        guard context.hasChanges else { return true }
        do {
            try context.save()
            return true
        } catch {
            AppLogger.database.error("CoreData 저장 실패: \(String(describing: error), privacy: .public)")
            CrashReporter.record(error)
            return false
        }
    }
}

extension DefaultPetRepository: PetRepository {
    /// 초기 수치는 정책 상수라 호출부가 조립한 Pet을 그대로 저장한다.
    func createPet(_ pet: Pet) -> Pet? {
        if let existing = fetchPetEntity() { return existing.toDomain() }

        let petEntity = PetEntity(context: context)
        petEntity.apply(pet)

        // 저장에 실패한 엔티티를 남기면 다음 fetch가 "이미 있음"으로 오판해 재시도가 막힌다.
        guard saveContext() else {
            context.delete(petEntity)
            return nil
        }

        return petEntity.toDomain()
    }

    func readPet() -> Pet? {
        return fetchPetEntity()?.toDomain()
    }

    func updatePet(_ pet: Pet) {
        guard let petEntity = fetchPetEntity() else { return }
        petEntity.apply(pet)
        saveContext()
    }

    /// 경험치 외 필드는 건드리지 않는다 — 미정산 경과시간(`stateUpdatedAt`)과 HP가 유실되면 안 된다.
    func addExperience(_ amount: Int) -> Int? {
        guard let petEntity = fetchPetEntity() else { return nil }
        petEntity.totalExperience += Int64(amount)
        saveContext()

        return Int(petEntity.totalExperience)
    }
}
