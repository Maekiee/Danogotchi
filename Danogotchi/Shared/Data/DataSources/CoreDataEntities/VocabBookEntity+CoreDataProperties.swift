public import Foundation
public import CoreData


public typealias VocabBookEntityCoreDataPropertiesSet = NSSet

extension VocabBookEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<VocabBookEntity> {
        return NSFetchRequest<VocabBookEntity>(entityName: "VocabBookEntity")
    }

    @NSManaged public var createAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var originBookId: String?
    @NSManaged public var type: String?
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
