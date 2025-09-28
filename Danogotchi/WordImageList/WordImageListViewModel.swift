import Foundation
import RxSwift
import RxCocoa

final class WordImageListViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    
    let imageItems: SearchPhotoDTO
    let wordText: String
    
    init(imageItems: SearchPhotoDTO, wordText: String) {
        self.imageItems = imageItems
        self.wordText = wordText
    }
    
    struct Input {
        
    }
    
    struct Output {
        
    }
    
    func transform(input: Input) -> Output {
        
        
        return Output()
    }
}
