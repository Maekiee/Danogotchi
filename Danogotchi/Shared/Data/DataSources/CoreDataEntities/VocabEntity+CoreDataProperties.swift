public import Foundation
public import CoreData


public typealias VocabEntityCoreDataPropertiesSet = NSSet

extension VocabEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<VocabEntity> {
        return NSFetchRequest<VocabEntity>(entityName: "VocabEntity")
    }

    @NSManaged public var bookType: String?
    @NSManaged public var createAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var level: String?
    @NSManaged public var meaning: String?
    @NSManaged public var partOfSpeech: String?
    @NSManaged public var sourceWordId: UUID?
    @NSManaged public var word: String?
    @NSManaged public var histories: NSSet?
    @NSManaged public var vocabBook: VocabBookEntity?

}

// MARK: Generated accessors for histories
extension VocabEntity {

    @objc(addHistoriesObject:)
    @NSManaged public func addToHistories(_ value: LearningHistoryEntity)

    @objc(removeHistoriesObject:)
    @NSManaged public func removeFromHistories(_ value: LearningHistoryEntity)

    @objc(addHistories:)
    @NSManaged public func addToHistories(_ values: NSSet)

    @objc(removeHistories:)
    @NSManaged public func removeFromHistories(_ values: NSSet)

}

extension VocabEntity : Identifiable {

}
