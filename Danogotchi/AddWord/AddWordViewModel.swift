import Foundation
import RxSwift
import RxCocoa

final class AddWordViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    
    struct Input {
        let wordBookTitleTextField: Observable<String>
        let wordTextField: Observable<String>
        let meanTextField: Observable<String>
        let selectedImage: Observable<String>
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
        let translateWord = PublishRelay<String>()
//        let isValidSave = BehaviorRelay<Bool>(value: false)
        
        
        // 단어장 이름
        let wordBookTitle = input.wordBookTitleTextField
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .share()
        
        // 단어
        let learningWord = input.wordTextField
            .skip(1)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter{ $0.count >= 2 }
            .distinctUntilChanged()
            .debounce(.seconds(2), scheduler: MainScheduler.instance)
            .do { text in
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
        
        
        let isValidSave = Observable.combineLatest(
            wordBookTitle,
            learningWord.startWith(""),
            meanWord.startWith(""),
            translateWord.startWith(""),
            wordImageUrl.startWith("")
        ).map { title, word, mean, translated, image -> Bool in
            let hasMeaning = !mean.isEmpty || !translated.isEmpty
            return !title.isEmpty && !word.isEmpty && hasMeaning && !image.isEmpty
        }
        
        
//        Observable.combineLatest(wordImageUrl, learningWord, wordBookTitle, meanWord, translateWord)
//        
        
        return Output(
            wordImageUrl: wordImageUrl.asDriver(onErrorJustReturn: ""),
            itemSet: Observable.combineLatest(wordImageItems, wordText),
            translateWord: translateWord.asDriver(onErrorJustReturn: ""),
            isValidSave: isValidSave.asDriver(onErrorJustReturn: false)
        )
    }
}
