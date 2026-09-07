import CoreData
import OSLog

final class CoreDataStack {
    static let shared = CoreDataStack()
    
    let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext { container.viewContext }
    
    private init() {
        container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("코어 데이터 store 로드 실패: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    func saveContext() throws {
        try viewContext.saveOrRollback()
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
