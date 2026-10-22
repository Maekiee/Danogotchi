import CoreData
import OSLog

final class CoreDataStack {
    private let container: NSPersistentContainer
    private var isPrepared = false

    var viewContext: NSManagedObjectContext { container.viewContext }

    init() {
        container = NSPersistentContainer(name: "Model")
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        return container.newBackgroundContext()
    }

    func prepareStore() throws {
        guard !isPrepared else { return }
        if container.persistentStoreCoordinator.persistentStores.isEmpty {
            for description in container.persistentStoreDescriptions {
                if let url = description.url, description.type == NSSQLiteStoreType {
                    try StudyReportMigration.preflight(storeURL: url, destinationModel: container.managedObjectModel)
                }
                description.shouldAddStoreAsynchronously = false
                description.shouldMigrateStoreAutomatically = true
                description.shouldInferMappingModelAutomatically = true
            }
            var loadError: Error?
            container.loadPersistentStores { _, error in loadError = error }
            if let loadError { throw loadError }
        }
        try StudyReportMigration.backfillIfNeeded(context: viewContext)
        isPrepared = true
    }
}

extension NSManagedObjectContext {
    /// Repository 작업은 동기적으로 저장까지 마친다. 실패한 변경을 다음 저장에 섞지 않는다.
    func saveOrRollback() throws {
        guard hasChanges else { return }
        do {
            try save()
        } catch {
            rollback()
            AppLogger.database.error("CoreData 저장 실패: \(String(describing: error), privacy: .public)")
            CrashReporter.record(error)
            throw error
        }
    }
}
