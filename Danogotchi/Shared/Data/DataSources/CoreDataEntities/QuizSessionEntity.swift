import CoreData

@objc(QuizSessionEntity)
public class QuizSessionEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var startedAt: Date?
    @NSManaged public var questionCount: Int64
    @NSManaged public var histories: NSSet?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<QuizSessionEntity> {
        NSFetchRequest<QuizSessionEntity>(entityName: "QuizSessionEntity")
    }

    func toDomain() throws -> QuizSession {
        guard let id, let startedAt else {
            throw StudyReportDataError.invalidRecord
        }
        return QuizSession(id: id, startedAt: startedAt, questionCount: Int(questionCount))
    }
}
