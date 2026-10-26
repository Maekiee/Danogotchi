#if DEBUG
import CoreData
import Foundation
import UIKit

/// UI 테스트 전용 — 실행 인자로 첫 설치 상태를 만든다
enum UITestingSupport {
    /// AppDIContainer가 만들어지기 전에 호출해야 한다
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
            try container.seedMainFlowForUITesting()
        } catch {
            assertionFailure("UI 테스트 시드 실패: \(error)")
        }
    }

    /// 테마만 고른 상태(펫 없음)를 만든다 — 온보딩이 알 선택 화면부터 이어진다
    static func seedThemeSelectedIfRequested(container: AppDIContainer) {
        guard ProcessInfo.processInfo.arguments.contains("-uiTestingThemeSelected") else { return }
        do {
            try container.seedThemeSelectedForUITesting()
        } catch {
            assertionFailure("UI 테스트 시드 실패: \(error)")
        }
    }

    /// 단색 이미지를 실제 테마 파일로 깐다 — 화면 모드가 바뀌어도 카드 뒤 배경이 같아야 하는 테스트용
    static func seedSolidThemeIfRequested(container: AppDIContainer) {
        guard ProcessInfo.processInfo.arguments.contains("-uiTestingSolidTheme") else { return }
        let size = CGSize(width: 10, height: 20)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            UIColor(red: 0.2, green: 0.45, blue: 0.75, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        do {
            guard let data = image.pngData() else { throw CocoaError(.fileWriteUnknown) }
            try container.seedThemeImageForUITesting(data)
        } catch {
            assertionFailure("UI 테스트 시드 실패: \(error)")
        }
    }
}
#endif
