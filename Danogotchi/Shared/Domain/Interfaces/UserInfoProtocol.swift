import Foundation
import RxSwift

protocol UserInfoProtocol: AnyObject {
    var username: String? { get set }
    var userId: String? { get set }
    var currentThemeUrl: String? { get set }
    var isStudyReminderEnabled: Bool { get set }
    var themeUrlObservable: Observable<String?> { get }
}
