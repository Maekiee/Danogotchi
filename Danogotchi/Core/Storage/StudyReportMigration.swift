import CoreData

enum StudyReportMigration {
    private static let backfillVersionKey = "com.maekie.Danogotchi.studyReportBackfillVersion"
    private static let backfillVersion = 1

    static func preflight(storeURL: URL, destinationModel: NSManagedObjectModel) throws {
        guard FileManager.default.fileExists(atPath: storeURL.path) else { return }
        let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
            ofType: NSSQLiteStoreType, at: storeURL, options: [NSReadOnlyPersistentStoreOption: true]
        )
        guard !destinationModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) else { return }
        guard let sourceModel = NSManagedObjectModel.mergedModel(
            from: [Bundle(for: LearningHistoryEntity.self)], forStoreMetadata: metadata
        ) else { throw StudyReportDataError.invalidRecord }

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: sourceModel)
        let store = try coordinator.addPersistentStore(
            ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL,
            options: [NSReadOnlyPersistentStoreOption: true]
        )
        defer { try? coordinator.remove(store) }
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        try context.performAndWait {
            for name in ["LearningHistoryEntity", "QuizSessionEntity"] where sourceModel.entitiesByName[name] != nil {
                try validateIdentifiers(entityName: name, context: context)
            }
        }
        _ = try NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: destinationModel)
    }

    static func validateIdentifiers(entityName: String, context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        let records = try context.fetch(request)
        var ids = Set<UUID>()
        for record in records {
            guard let id = record.value(forKey: "id") as? UUID, ids.insert(id).inserted else {
                throw StudyReportDataError.invalidIdentifiers
            }
        }
    }

    static func backfillIfNeeded(context: NSManagedObjectContext) throws {
        try context.performAndWait {
            guard let coordinator = context.persistentStoreCoordinator,
                  let store = coordinator.persistentStores.first else {
                throw StudyReportDataError.invalidRecord
            }
            let version = coordinator.metadata(for: store)[backfillVersionKey] as? Int ?? 0
            guard version < backfillVersion else { return }

            try backfill(context: context)
            let previousMetadata = coordinator.metadata(for: store)
            var metadata = previousMetadata
            metadata[backfillVersionKey] = backfillVersion
            coordinator.setMetadata(metadata, for: store)
            do {
                // 레코드 변경이 없어도 완료 메타데이터 저장
                try context.save()
            } catch {
                context.rollback()
                coordinator.setMetadata(previousMetadata, for: store)
                throw error
            }
        }
    }

    static func backfill(context: NSManagedObjectContext) throws {
        try context.performAndWait {
            do {
                try validateIdentifiers(entityName: "LearningHistoryEntity", context: context)
                try validateIdentifiers(entityName: "QuizSessionEntity", context: context)
                let words = try context.fetch(VocabEntity.fetchRequest())
                var topicsByID: [UUID: String] = [:]
                for word in words {
                    if let id = word.id, let topic = topicIdentifier(word.bookType) {
                        topicsByID[id] = topic
                    }
                }
                for word in words where word.originalTopic == nil {
                    word.originalTopic = word.sourceWordId.flatMap { topicsByID[$0] }
                        ?? topicIdentifier(word.bookType)
                }
                let request = LearningHistoryEntity.fetchRequest()
                request.predicate = NSPredicate(format: "vocabId == nil")
                for history in try context.fetch(request) {
                    guard let word = history.vocab, let id = word.id,
                          let name = word.word, let meaning = word.meaning,
                          history.createAt != nil else {
                        throw StudyReportDataError.invalidRecord
                    }
                    history.sourceWordIdSnapshot = word.sourceWordId
                    history.wordSnapshot = name
                    history.meaningSnapshot = meaning
                    history.topicSnapshot = topicIdentifier(word.originalTopic) ?? topicIdentifier(word.bookType)
                    history.partOfSpeechSnapshot = partIdentifier(word.partOfSpeech)
                    // 독립 ID를 보강 완료 표시로 사용해 기존 스냅샷 유지
                    history.vocabId = id
                }
                try context.saveOrRollback()
            } catch {
                context.rollback()
                throw error
            }
        }
    }

    private static func topicIdentifier(_ value: String?) -> String? {
        switch value {
        case "travel", "Travel", "여행": return "travel"
        case "business", "Business", "비즈니스": return "business"
        case "emotion", "Emotion", "감정": return "emotion"
        case "life", "Life", "daily", "일상": return "life"
        default: return nil
        }
    }

    private static func partIdentifier(_ value: String?) -> String? {
        switch value {
        case "noun", "Noun", "명사": return "noun"
        case "verb", "Verb", "동사": return "verb"
        case "adj", "Adj.", "adjective", "형용사": return "adj"
        case "adv", "Adv.", "adverb", "부사": return "adv"
        default: return nil
        }
    }
}
