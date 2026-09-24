import ComposableArchitecture
import UIKit
import XCTest
@testable import Danogotchi

@MainActor
final class PhotoThemeFeatureTests: XCTestCase {
    private static let validCrop = CGRect(x: 0.25, y: 0, width: 0.5, height: 1)

    func test_confirmWithoutSelectionDoesNotSave() async {
        let fixture = Fixture()

        await fixture.store.send(.confirmTapped)

        XCTAssertTrue(fixture.save.datas.isEmpty)
        XCTAssertFalse(fixture.store.state.canConfirm)
        XCTAssertEqual(fixture.savedCount.value, 0)
    }

    func test_validImageEnablesConfirmAndShowsPreview() async throws {
        let fixture = Fixture()

        try await fixture.selectValidImage()

        XCTAssertNotNil(fixture.store.state.previewImage)
        XCTAssertTrue(fixture.store.state.canConfirm)
    }

    func test_imageWithoutCropCannotBeSavedAndOldImageUpdatesAreIgnored() async throws {
        let fixture = Fixture()
        let previousImage = try await fixture.selectValidImage()
        let (data, image) = try solidImage(color: .red)
        await fixture.store.send(.imageLoaded(data: data, image: image)) {
            $0.imageData = data
            $0.previewImage = image
            $0.crop = nil
            $0.hasCrop = false
        }

        XCTAssertFalse(fixture.store.state.canConfirm)
        await fixture.store.send(.cropChanged(CGRect(x: 0, y: 0, width: 1, height: 1), previousImage))
        await fixture.store.send(.confirmTapped)
        XCTAssertTrue(fixture.save.datas.isEmpty)

        let selection = CGRect(x: 0.25, y: 0.1, width: 0.5, height: 0.8)
        await fixture.store.send(.cropChanged(selection, image)) {
            $0.crop = PhotoThemeCrop(selection)
            $0.hasCrop = true
        }
        await fixture.store.send(.confirmTapped) { $0.isSaving = true }
        XCTAssertEqual(fixture.save.datas, [data])
        XCTAssertEqual(fixture.save.crops, [selection])
        await fixture.store.skipInFlightEffects()
    }

    func test_pendingSaveBlocksDuplicateConfirms() async throws {
        let fixture = Fixture()
        let image = try await fixture.selectValidImage()

        await fixture.store.send(.confirmTapped) { $0.isSaving = true }
        await fixture.store.send(.confirmTapped)
        await fixture.store.send(.confirmTapped)

        // isSaving을 구독 이전에 세우므로 중복 탭이 두 번째 저장을 만들지 못한다
        XCTAssertEqual(fixture.save.datas.count, 1)
        // 저장 중에는 크롭이 바뀌지 않는다 — 상태 변화가 없어야 통과한다
        await fixture.store.send(.cropChanged(CGRect(x: 0, y: 0, width: 1, height: 1), image))
        XCTAssertFalse(fixture.store.state.canConfirm)
        XCTAssertEqual(fixture.savedCount.value, 0)
        await fixture.store.skipInFlightEffects()
    }

    func test_blackMarginsCanBeSavedButInvisibleOrInvalidSelectionsCannot() async throws {
        let fixture = Fixture()
        let image = try await fixture.selectValidImage()
        let invalidCrops = [CGRect(x: 1, y: 0, width: 1, height: 1),
                            CGRect(x: -1, y: 0, width: 1, height: 1),
                            CGRect(x: 0, y: 1, width: 1, height: 1),
                            CGRect(x: 0, y: -1, width: 1, height: 1),
                            .zero, CGRect(x: 0, y: 0, width: -1, height: 1),
                            CGRect(x: CGFloat.nan, y: 0, width: 1, height: 1),
                            CGRect(x: 0, y: 0, width: CGFloat.infinity, height: 1)]

        // 첫 무효 영역이 선택을 비우고, 이후 무효 영역은 상태를 바꾸지 않는다
        await fixture.store.send(.cropChanged(invalidCrops[0], image)) {
            $0.crop = nil
            $0.hasCrop = false
        }
        for crop in invalidCrops.dropFirst() {
            await fixture.store.send(.cropChanged(crop, image))
        }
        await fixture.store.send(.confirmTapped)
        XCTAssertTrue(fixture.save.datas.isEmpty)

        let crop = CGRect(x: -0.5, y: -0.25, width: 2, height: 1.5)
        await fixture.store.send(.cropChanged(crop, image)) {
            $0.crop = PhotoThemeCrop(crop)
            $0.hasCrop = true
        }
        await fixture.store.send(.confirmTapped) { $0.isSaving = true }
        XCTAssertEqual(fixture.save.crops, [crop])
        await fixture.store.skipInFlightEffects()
    }

    func test_successNotifiesSavedOnceAndClearsSaving() async throws {
        let fixture = Fixture()
        try await fixture.selectValidImage()
        await fixture.store.send(.confirmTapped) { $0.isSaving = true }

        fixture.save.complete(.success(()))

        await fixture.store.receive(\.saveResponse) { $0.isSaving = false }
        await fixture.store.finish()
        XCTAssertEqual(fixture.savedCount.value, 1)
    }

    func test_failureKeepsSelectionAndAllowsRetry() async throws {
        let fixture = Fixture()
        let image = try await fixture.selectValidImage()
        let crop = CGRect(x: -0.5, y: -0.25, width: 2, height: 1.5)
        await fixture.store.send(.cropChanged(crop, image)) { $0.crop = PhotoThemeCrop(crop) }

        await fixture.store.send(.confirmTapped) { $0.isSaving = true }
        fixture.save.complete(.failure(CocoaError(.fileWriteOutOfSpace)))

        await fixture.store.receive(\.saveResponse) {
            $0.isSaving = false
            $0.alertMessage = "잠시후 다시 시도해주세요"
        }
        XCTAssertEqual(fixture.savedCount.value, 0)
        XCTAssertTrue(fixture.store.state.canConfirm, "실패해도 선택이 남아 같은 사진으로 다시 시도할 수 있다")

        await fixture.store.send(.confirmTapped) { $0.isSaving = true }
        XCTAssertEqual(fixture.save.datas.count, 2)
        XCTAssertEqual(fixture.save.datas.first, fixture.save.datas.last, "같은 사진으로 재시도한다")
        XCTAssertEqual(fixture.save.crops.first, fixture.save.crops.last, "같은 구도로 재시도한다")

        fixture.save.complete(.success(()))

        await fixture.store.receive(\.saveResponse) { $0.isSaving = false }
        await fixture.store.finish()
        XCTAssertEqual(fixture.savedCount.value, 1)
    }

    func test_unsupportedFormatShowsFormatSpecificMessageAndBlocksConfirm() async {
        let fixture = Fixture()

        await fixture.store.send(.imageLoaded(data: Data("invalid".utf8), image: nil)) {
            $0.alertMessage = "지원하지 않는 이미지 형식이에요. 다른 사진을 선택해주세요"
        }
        XCTAssertFalse(fixture.store.state.canConfirm)

        await fixture.store.send(.confirmTapped)
        XCTAssertTrue(fixture.save.datas.isEmpty)
    }

    func test_transferFailureEndsLoadingAndShowsRetryMessage() async {
        var state = PhotoThemeFeature.State()
        state.isLoading = true
        let fixture = Fixture(initialState: state)

        await fixture.store.send(.imageLoadFailed(PhotoThemeError.transferFailed)) {
            $0.isLoading = false
            $0.alertMessage = "잠시후 다시 시도해주세요"
        }
    }

    func test_cropNotifiesOnlyWhenConfirmAvailabilityChanges() throws {
        let store = Store(initialState: PhotoThemeFeature.State()) {
            PhotoThemeFeature(savePhotoThemeUseCase: ControlledSavePhotoThemeUseCase(), onThemeSaved: {})
        }
        let (data, image) = try solidImage(color: .blue)
        store.send(.imageLoaded(data: data, image: image))

        // 확인 버튼이 읽는 값에 변경 알림이 갔는지
        func notifiesConfirm(_ rect: CGRect) -> Bool {
            let changed = LockIsolated(false)
            withObservationTracking { _ = store.canConfirm } onChange: { changed.setValue(true) }
            store.send(.cropChanged(rect, image))
            return changed.value
        }

        XCTAssertTrue(notifiesConfirm(Self.validCrop))
        XCTAssertTrue(store.canConfirm)

        // 스크롤 중 값은 갱신되지만 화면 갱신은 일으키지 않는다
        let moved = CGRect(x: 0.3, y: 0, width: 0.5, height: 1)
        XCTAssertFalse(notifiesConfirm(moved))
        XCTAssertEqual(store.crop?.rect, moved)

        XCTAssertTrue(notifiesConfirm(CGRect(x: 2, y: 0, width: 0.5, height: 1)))
        XCTAssertFalse(store.canConfirm)
        XCTAssertFalse(notifiesConfirm(CGRect(x: 3, y: 0, width: 0.5, height: 1)))

        XCTAssertTrue(notifiesConfirm(moved))
        XCTAssertTrue(store.canConfirm)
    }

    func test_closeButtonTappedCallsOnClose() async {
        let fixture = Fixture()

        await fixture.store.send(.closeButtonTapped)

        XCTAssertEqual(fixture.closedCount.value, 1)
    }

    @MainActor
    private final class Fixture {
        let save = ControlledSavePhotoThemeUseCase()
        let savedCount = LockIsolated(0)
        let closedCount = LockIsolated(0)
        let store: TestStoreOf<PhotoThemeFeature>

        init(initialState: PhotoThemeFeature.State = PhotoThemeFeature.State()) {
            store = TestStore(initialState: initialState) { [save, savedCount, closedCount] in
                PhotoThemeFeature(
                    savePhotoThemeUseCase: save,
                    onThemeSaved: { savedCount.withValue { $0 += 1 } },
                    onClose: { closedCount.withValue { $0 += 1 } }
                )
            }
        }

        /// 실제 화면에서는 이펙트가 백그라운드에서 디코딩한 뒤 imageLoaded를 보낸다
        @discardableResult
        func selectValidImage() async throws -> UIImage {
            let (data, image) = try solidImage(color: .blue)
            await store.send(.imageLoaded(data: data, image: image)) {
                $0.imageData = data
                $0.previewImage = image
            }
            await store.send(.cropChanged(PhotoThemeFeatureTests.validCrop, image)) {
                $0.crop = PhotoThemeCrop(PhotoThemeFeatureTests.validCrop)
                $0.hasCrop = true
            }
            return image
        }
    }
}
