import Foundation
import RxSwift

/// UserDefaults 기반 사용자 설정에 대한 도메인 인터페이스.
/// UseCase가 `private let`으로 보유한 채 값을 갱신하므로 참조 타입으로 제한한다.
protocol UserInfoProtocol: AnyObject {
    var username: String? { get set }
    var userId: String? { get set }
    var currentThemeUrl: String? { get set }
    var themeUrlObservable: Observable<String?> { get }
}
