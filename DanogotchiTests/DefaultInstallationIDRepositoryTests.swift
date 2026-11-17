import XCTest
@testable import Danogotchi

final class DefaultInstallationIDRepositoryTests: XCTestCase {
    private let suiteName = "InstallationIDTests.\(UUID().uuidString)"

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    /// 실제 앱 설정을 건드리지 않도록 테스트 전용 suite를 쓴다
    private func makeDefaults() throws -> UserDefaults {
        try XCTUnwrap(UserDefaults(suiteName: suiteName))
    }

    func test_idIsCreatedOnceAndStaysTheSameAcrossInstances() throws {
        let defaults = try makeDefaults()
        let first = DefaultInstallationIDRepository(defaults: defaults).installationID

        XCTAssertNotNil(UUID(uuidString: first))
        XCTAssertEqual(DefaultInstallationIDRepository(defaults: defaults).installationID, first)
    }

    /// 재설치처럼 저장소가 비면 새 ID가 된다
    func test_clearedStorageCreatesNewID() throws {
        let defaults = try makeDefaults()
        let before = DefaultInstallationIDRepository(defaults: defaults).installationID

        defaults.removePersistentDomain(forName: suiteName)

        XCTAssertNotEqual(DefaultInstallationIDRepository(defaults: defaults).installationID, before)
    }
}
