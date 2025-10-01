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
        let meanText = BehaviorRelay<String>(value: "")
        
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
                wordText.accept(text)
            }.share()
        
        // 뜻
        input.meanTextField
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .bind(to: meanText)
            .disposed(by: disposeBag)
        
        
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
            meanText,
            translateWord)
        
        allInputData
            .map { title, url, word, mean, translate in
                let hasMeaning = !mean.isEmpty || !translate.isEmpty
                return !title.isEmpty && !url.isEmpty && !word.isEmpty && hasMeaning
            }.bind(to: isValidSaved)
            .disposed(by: disposeBag)
        
        // 저장 버튼
        input.savedButtonTapped
            .withLatestFrom(allInputData)
            .bind(with: self) { owner, validData in
                let (url, word, wordBookTitle, mean, translateWord) = validData
                let finalMeaning = !mean.isEmpty ? mean : translateWord
                
                print("이미지>>\(url)")
                print("단어장 타이틀>>\(wordBookTitle)")
                print("단어>>\(word)")
                print("최종뜻>> \(finalMeaning)")
                //
//                owner.saveWord(
//                    wordBookTitle: wordBookTitle,
//                    url: url,
//                    word: word,
//                    meaning: finalMeaning)
                
            }.disposed(by: disposeBag)
        
        return Output(
            wordImageUrl: wordImageUrl.asDriver(onErrorJustReturn: ""),
            itemSet: Observable.combineLatest(wordImageItems, wordText),
            translateWord: translateWord.asDriver(onErrorJustReturn: ""),
            isValidSave: isValidSaved.asDriver()
        )
    }
    
    private func saveWord(wordBookTitle: String, url: String, word: String, meaning: String) {
        let wordBookId: ObjectId
        
        if let id = isWordBookId {
            // 기존 단어장 타이틀 업데이트
            wordBookRepo.update(id: id, title: wordBookTitle)
            wordBookId = id
        } else {
            // 신규 단어장
            wordBookRepo.create(title: wordBookTitle)
            wordBookId = wordBookRepo.readAll().last!.id
        }
        
        let newWord = wordRepo.create(thumbnail: url, word: word, meaning: meaning)
        wordBookRepo.addWord(bookId: wordBookId, word: newWord)
    }
}
