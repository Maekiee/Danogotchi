import Foundation
import RxSwift
import RxCocoa

final class AddWordViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    
    struct Input {
        let wordTextField: Observable<String>
        let meanTextField: Observable<String>
    }
    
    struct Output {
        let wordImageUrl: Driver<String>
    }
    
    func transform(input: Input) -> Output {
        let wordImageUrl = PublishRelay<String>()
        
        input.wordTextField
            .debounce(.seconds(2), scheduler: MainScheduler.instance)
            .flatMap{
                // 빈 문자열일때 api 호출 안하게 막아됨
                ApiService.searchPhoto(api: .searchPhoto(word: $0, page: 1), type: SearchPhotoDTO.self)
            }
            .bind(with: self) { owner, responseValue in
                switch responseValue {
                case .success(let value):
                    wordImageUrl.accept( value.results.first!.urls.small)
                case .failure(_):
                    print("네트워크 에러")
                }
            }.disposed(by: disposeBag)
        
        
        
        return Output(
            wordImageUrl: wordImageUrl.asDriver(onErrorJustReturn: "")
        )
    }
}
