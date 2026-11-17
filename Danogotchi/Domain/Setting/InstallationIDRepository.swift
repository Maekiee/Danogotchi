import Foundation

/// 이 설치를 가리키는 익명 ID. 재설치하면 새 값이 된다
protocol InstallationIDRepository {
    /// 처음 조회할 때 만들어 저장하고, 이후에는 같은 값을 돌려준다
    var installationID: String { get }
}
