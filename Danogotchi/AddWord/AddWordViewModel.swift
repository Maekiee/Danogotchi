import Foundation
import RxSwift
import RxCocoa

final class AddWordViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    
    struct Input {
        let wordTextField: Observable<String>
        let meanTextField: Observable<String>
        let selectedImage: Observable<String>
    }
    
    struct Output {
        let wordImageUrl: Driver<String>
        let wordImageItems: PublishRelay<SearchPhotoDTO>
        let wordText: PublishRelay<String>
        let itemSet: Observable<(SearchPhotoDTO, String)>
    }
    
    func transform(input: Input) -> Output {
        let wordImageUrl = PublishRelay<String>()
        let wordImageItems = PublishRelay<SearchPhotoDTO>()
        let wordText = PublishRelay<String>()
        
        let learningWord = input.wordTextField
            .skip(1)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter{ $0.count >= 2 }
            .distinctUntilChanged()
            .debounce(.seconds(2), scheduler: MainScheduler.instance)
            .do { text in
                wordText.accept(text)
            }.share()
        
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
                    print("번역 데이터\(value)")
                case .failure(_):
                    print("네트워크 에러")
                }
            }.disposed(by: disposeBag)
        
        input.selectedImage
            .bind(to: wordImageUrl)
            .disposed(by: disposeBag)
        
        return Output(
            wordImageUrl: wordImageUrl.asDriver(onErrorJustReturn: ""),
            wordImageItems: wordImageItems,
            wordText: wordText,
            itemSet: Observable.combineLatest(wordImageItems, wordText)
        )
    }
}
