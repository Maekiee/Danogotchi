import Foundation
import RxSwift
import RxCocoa
import RealmSwift

final class AddWordViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let wordBookRepo: WordBookRepositoryProtocol
    private let wordRepo: WordRepositoryProtocol
    
    let wordBookId: ObjectId?
    
    
    init(wordBookId: ObjectId? = nil,
         wordBookRepo: WordBookRepositoryProtocol = WordBookRepository(),
         wordRepo: WordRepositoryProtocol = WordRepository()
    ) {
        self.wordBookId = wordBookId
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
        
        // 저장 버튼
        input.savedButtonTapped
            .bind(with: self) { owner, _ in
                
              // 단어 추가 화면 진입시 이미 단어장에 대한 데이터를 들고 있음
                // 단어장 타이틀이 빈값인지 체크
                // 이미지가 있는지 체크
                // 단어가 있는지 체크
                // 뜻이 있는지 체크
                // 모두 있으면 해당 값을 디비에 저장
                // 저장이 완료 됐으면 단어장 타이틀을 제외한 모든 값 초기화
                // 저장이 되었다는 토스트 메세지 출력
            }.disposed(by: disposeBag)
        
        // 단어장 유효성 검사
        Observable.combineLatest(
            wordImageUrl.map { !$0.isEmpty },
            validWord.map { !$0.isEmpty },
            wordBookTitle.map { !$0.isEmpty },
            meanWord,
            translateWord).map { imageValid, wordValid, titleValid, mean, translate in
                let hasMeaning = !mean.isEmpty || !translate.isEmpty
                return imageValid && wordValid && titleValid && hasMeaning
            }.bind(with: self) { owner, isValid in
                isValidSaved.accept(isValid)
            }.disposed(by: disposeBag)
        
        return Output(
            wordImageUrl: wordImageUrl.asDriver(onErrorJustReturn: ""),
            itemSet: Observable.combineLatest(wordImageItems, wordText),
            translateWord: translateWord.asDriver(onErrorJustReturn: ""),
            isValidSave: isValidSaved.asDriver(onErrorJustReturn: false)
        )
    }
}
