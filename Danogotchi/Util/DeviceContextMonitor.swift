import Foundation
import Network

/// 네트워크 종류·저전력 모드를 Crashlytics key로 계속 갱신한다. 앱 전체에서 한 번만 시작한다
enum DeviceContextMonitor {
    private static let pathMonitor = NWPathMonitor()
    private static var lowPowerObserver: NSObjectProtocol?

    static func start() {
        guard lowPowerObserver == nil else { return }

        pathMonitor.pathUpdateHandler = { path in
            CrashReporter.setValue(networkType(path), for: .networkType)
        }
        pathMonitor.start(queue: DispatchQueue(label: "DeviceContextMonitor.path"))

        CrashReporter.setValue(ProcessInfo.processInfo.isLowPowerModeEnabled, for: .lowPowerMode)
        lowPowerObserver = NotificationCenter.default.addObserver(
            forName: .NSProcessInfoPowerStateDidChange, object: nil, queue: nil
        ) { _ in
            CrashReporter.setValue(ProcessInfo.processInfo.isLowPowerModeEnabled, for: .lowPowerMode)
        }
    }

    private static func networkType(_ path: NWPath) -> String {
        guard path.status == .satisfied else { return "none" }
        if path.usesInterfaceType(.wifi) { return "wifi" }
        if path.usesInterfaceType(.cellular) { return "cellular" }
        if path.usesInterfaceType(.wiredEthernet) { return "wired" }
        return "other"
    }
}
