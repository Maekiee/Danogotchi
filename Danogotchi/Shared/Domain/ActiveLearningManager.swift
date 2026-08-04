import Foundation
import RxSwift
import RxCocoa

final class ActiveLearningManager {
    static let shared = ActiveLearningManager()
    private let disposeBag = DisposeBag()
    private let userInfo: UserInfoManager
    let activeBook = BehaviorRelay<VocabBook?>(value: nil)

    init(
        wordBookRepo: VocabBookRepository = DefaultVocabBookRepository(
            context: CoreDataStack.shared.viewContext
        ),
        userInfo: UserInfoManager = UserInfoManager.shared
    ) {
        self.userInfo = userInfo

        // 시드 이후 모든 단어장이 DB에 있으므로 id로만 로드한다
        userInfo.activeBookIdentifierRelay
            .map { $0.flatMap { wordBookRepo.readBook(id: $0) } }
            .bind(to: activeBook)
            .disposed(by: disposeBag)
    }

    // '활성 단어장' 변경 (ViewControllers에서 호출)
    // -> 이 변경이 위 구독 로직을 트리거하여 activeBook이 자동 갱신됨
    func setActiveBook(_ book: VocabBook) {
        userInfo.activeBookIdentifier = book.id
    }
}
