public import Foundation
public import CoreData


public typealias VocabBookEntityCoreDataPropertiesSet = NSSet

extension VocabBookEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<VocabBookEntity> {
        return NSFetchRequest<VocabBookEntity>(entityName: "VocabBookEntity")
    }

    @NSManaged public var bookType: String?
    @NSManaged public var createAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var isActive: Bool
    @NSManaged public var level: String?
    @NSManaged public var title: String?
    @NSManaged public var vocabs: NSSet?

}

// MARK: Generated accessors for vocabs
extension VocabBookEntity {

    @objc(addVocabsObject:)
    @NSManaged public func addToVocabs(_ value: VocabEntity)

    @objc(removeVocabsObject:)
    @NSManaged public func removeFromVocabs(_ value: VocabEntity)

    @objc(addVocabs:)
    @NSManaged public func addToVocabs(_ values: NSSet)

    @objc(removeVocabs:)
    @NSManaged public func removeFromVocabs(_ values: NSSet)

}

extension VocabBookEntity : Identifiable {

}
