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

    func test_validImageEnablesConfirmAndShowsPreview() throws {
        let fixture = Fixture()

        try fixture.selectValidImage()

        XCTAssertNotNil(fixture.viewModel.previewImage)
        XCTAssertTrue(fixture.viewModel.canConfirm)
        XCTAssertTrue(fixture.alerts.isEmpty)
    }

    func test_imageWithoutCropCannotBeSavedAndOldImageUpdatesAreIgnored() throws {
        let fixture = Fixture()
        try fixture.selectValidImage()
        let previousImage = try XCTUnwrap(fixture.viewModel.previewImage)
        let data = Fixture.imageData(color: .red)
        let image = try XCTUnwrap(UIImage(data: data))
        fixture.viewModel.apply(data: data, image: image)

        XCTAssertNil(fixture.viewModel.crop)
        XCTAssertFalse(fixture.viewModel.canConfirm)
        fixture.viewModel.updateCropRect(CGRect(x: 0, y: 0, width: 1, height: 1), for: previousImage)
        fixture.viewModel.confirmSelection()
        XCTAssertTrue(fixture.save.datas.isEmpty)

        let selection = CGRect(x: 0.25, y: 0.1, width: 0.5, height: 0.8)
        fixture.viewModel.updateCropRect(selection, for: image)
        fixture.viewModel.confirmSelection()
        XCTAssertEqual(fixture.save.datas, [data])
        XCTAssertEqual(fixture.save.crops, [selection])
    }

    func test_pendingSaveBlocksDuplicateConfirms() throws {
        let fixture = Fixture()
        try fixture.selectValidImage()

        fixture.viewModel.confirmSelection()
        fixture.viewModel.confirmSelection()
        fixture.viewModel.confirmSelection()

        // isSaving을 구독 이전에 세우므로 중복 탭이 두 번째 저장을 만들지 못한다
        XCTAssertEqual(fixture.save.datas.count, 1)
        let image = try XCTUnwrap(fixture.viewModel.previewImage)
        let savedCrop = fixture.viewModel.crop
        fixture.viewModel.updateCropRect(CGRect(x: 0, y: 0, width: 1, height: 1), for: image)
        XCTAssertEqual(fixture.viewModel.crop, savedCrop)
        XCTAssertTrue(fixture.viewModel.isSaving)
        XCTAssertFalse(fixture.viewModel.canConfirm)
        XCTAssertEqual(fixture.savedCount, 0)
        XCTAssertTrue(fixture.alerts.isEmpty)
    }

    func test_blackMarginsCanBeSavedButInvisibleOrInvalidSelectionsCannot() throws {
        let fixture = Fixture()
        try fixture.selectValidImage()
        let image = try XCTUnwrap(fixture.viewModel.previewImage)
        for crop in [CGRect(x: 1, y: 0, width: 1, height: 1),
                     CGRect(x: -1, y: 0, width: 1, height: 1),
                     CGRect(x: 0, y: 1, width: 1, height: 1),
                     CGRect(x: 0, y: -1, width: 1, height: 1),
                     .zero, CGRect(x: 0, y: 0, width: -1, height: 1),
                     CGRect(x: CGFloat.nan, y: 0, width: 1, height: 1),
                     CGRect(x: 0, y: 0, width: CGFloat.infinity, height: 1)] {
            fixture.viewModel.updateCropRect(crop, for: image)
            XCTAssertFalse(fixture.viewModel.canConfirm, "\(crop)")
            fixture.viewModel.confirmSelection()
        }
        XCTAssertTrue(fixture.save.datas.isEmpty)

        let crop = CGRect(x: -0.5, y: -0.25, width: 2, height: 1.5)
        fixture.viewModel.updateCropRect(crop, for: image)
        XCTAssertTrue(fixture.viewModel.canConfirm)
        fixture.viewModel.confirmSelection()
        XCTAssertEqual(fixture.save.crops, [crop])
    }

    func test_successNotifiesSavedOnceAndClearsSaving() throws {
        let fixture = Fixture()
        try fixture.selectValidImage()
        fixture.viewModel.confirmSelection()

        fixture.save.complete(.success(()))

        XCTAssertEqual(fixture.savedCount, 1)
        XCTAssertFalse(fixture.viewModel.isSaving)
        XCTAssertTrue(fixture.alerts.isEmpty)
    }

    func test_failureKeepsSelectionAndAllowsRetry() throws {
        let fixture = Fixture()
        try fixture.selectValidImage()
        let crop = CGRect(x: -0.5, y: -0.25, width: 2, height: 1.5)
        fixture.viewModel.updateCropRect(crop, for: try XCTUnwrap(fixture.viewModel.previewImage))

        fixture.viewModel.confirmSelection()
        fixture.save.complete(.failure(CocoaError(.fileWriteOutOfSpace)))

        XCTAssertEqual(fixture.alerts, ["잠시후 다시 시도해주세요"])
        XCTAssertEqual(fixture.savedCount, 0)
        XCTAssertFalse(fixture.viewModel.isSaving)
        XCTAssertTrue(fixture.viewModel.canConfirm, "실패해도 선택이 남아 같은 사진으로 다시 시도할 수 있다")
        XCTAssertEqual(fixture.viewModel.crop?.rect, crop)

        fixture.viewModel.confirmSelection()
        XCTAssertEqual(fixture.save.datas.count, 2)
        XCTAssertEqual(fixture.save.datas.first, fixture.save.datas.last, "같은 사진으로 재시도한다")
        XCTAssertEqual(fixture.save.crops.first, fixture.save.crops.last, "같은 구도로 재시도한다")

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

    func test_cropPublishesOnlyWhenConfirmAvailabilityChanges() throws {
        let fixture = Fixture()
        let (data, image) = try solidImage(color: .blue)
        fixture.viewModel.apply(data: data, image: image)
        var changes = 0
        let cancellable = fixture.viewModel.objectWillChange.sink { changes += 1 }
        defer { cancellable.cancel() }

        fixture.viewModel.updateCropRect(CGRect(x: 0.25, y: 0, width: 0.5, height: 1), for: image)
        XCTAssertEqual(changes, 1)
        XCTAssertTrue(fixture.viewModel.canConfirm)

        // 스크롤 중 값은 갱신되지만 화면 갱신은 일으키지 않는다
        let moved = CGRect(x: 0.3, y: 0, width: 0.5, height: 1)
        fixture.viewModel.updateCropRect(moved, for: image)
        XCTAssertEqual(changes, 1)
        XCTAssertEqual(fixture.viewModel.crop?.rect, moved)

        fixture.viewModel.updateCropRect(CGRect(x: 2, y: 0, width: 0.5, height: 1), for: image)
        XCTAssertEqual(changes, 2)
        XCTAssertFalse(fixture.viewModel.canConfirm)

        fixture.viewModel.updateCropRect(CGRect(x: 3, y: 0, width: 0.5, height: 1), for: image)
        XCTAssertEqual(changes, 2)

        fixture.viewModel.updateCropRect(moved, for: image)
        XCTAssertEqual(changes, 3)
        XCTAssertTrue(fixture.viewModel.canConfirm)
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
        func selectValidImage() throws {
            let data = Self.imageData(color: .blue)
            let image = try XCTUnwrap(UIImage(data: data))
            viewModel.apply(data: data, image: image)
            viewModel.updateCropRect(CGRect(x: 0.25, y: 0, width: 0.5, height: 1), for: image)
        }

        static func imageData(color: UIColor) -> Data {
            UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).pngData { context in
                color.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
            }
        }
    }
}
