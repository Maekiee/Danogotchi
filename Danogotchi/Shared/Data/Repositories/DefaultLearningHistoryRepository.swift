import CoreData

final class DefaultLearningHistoryRepository: LearningHistoryRepository {
    private let context: NSManagedObjectContext
    private let reportContext: NSManagedObjectContext

    init(context: NSManagedObjectContext, reportContext: NSManagedObjectContext? = nil) {
        self.context = context
        self.reportContext = reportContext ?? context
    }

    func addHistory(_ answer: QuizAnswer) throws {
        try context.performAndWait {
            let previousPolicy = context.mergePolicy
            context.mergePolicy = NSErrorMergePolicy
            defer { context.mergePolicy = previousPolicy }
            do {
                let value = answer.history
                guard answer.session.questionCount > 0,
                      let index = value.questionIndex,
                      (0..<answer.session.questionCount).contains(index),
                      value.sessionId == answer.session.id else {
                    throw StudyReportDataError.invalidRecord
                }
                let sessionRequest = QuizSessionEntity.fetchRequest()
                sessionRequest.predicate = NSPredicate(format: "id == %@", answer.session.id as CVarArg)
                let sessions = try context.fetch(sessionRequest)
                guard sessions.count <= 1 else { throw StudyReportDataError.invalidIdentifiers }
                if let session = sessions.first, try session.toDomain() != answer.session {
                    throw StudyReportDataError.conflictingSession
                }

                let request = LearningHistoryEntity.fetchRequest()
                request.predicate = NSPredicate(
                    format: "id == %@ OR (session.id == %@ AND questionIndex == %lld)",
                    value.id as CVarArg, answer.session.id as CVarArg, Int64(index)
                )
                let matches = try context.fetch(request)
                if !matches.isEmpty {
                    guard matches.count == 1, try matches[0].toDomain() == value else {
                        throw StudyReportDataError.conflictingAnswer
                    }
                    return
                }

                let wordRequest = VocabEntity.fetchRequest()
                wordRequest.predicate = NSPredicate(format: "id == %@", value.vocabId as CVarArg)
                wordRequest.fetchLimit = 1
                guard let word = try context.fetch(wordRequest).first else {
                    throw PersistenceError.entityNotFound
                }
                let session = sessions.first ?? QuizSessionEntity(context: context)
                session.id = answer.session.id
                session.startedAt = answer.session.startedAt
                session.questionCount = Int64(answer.session.questionCount)

                let history = LearningHistoryEntity(context: context)
                history.id = value.id
                history.vocabId = value.vocabId
                history.vocab = word
                history.isCorrect = value.isCorrect
                history.createAt = value.createAt
                history.sourceWordIdSnapshot = value.sourceWordIdSnapshot
                history.wordSnapshot = value.wordSnapshot
                history.meaningSnapshot = value.meaningSnapshot
                history.topicSnapshot = value.topicSnapshot
                history.partOfSpeechSnapshot = value.partOfSpeechSnapshot
                history.questionIndex = NSNumber(value: index)
                history.session = session
                try context.saveOrRollback()
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    func fetchAllHistory() throws -> [LearningHistory] {
        try context.performAndWait {
            try context.fetch(Self.historyRequest()).map { try $0.toDomain() }
        }
    }

    func fetchHistory(vocabId: UUID) throws -> [LearningHistory] {
        try context.performAndWait {
            let request = Self.historyRequest()
            request.predicate = NSPredicate(format: "vocabId == %@", vocabId as CVarArg)
            return try context.fetch(request).map { try $0.toDomain() }
        }
    }

    func accuracy(vocabId: UUID) throws -> Double? {
        let histories = try fetchHistory(vocabId: vocabId)
        guard !histories.isEmpty else { return nil }
        return Double(histories.filter(\.isCorrect).count) / Double(histories.count)
    }

    func fetchReportRecords() async throws -> StudyReportRecords {
        let context = reportContext
        return try await context.perform {
            try Task.checkCancellation()
            // 전용 읽기 context의 두 조회를 같은 저장소 시점에 고정
            if context.concurrencyType == .privateQueueConcurrencyType {
                context.reset()
                try context.setQueryGenerationFrom(.current)
            }
            let histories = try context.fetch(Self.historyRequest()).map { try $0.toDomain() }
            let sessions = try context.fetch(QuizSessionEntity.fetchRequest()).map { try $0.toDomain() }
            return StudyReportRecords(histories: histories, sessions: sessions)
        }
    }

    private static func historyRequest() -> NSFetchRequest<LearningHistoryEntity> {
        let request = LearningHistoryEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createAt", ascending: true)]
        return request
    }
}
