import Foundation
import RxSwift
import RxCocoa
import RealmSwift

final class AddWordViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let wordBookRepo: WordBookRepositoryProtocol
    private let wordRepo: WordRepositoryProtocol
    
    let isWordBookId: ObjectId?
    
    
    init(wordBookId: ObjectId? = nil,
         wordBookRepo: WordBookRepositoryProtocol = WordBookRepository(),
         wordRepo: WordRepositoryProtocol = WordRepository()
    ) {
        self.isWordBookId = wordBookId
        self.wordBookRepo = wordBookRepo
        self.wordRepo = wordRepo
    }
    
    
    struct Input {
        let wordBookTitleTextField: Observable<String>
        let wordTextField: Observable<String>
        let meanTextField: Observable<String>
        let selectedImage: Observable<String>
        let savedButtonTapped: Observable<Void>
    }
    
    struct Output {
        let wordImageUrl: Driver<String>
        let itemSet: Observable<(SearchPhotoDTO, String)>
        let translateWord: Driver<String>
        let isValidSave: Driver<Bool>
    }
    
    func transform(input: Input) -> Output {
        let wordImageUrl = PublishRelay<String>()
        let wordImageItems = PublishRelay<SearchPhotoDTO>()
        let wordText = PublishRelay<String>()
        let validWord = PublishRelay<String>()
        let translateWord = PublishRelay<String>()
        let isValidSaved = BehaviorRelay<Bool>(value: false)
        
        // 단어장 이름
        let wordBookTitle = input.wordBookTitleTextField
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .share()
        
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
            .do { text in
                print(text)
                wordText.accept(text)
            }.share()
        
        // 뜻
        let meanWord = input.meanTextField
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .share()
        
        
        // 이미지
        input.selectedImage
            .bind(to: wordImageUrl)
            .disposed(by: disposeBag)
        
        // 이미지 검색
        learningWord
            .flatMap{
                ApiService.searchPhoto(api: .searchPhoto(word: $0, page: 1), type: SearchPhotoDTO.self)
            }
            .bind(with: self) { owner, responseValue in
                switch responseValue {
                case .success(let value):
                    wordImageItems.accept(value)
                    wordImageUrl.accept(value.results.first!.urls.small)
                case .failure(_):
                    print("네트워크 에러")
                }
            }.disposed(by: disposeBag)
        
        // 번역 검색
        learningWord
            .flatMap {
                ApiService.searcMeaning(api: .translate(text: $0), type: TranslatedDTO.self)
            }.bind(with: self) { owner, responseValue in
                switch responseValue {
                case .success(let value):
                    translateWord.accept(value.translations.first!.text)
                case .failure(_):
                    print("네트워크 에러")
                }
            }.disposed(by: disposeBag)
        

        
        // 단어장 유효성 검사
        let allInputData = Observable.combineLatest(
            wordImageUrl,
            validWord,
            wordBookTitle,
            meanWord,
            translateWord)
        
        allInputData
            .map { title, url, word, mean, translate in
                let hasMeaning = !mean.isEmpty || !translate.isEmpty
                return !title.isEmpty && !url.isEmpty && !word.isEmpty && hasMeaning
            }.bind(with: self) { owner, isValid in
                isValidSaved.accept(isValid)
            }.disposed(by: disposeBag)
        
        // 저장 버튼
        input.savedButtonTapped
            .withLatestFrom(allInputData)
            .filter { title, url, word, mean, translate in
                let hasMeaning = !mean.isEmpty || !translate.isEmpty
                return !title.isEmpty && !url.isEmpty && !word.isEmpty && hasMeaning
            }.bind(with: self) { owner, validData in
                let (url, word, wordBookTitle, mean, _) = validData
                print("이미지>>\(url)")
                print("이미지>>\(wordBookTitle)")
                print("이미지>>\(word)")
                print("이미지>>\(mean)")
                
                
                owner.saveWord(
                    currentWordBookTitle: wordBookTitle,
                    url: url,
                    word: word,
                    meaning: mean)
            }.disposed(by: disposeBag)
        
        return Output(
            wordImageUrl: wordImageUrl.asDriver(onErrorJustReturn: ""),
            itemSet: Observable.combineLatest(wordImageItems, wordText),
            translateWord: translateWord.asDriver(onErrorJustReturn: ""),
            isValidSave: isValidSaved.asDriver(onErrorJustReturn: false)
        )
    }
    
    private func saveWord(currentWordBookTitle: String, url: String, word: String, meaning: String) {
        let wordBookId: ObjectId
        
        if let id = isWordBookId {
            //
            wordBookRepo.update(id: id, title: currentWordBookTitle)
            wordBookId = id
        } else {
            // 신규 단어장
            wordBookRepo.create(title: currentWordBookTitle)
            wordBookId = wordBookRepo.readAll().last!.id
        }
        
        let word = wordRepo.create(thumbnail: url, word: word, meaning: meaning)
        wordBookRepo.addWord(bookId: wordBookId, word: word)
    }
}
