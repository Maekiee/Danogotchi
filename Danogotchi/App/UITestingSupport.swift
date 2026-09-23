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
}
#endif
