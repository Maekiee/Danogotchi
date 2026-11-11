import Foundation
import CoreData

final class DefaultPetRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    /// 불변식상 1마리지만, 중복이 생겨도 항상 같은(가장 오래된) 한 마리를 보도록 정렬한다.
    private func fetchPetEntity() throws -> PetEntity? {
        let request = PetEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "createAt", ascending: true)
        ]
        request.fetchLimit = 1

        return try context.fetch(request).first
    }

}

extension DefaultPetRepository: PetRepository {
    /// 초기 수치는 정책 상수라 호출부가 조립한 Pet을 그대로 저장한다.
    func createPet(_ pet: Pet) throws -> Pet? {
        if let existing = try fetchPetEntity() { return existing.toDomain() }

        let petEntity = PetEntity(context: context)
        petEntity.apply(pet)

        try context.saveOrRollback()

        return petEntity.toDomain()
    }

    func readPet() throws -> Pet? {
        return try fetchPetEntity()?.toDomain()
    }

    func updatePet(_ pet: Pet) throws {
        guard let petEntity = try fetchPetEntity() else { throw PersistenceError.entityNotFound }
        petEntity.apply(pet)
        try context.saveOrRollback()
    }

    /// 경험치 외 필드는 건드리지 않는다 — 미정산 경과시간(`stateUpdatedAt`)과 HP가 유실되면 안 된다.
    func addExperience(_ amount: Int) throws -> Int? {
        guard let petEntity = try fetchPetEntity() else { throw PersistenceError.entityNotFound }
        petEntity.totalExperience += Int64(amount)
        try context.saveOrRollback()

        return Int(petEntity.totalExperience)
    }
}
