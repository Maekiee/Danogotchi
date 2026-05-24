import Foundation
import RxSwift

protocol RecommendBookRepoProtocol {
    func fetchRecommendBooks() -> Observable<[WordBook]>
}
