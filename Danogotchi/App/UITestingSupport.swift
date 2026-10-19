#if DEBUG
import CoreData
import Foundation

/// UI 테스트 전용 — 실행 인자로 첫 설치 상태를 만든다
enum UITestingSupport {
    /// CoreDataStack·UserInfoManager가 만들어지기 전에 호출해야 한다
    static func resetIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("-uiTestingReset") else { return }
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
        }

        let fileManager = FileManager.default
        let storePath = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("Model.sqlite").path
        for suffix in ["", "-wal", "-shm"] {
            try? fileManager.removeItem(atPath: storePath + suffix)
        }
        if let support = try? fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                              appropriateFor: nil, create: false) {
            try? fileManager.removeItem(at: support.appendingPathComponent("ThemeImage"))
        }
    }

    /// 온보딩을 건너뛰고 여행 단어장을 학습 중인 메인 화면 상태를 만든다
    static func seedMainFlowIfRequested(container: AppDIContainer) {
        guard ProcessInfo.processInfo.arguments.contains("-uiTestingMainFlow") else { return }
        do {
            try container.coreDataStack.prepareStore()
            try DatabaseSeeder.seedIfNeeded(context: container.coreDataStack.viewContext)
            try container.makeSetActiveBookUseCase().execute(topic: .travel)
            _ = try container.makeCreatePetUseCase().execute(type: .sprout, name: "테스트")
            // 없는 파일명만 지정 — 원본 URL이 없어 복구 다운로드가 일어나지 않는다
            container.userInfoManager.currentThemeImageFileName = "ui-test-theme.png"
        } catch {
            assertionFailure("UI 테스트 시드 실패: \(error)")
        }
    }
}
#endif
