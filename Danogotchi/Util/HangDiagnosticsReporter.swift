import Foundation
import MetricKit

/// MetricKit hang 진단을 Crashlytics non-fatal로 보낸다 — Crashlytics SDK는 hang을 직접 수집하지 않는다
/// crash 진단은 Crashlytics와 겹치고, MXMetricPayload(실행 시간·종료 사유)는 Amplitude 도입 때 다룬다
final class HangDiagnosticsReporter: NSObject, MXMetricManagerSubscriber {
    static let shared = HangDiagnosticsReporter()

    override private init() {
        super.init()
    }

    /// 앱 시작 때 한 번만 부른다
    func start() {
        MXMetricManager.shared.add(self)
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for hang in payloads.flatMap({ $0.hangDiagnostics ?? [] }) {
            CrashReporter.record(Self.error(hangDuration: hang.hangDuration, buildVersion: hang.metaData.applicationBuildVersion))
        }
    }

    /// 모든 hang을 한 이슈로 묶는다 — 시간·빌드는 고유 값이라 userInfo에 둔다
    static func error(hangDuration: Measurement<UnitDuration>, buildVersion: String) -> NSError {
        NSError(domain: "danogotchi.metrickit.hang", code: 0, userInfo: [
            CrashReporter.InfoKey.hangDurationMs: Int(hangDuration.converted(to: .milliseconds).value.rounded()),
            CrashReporter.InfoKey.appBuildVersion: buildVersion
        ])
    }
}
