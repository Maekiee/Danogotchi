import RxCocoa
import RxSwift
import XCTest
@testable import Danogotchi

@MainActor
final class LibraryViewModelTests: XCTestCase {
    func test_localBooksShowImmediatelyAndServerListIsFetchedOncePerScreen() async throws {
        let books = DefaultVocabBookRepository(context: makeInMemoryContext())
        let myBook = try books.createBook(title: "my", bookType: .myBook, level: nil)
        let remote = ControlledRemoteVocabBookRepository()
        remote.books = .success([RemoteVocabBook(key: travelA1, wordCount: 2, order: 0)])
        let viewModel = LibraryViewModel(fetchVocabBooksUseCase: DefaultFetchVocabBooksUseCase(
            vocabBookRepository: books, remoteVocabBookRepository: remote
        ))
        let appear = PublishRelay<Void>()
        let output = viewModel.transform(input: .init(viewWillAppear: appear.asObservable()))
        let bag = DisposeBag()
        var items: [VocabBookCardInfo] = []
        output.bookItems.drive(onNext: { items = $0 }).disposed(by: bag)

        appear.accept(())
        XCTAssertEqual(items.map(\.key), [myBook.key])
        await waitUntil { items.map(\.key) == [myBook.key, travelA1] }

        // 다시 나타나거나 학습중이 바뀌어도 서버 목록은 다시 읽지 않는다
        appear.accept(())
        try books.setActive(id: myBook.id, isActive: true)
        await waitUntil {
            items == [VocabBookCardInfo(key: myBook.key, isActive: true), VocabBookCardInfo(key: travelA1, isActive: false)]
        }
        XCTAssertEqual(remote.fetchBooksCount, 1)
    }

    func test_failedServerListShowsLocalBooksAndRetriesOnNextAppear() async throws {
        let books = DefaultVocabBookRepository(context: makeInMemoryContext())
        let myBook = try books.createBook(title: "my", bookType: .myBook, level: nil)
        let remote = ControlledRemoteVocabBookRepository()
        remote.books = .failure(URLError(.notConnectedToInternet))
        let viewModel = LibraryViewModel(fetchVocabBooksUseCase: DefaultFetchVocabBooksUseCase(
            vocabBookRepository: books, remoteVocabBookRepository: remote
        ))
        let appear = PublishRelay<Void>()
        let output = viewModel.transform(input: .init(viewWillAppear: appear.asObservable()))
        let bag = DisposeBag()
        var items: [VocabBookCardInfo] = []
        var alerts = 0
        output.bookItems.drive(onNext: { items = $0 }).disposed(by: bag)
        output.alertMessage.emit(onNext: { _ in alerts += 1 }).disposed(by: bag)

        appear.accept(())
        // 받는 중에 다시 나타나도 겹쳐 읽지 않는다
        appear.accept(())
        await waitUntil { remote.fetchBooksCount == 1 }
        XCTAssertEqual(items.map(\.key), [myBook.key])

        // 실패한 요청이 끝난 뒤 나타나면 다시 받는다 — 끝나는 시점을 알 수 없어 나타나기를 반복한다
        remote.books = .success([RemoteVocabBook(key: travelA1, wordCount: 2, order: 0)])
        await waitUntil {
            appear.accept(())
            return items.map(\.key) == [myBook.key, travelA1]
        }
        appear.accept(())
        XCTAssertEqual(remote.fetchBooksCount, 2)
        XCTAssertEqual(alerts, 0)
    }
}
