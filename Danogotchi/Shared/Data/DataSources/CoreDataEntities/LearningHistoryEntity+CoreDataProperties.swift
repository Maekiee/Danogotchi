public import Foundation
public import CoreData


public typealias LearningHistoryEntityCoreDataPropertiesSet = NSSet

extension LearningHistoryEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LearningHistoryEntity> {
        return NSFetchRequest<LearningHistoryEntity>(entityName: "LearningHistoryEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var isCorrect: Bool
    @NSManaged public var createAt: Date?
    @NSManaged public var vocab: VocabEntity?

}

extension LearningHistoryEntity : Identifiable {

}
