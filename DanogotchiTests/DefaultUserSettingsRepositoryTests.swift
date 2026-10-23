import XCTest
@testable import Danogotchi

final class DefaultUserSettingsRepositoryTests: XCTestCase {
    private let suiteName = "UserSettingsTests.\(UUID().uuidString)"

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    /// 실제 앱 설정을 건드리지 않도록 테스트 전용 suite를 쓴다
    private func makeDefaults() throws -> UserDefaults {
        try XCTUnwrap(UserDefaults(suiteName: suiteName))
    }

    func test_firstLaunchDefaults() throws {
        let repository = DefaultUserSettingsRepository(defaults: try makeDefaults())

        XCTAssertNil(repository.currentThemeUrl)
        XCTAssertNil(repository.currentThemeImageFileName)
        XCTAssertFalse(repository.hasSelectedTheme)
        XCTAssertTrue(repository.isStudyReminderEnabled, "키가 없는 첫 실행은 알림이 켜진 것으로 본다")
    }

    func test_valuesPersistAcrossInstancesUnderStableKeys() throws {
        let defaults = try makeDefaults()
        let writer = DefaultUserSettingsRepository(defaults: defaults)
        writer.currentThemeUrl = "https://images.example.test/a"
        writer.currentThemeImageFileName = "a.heic"
        writer.isStudyReminderEnabled = false

        // 기존 사용자 데이터와 호환되려면 키 문자열이 바뀌면 안 된다
        XCTAssertEqual(defaults.string(forKey: "themeUrl"), "https://images.example.test/a")
        XCTAssertEqual(defaults.string(forKey: "themeImageFileName"), "a.heic")
        XCTAssertEqual(defaults.object(forKey: "studyReminderEnabled") as? Bool, false)

        let reader = DefaultUserSettingsRepository(defaults: defaults)
        XCTAssertEqual(reader.currentThemeUrl, "https://images.example.test/a")
        XCTAssertEqual(reader.currentThemeImageFileName, "a.heic")
        XCTAssertFalse(reader.isStudyReminderEnabled)
        XCTAssertTrue(reader.hasSelectedTheme)
    }

    func test_fileNameStreamStartsWithCurrentValueThenFollowsChanges() async throws {
        let repository = DefaultUserSettingsRepository(defaults: try makeDefaults())
        repository.currentThemeImageFileName = "first.heic"

        var iterator = repository.themeImageFileNameChanges.makeAsyncIterator()
        let initial = await iterator.next()
        XCTAssertEqual(initial, .some("first.heic"), "구독 즉시 저장된 값을 보낸다")

        repository.currentThemeImageFileName = "second.heic"
        let changed = await iterator.next()
        XCTAssertEqual(changed, .some("second.heic"))

        repository.currentThemeImageFileName = nil
        let cleared = await iterator.next()
        XCTAssertEqual(cleared, .some(nil), "파일이 사라진 상태도 그대로 흘린다")
    }

    func test_themeUrlChangeDoesNotEmitOnFileNameStream() async throws {
        let repository = DefaultUserSettingsRepository(defaults: try makeDefaults())
        var iterator = repository.themeImageFileNameChanges.makeAsyncIterator()
        _ = await iterator.next()

        repository.currentThemeUrl = "https://images.example.test/b"
        repository.currentThemeImageFileName = "b.heic"

        // URL 변경은 스트림 대상이 아니므로 다음 값은 파일명이다
        let next = await iterator.next()
        XCTAssertEqual(next, .some("b.heic"))
    }
}
