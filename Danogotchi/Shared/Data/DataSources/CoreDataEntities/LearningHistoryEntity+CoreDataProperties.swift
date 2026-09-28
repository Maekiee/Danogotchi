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
    @NSManaged public var vocabId: UUID?
    @NSManaged public var sourceWordIdSnapshot: UUID?
    @NSManaged public var wordSnapshot: String?
    @NSManaged public var meaningSnapshot: String?
    @NSManaged public var topicSnapshot: String?
    @NSManaged public var partOfSpeechSnapshot: String?
    @NSManaged public var questionIndex: NSNumber?
    @NSManaged public var session: QuizSessionEntity?

}

extension LearningHistoryEntity : Identifiable {

}
