import Foundation

final class CoreDataPreparer: DatabasePreparing {
    private let stack: CoreDataStack

    init(stack: CoreDataStack) {
        self.stack = stack
    }

    func prepareIfNeeded() throws {
        try stack.prepareStore()
        try DatabaseSeeder.seedIfNeeded(context: stack.viewContext)
    }
}
