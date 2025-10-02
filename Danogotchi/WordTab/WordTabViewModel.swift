import Foundation
import RxSwift
import RxCocoa
import RealmSwift


final class WordTabViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let userInfo = UserInfoManager.shared
    
    private let wordBookRepo: WordBookRepositoryProtocol
    private let wordRepo: WordRepositoryProtocol
    
    init(
        wordBookRepo: WordBookRepositoryProtocol = WordBookRepository(),
        wordRepo: WordRepositoryProtocol = WordRepository()) {
            self.wordBookRepo = wordBookRepo
            self.wordRepo = wordRepo
    }
    
    struct Input {
        let viewWillAppear: Observable<Void>
    }
    
    struct Output {
        let selectedWordBookId: Driver<Bool>
    }
    
    func transform(input: Input) -> Output {
        let selectedWordBook = BehaviorRelay(value: true)
        if let wordBookId = userInfo.selectedWordBook,
           let bookId = try? ObjectId(string: wordBookId) {
            // 선택된 단어장이 이미 있으면 선택된 단어장 불러오기
            let wordList = wordBookRepo.fetchWordsInWordBook(id: bookId)
            print("단어 리스트>>>\(wordList)")
            selectedWordBook.accept(false)
        } else {
            print("유저 디볼트에 값이 없나요?")
            selectedWordBook.accept(true)
        }
        
        
        input.viewWillAppear
            .skip(1)
            .bind(with: self) { owner, _ in
                let allWordBook = owner.wordBookRepo.readAll()
                if allWordBook.isEmpty {
                    print("단어장 없음")
                    selectedWordBook.accept(true)
                } else {
                    print("단어장 있음")
                    selectedWordBook.accept(false)
                }
            }.disposed(by: disposeBag)
        
        
        return Output(
            selectedWordBookId: selectedWordBook.asDriver()
        )
    }
}
