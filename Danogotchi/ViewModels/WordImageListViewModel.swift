import Foundation
import RxSwift
import RxCocoa

final class WordImageListViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    
    let imageItems: SearchPhotoDTO
    let wordText: String
    private var currentPage = 2
    private var isLoading = false
    
    init(imageItems: SearchPhotoDTO, wordText: String) {
        self.imageItems = imageItems
        self.wordText = wordText
    }
    
    struct Input {
        let loadNextPage: Observable<Void>
    }
    
    struct Output {
        let imageList: Driver<[PhotoDTO]>
    }
    
    func transform(input: Input) -> Output {
        let imageItems = BehaviorRelay<[PhotoDTO]>(value: imageItems.results)
        let nextPage = BehaviorRelay<Int>(value: 2)
        
        input.loadNextPage
            
            .withLatestFrom(nextPage.asObservable())
            .flatMapLatest{ page -> Single<Result<SearchPhotoDTO, Error>> in
                print(page)
                return ApiService.searchPhoto(api: .searchPhoto(word: self.wordText, page: page), type: SearchPhotoDTO.self)
            }
            .bind(with: self) { owner, responseValue in
                switch responseValue {
                case .success(let value):
                    var currentList = imageItems.value
                    currentList.append(contentsOf: value.results)
                    imageItems.accept(currentList)
                    nextPage.accept(nextPage.value + 1)
                case .failure(_):
                    print("네트워크 에러")
                }
            }.disposed(by: disposeBag)
        
        
        
        return Output(
            imageList: imageItems.asDriver(onErrorJustReturn: [])
        )
    }
}
