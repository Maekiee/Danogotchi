import Foundation
import RxSwift

protocol RecommendBookRepository {
    func fetchRecommendBooks() -> Observable<[WordBook]>
}
