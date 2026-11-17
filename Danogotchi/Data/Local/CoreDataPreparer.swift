import Foundation

final class CoreDataPreparer: DatabasePreparing {
    private let stack: CoreDataStack

    init(stack: CoreDataStack) {
        self.stack = stack
    }

    /// preflight·backfill은 조립부가 스택에 넘긴 클로저가 단계를 붙인다 — 나머지 스택 실패는 스토어 로드다
    func prepareIfNeeded() throws {
        try DatabasePreparationError.tagging(.loadStore) { try stack.prepareStore() }
        try DatabasePreparationError.tagging(.seed) { try DatabaseSeeder.seedIfNeeded(context: stack.viewContext) }
    }
}
