import Foundation
import RxSwift
import RxCocoa

final class VocabBookDetailViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let topic: BookTopic
    private let fetchVocabBooksUseCase: FetchVocabBookUseCase
    var navigationBarTitle: String { topic.title }
    
    init(topic: BookTopic, fetchVocabBooksUseCase: FetchVocabBookUseCase) {
        self.topic = topic
        self.fetchVocabBooksUseCase = fetchVocabBooksUseCase
    }
    
    struct Input {
        
    }
    
    struct Output {
        
    }
    
    func transform(input: Input) -> Output {
        return Output()
    }
}
