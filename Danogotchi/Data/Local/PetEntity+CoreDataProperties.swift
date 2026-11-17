public import Foundation
public import CoreData


public typealias PetEntityCoreDataPropertiesSet = NSSet

extension PetEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PetEntity> {
        return NSFetchRequest<PetEntity>(entityName: "PetEntity")
    }

    @NSManaged public var cleanliness: Double
    @NSManaged public var createAt: Date?
    @NSManaged public var fun: Double
    @NSManaged public var hp: Double
    @NSManaged public var hydration: Double
    @NSManaged public var id: UUID?
    @NSManaged public var level: Int64
    @NSManaged public var name: String?
    @NSManaged public var satiety: Double
    @NSManaged public var stateUpdatedAt: Date?
    @NSManaged public var totalExperience: Int64
    @NSManaged public var type: String?

}

extension PetEntity : Identifiable {

}
