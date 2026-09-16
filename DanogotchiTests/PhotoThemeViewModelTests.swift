import Combine
import UIKit
import XCTest
@testable import Danogotchi

final class PhotoThemeViewModelTests: XCTestCase {

    func test_confirmWithoutSelectionDoesNotSave() {
        let fixture = Fixture()

        fixture.viewModel.confirmSelection()

        XCTAssertTrue(fixture.save.datas.isEmpty)
        XCTAssertFalse(fixture.viewModel.isSaving)
        XCTAssertFalse(fixture.viewModel.canConfirm)
        XCTAssertEqual(fixture.savedCount, 0)
    }

    func test_validImageEnablesConfirmAndShowsPreview() {
        let fixture = Fixture()

        fixture.selectValidImage()

        XCTAssertNotNil(fixture.viewModel.previewImage)
        XCTAssertTrue(fixture.viewModel.canConfirm)
        XCTAssertTrue(fixture.alerts.isEmpty)
    }

    func test_pendingSaveBlocksDuplicateConfirms() {
        let fixture = Fixture()
        fixture.selectValidImage()

        fixture.viewModel.confirmSelection()
        fixture.viewModel.confirmSelection()
        fixture.viewModel.confirmSelection()

        // isSaving을 구독 이전에 세우므로 중복 탭이 두 번째 저장을 만들지 못한다
        XCTAssertEqual(fixture.save.datas.count, 1)
        XCTAssertTrue(fixture.viewModel.isSaving)
        XCTAssertFalse(fixture.viewModel.canConfirm)
        XCTAssertEqual(fixture.savedCount, 0)
        XCTAssertTrue(fixture.alerts.isEmpty)
    }

    func test_successNotifiesSavedOnceAndClearsSaving() {
        let fixture = Fixture()
        fixture.selectValidImage()
        fixture.viewModel.confirmSelection()

        fixture.save.complete(.success(()))

        XCTAssertEqual(fixture.savedCount, 1)
        XCTAssertFalse(fixture.viewModel.isSaving)
        XCTAssertTrue(fixture.alerts.isEmpty)
    }

    func test_failureKeepsSelectionAndAllowsRetry() {
        let fixture = Fixture()
        fixture.selectValidImage()

        fixture.viewModel.confirmSelection()
        fixture.save.complete(.failure(CocoaError(.fileWriteOutOfSpace)))

        XCTAssertEqual(fixture.alerts, ["잠시후 다시 시도해주세요"])
        XCTAssertEqual(fixture.savedCount, 0)
        XCTAssertFalse(fixture.viewModel.isSaving)
        XCTAssertTrue(fixture.viewModel.canConfirm, "실패해도 선택이 남아 같은 사진으로 다시 시도할 수 있다")

        fixture.viewModel.confirmSelection()
        XCTAssertEqual(fixture.save.datas.count, 2)
        XCTAssertEqual(fixture.save.datas.first, fixture.save.datas.last, "같은 사진으로 재시도한다")

        fixture.save.complete(.success(()))

        XCTAssertEqual(fixture.savedCount, 1)
        XCTAssertEqual(fixture.alerts.count, 1)
    }

    func test_unsupportedFormatShowsFormatSpecificMessageAndBlocksConfirm() {
        let fixture = Fixture()

        fixture.viewModel.apply(data: Data("invalid".utf8), image: nil)

        XCTAssertEqual(fixture.alerts, ["지원하지 않는 이미지 형식이에요. 다른 사진을 선택해주세요"])
        XCTAssertNil(fixture.viewModel.previewImage)
        XCTAssertFalse(fixture.viewModel.canConfirm)

        fixture.viewModel.confirmSelection()
        XCTAssertTrue(fixture.save.datas.isEmpty)
    }

    private final class Fixture {
        let save = ControlledSavePhotoThemeUseCase()
        let viewModel: PhotoThemeViewModel
        private(set) var savedCount = 0
        private(set) var alerts: [String] = []
        private var cancellables = Set<AnyCancellable>()

        init() {
            viewModel = PhotoThemeViewModel(savePhotoThemeUseCase: save)
            viewModel.onThemeSaved = { [weak self] in self?.savedCount += 1 }
            viewModel.$alertMessage
                .compactMap { $0 }
                .sink { [weak self] message in self?.alerts.append(message) }
                .store(in: &cancellables)
        }

        /// 실제 화면에서는 파이프라인이 백그라운드에서 디코딩한 뒤 이 지점을 호출한다
        func selectValidImage() {
            let data = Self.imageData(color: .blue)
            viewModel.apply(data: data, image: UIImage(data: data))
        }

        static func imageData(color: UIColor) -> Data {
            UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).pngData { context in
                color.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
            }
        }
    }
}

private final class ControlledSavePhotoThemeUseCase: SavePhotoThemeUseCase {
    private(set) var datas: [Data] = []
    private var pending: PassthroughSubject<Void, Error>?

    func execute(imageData: Data) -> AnyPublisher<Void, Error> {
        datas.append(imageData)
        XCTAssertNil(pending, "A pending save must not be replaced by another confirm")
        // 완료된 subject는 재사용할 수 없어 호출마다 새로 만든다 — 재시도 테스트가 필요로 한다
        let subject = PassthroughSubject<Void, Error>()
        pending = subject
        return subject.eraseToAnyPublisher()
    }

    func complete(_ result: Result<Void, Error>) {
        guard let subject = pending else {
            XCTFail("No pending save")
            return
        }
        pending = nil

        switch result {
        case .success:
            subject.send(())
            subject.send(completion: .finished)
        case .failure(let error):
            subject.send(completion: .failure(error))
        }
    }
}
