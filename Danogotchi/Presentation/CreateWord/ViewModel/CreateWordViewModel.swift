import Foundation
import RxSwift
import RxCocoa
import RealmSwift

final class CreateWordViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    
    private let wordItem: CreateWord?
    private let wordBookRepository: WordBookRepository
    private let wordRepository: WordRepository
    private let userInfoManager = UserInfoManager.shared
    
    private var isWordBookId: ObjectId?
    
    
    
    init(
        wordItem: CreateWord? = nil,
        wordBookRepository: WordBookRepository,
        wordRepository: WordRepository
    ) {
        self.wordItem = wordItem
        self.wordBookRepository = wordBookRepository
        self.wordRepository = wordRepository
    }
    
    
    struct Input {
        let wordBookTitleTextField: Observable<String>
        let wordTextField: Observable<String>
        let meanTextField: Observable<String>
        let savedButtonTapped: Observable<Void>
    }
    
    struct Output {
        let translateWord: Driver<String>
        let isValidSave: Driver<Bool>
        let resetTrigger: Signal<Void>
        let bookTitle: Driver<String>
        let meanText: Driver<String>
        let wordTextFieldText: Driver<String>
    }
    
    func transform(input: Input) -> Output {
        let validWord = BehaviorRelay<String>(value: "")
        let translatedWord = BehaviorRelay<String>(value: "")
        let isValidSaved = BehaviorRelay<Bool>(value: false)
        let meanText = BehaviorRelay<String>(value: "")
        let resetTrigger = PublishRelay<Void>()
        let bookTitleText = BehaviorRelay<String>(value: "")
        let actionType = BehaviorRelay<EntryPoint>(value: .add)
        
        if let item = wordItem {
            bookTitleText.accept(item.bookTitle)
            validWord.accept(item.word)
            meanText.accept(item.meaning)
            actionType.accept(item.actionType)
        }
        
        // 단어장 이름
        let wordBookTitle = Observable.merge(
            bookTitleText.asObservable(),
            input.wordBookTitleTextField
                .skip(1)
        )
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .share(replay: 1, scope: .whileConnected)
        
        
        
        // 단어
        let learningWord = input.wordTextField
            .skip(1)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .do { text in
                validWord.accept(text)
            }
            .filter{ $0.count >= 2 }
            .distinctUntilChanged()
            .debounce(.seconds(2), scheduler: MainScheduler.instance)
            .share()
        
        // 뜻
        input.meanTextField
            .filter { !$0.isEmpty }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .bind(to: meanText)
            .disposed(by: disposeBag)
        
        
        // 번역 검색
        learningWord
            .flatMap {
                ApiService.searcMeaning(api: .translate(text: $0), type: TranslatedDTO.self)
            }.bind(with: self) { owner, responseValue in
                switch responseValue {
                case .success(let value):
                    translatedWord.accept(value.translations.first!.text)
                case .failure(_):
                    print("네트워크 에러")
                }
            }.disposed(by: disposeBag)
        
        // 단어장 유효성 검사
        let allInputData = Observable.combineLatest(
            validWord,
//            wordBookTitle,
            meanText,
            translatedWord)
        
        allInputData
            .map {  word, mean, translate in
                let hasMeaning = !mean.isEmpty || !translate.isEmpty
                let hasWord = !word.isEmpty
                return hasWord && hasMeaning
//                return !title.isEmpty && !url.isEmpty && !word.isEmpty && hasMeaning
            }.bind(to: isValidSaved)
            .disposed(by: disposeBag)
        
        // 저장 버튼
        input.savedButtonTapped
            .withLatestFrom(allInputData)
            .bind(with: self) { owner, validData in
//                let (imageUrl, word, bookTitle, mean, translate) = validData
//                let finalMeaning = !mean.isEmpty ? mean : translate
                
                let (word, mean, translate) = validData
                let finalMeaning = !mean.isEmpty ? mean : translate
             
                let actionType = actionType.value
                
                owner.saveWord(
                    actionType: actionType,
                    wordBookTitle: "나의 단어장",
                    word: word,
                    meaning: finalMeaning)
                
                meanText.accept("")
                translatedWord.accept("")
                resetTrigger.accept(())
            }.disposed(by: disposeBag)
        
        return Output(
            translateWord: translatedWord.asDriver(onErrorJustReturn: ""),
            isValidSave: isValidSaved.asDriver(),
            resetTrigger: resetTrigger.asSignal(),
            bookTitle: bookTitleText.asDriver(onErrorJustReturn: ""),
            meanText: meanText.asDriver(onErrorJustReturn: ""),
            wordTextFieldText: validWord.asDriver(onErrorJustReturn: "")
        )
    }
    
    private func saveWord(actionType: EntryPoint, wordBookTitle: String, word: String, meaning: String) {
        let bookObjectId: ObjectId
        
        
        if let bookId = wordItem?.wordBookId {
            // 기존 단어장 타이틀 업데이트
//            wordBookRepo.update(id: bookId, title: wordBookTitle)
            bookObjectId = bookId
        } else {
//            // 신규 단어장 생성
//            wordBookRepo.create(title: wordBookTitle)
//            // 새 단어장 불러오기
//            guard let newBook = wordBookRepo.readAll().last else { return }
//            
//            bookObjectId = try! ObjectId(string: newBook.id) // ObjectId로 변경해서 값 할당
//            self.isWordBookId = bookObjectId
//            userInfoManager.selectedBookId = newBook.id
            
            guard let bookId = wordItem?.wordBookId else {
                print("Error: wordBookId가 없습니다.")
                return
            }
            bookObjectId = bookId
        }
        
        switch actionType {
            // 단어 추가 로직
        case .add:
            let newWord = wordRepository.create(word: word, meaning: meaning)
            wordBookRepository.addWord(bookId: bookObjectId, word: newWord)
            userInfoManager.notifyWordBookUpdate()
            // 단어 수정 ㅇ로직
        case .edit:
            // 단어 수정
            guard let wordId = wordItem?.wordId else { return }
            wordRepository.update(id: wordId, word: word, meaning: meaning)
            userInfoManager.notifyWordBookUpdate()
        }
        
        
    }
}
