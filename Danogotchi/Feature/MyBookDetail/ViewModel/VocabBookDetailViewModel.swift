import Foundation
import RxSwift
import RxCocoa

final class VocabBookDetailViewModel: BaseViewModel {
    private let disposeBag = DisposeBag()
    private let fetchVocabsUseCase: FetchVocabsUseCase
    let topic: BookTopic
    
    init(topic: BookTopic, fetchVocabsUseCase: FetchVocabsUseCase) {
        self.topic = topic
        self.fetchVocabsUseCase = fetchVocabsUseCase
    }
    
    struct Input {
        let viewWillAppear: Observable<Void>
    }
    
    struct Output {
        let vocabList: Driver<[VocabDisplayInfo]>
    }
    
    func transform(input: Input) -> Output {
        let vocabList = input.viewWillAppear
            .flatMapLatest { [weak self] _ -> Observable<[VocabDisplayInfo]> in
                guard let self else { return .just([]) }
                return fetchVocabsUseCase.execute(topic: self.topic)
            }.asDriver(onErrorJustReturn: [])
        
        return Output(vocabList: vocabList)
    }
}
