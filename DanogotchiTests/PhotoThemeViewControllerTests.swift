import UIKit
import XCTest
@testable import Danogotchi

@MainActor
final class PhotoThemeViewControllerTests: XCTestCase {

    func test_titleIsWhiteOnTransparentNavigationBar() throws {
        let screen = Screen()

        XCTAssertEqual(screen.viewController.title, "내 사진으로 지정")
        // 검은 배경 위에서 기본 검은 타이틀이 묻히지 않게 한다
        for appearance in [screen.viewController.navigationItem.standardAppearance,
                           screen.viewController.navigationItem.scrollEdgeAppearance] {
            let color = try XCTUnwrap(appearance?.titleTextAttributes[.foregroundColor] as? UIColor)
            XCTAssertEqual(color, AppColor.white)
        }
    }

    func test_pickerAutoPresentsOnlyAfterFirstAppearance() {
        let screen = Screen()
        let viewController = screen.viewController

        viewController.beginAppearanceTransition(true, animated: false)
        XCTAssertFalse(screen.viewModel.isPickerPresented, "전환 중에는 사진첩을 띄우지 않는다")
        viewController.endAppearanceTransition()
        XCTAssertTrue(screen.viewModel.isPickerPresented)

        // 사진첩을 취소하고 화면이 다시 나타나도 자동으로 열지 않는다
        screen.viewModel.isPickerPresented = false
        viewController.beginAppearanceTransition(false, animated: false)
        viewController.endAppearanceTransition()
        viewController.beginAppearanceTransition(true, animated: false)
        viewController.endAppearanceTransition()
        XCTAssertFalse(screen.viewModel.isPickerPresented)
    }

    func test_savingBlocksBackAndCloseUntilSaveFinishes() throws {
        let screen = Screen()
        let navigationItem = screen.viewController.navigationItem
        let close = try XCTUnwrap(navigationItem.leftBarButtonItem)
        XCTAssertFalse(navigationItem.hidesBackButton)
        XCTAssertTrue(close.isEnabled)

        try screen.selectImage()
        screen.viewModel.confirmSelection()
        XCTAssertTrue(navigationItem.hidesBackButton)
        XCTAssertFalse(close.isEnabled)

        // 실패하면 이탈과 재시도가 모두 다시 가능하다
        screen.save.complete(.failure(CocoaError(.fileWriteOutOfSpace)))
        XCTAssertFalse(navigationItem.hidesBackButton)
        XCTAssertTrue(close.isEnabled)

        screen.viewModel.confirmSelection()
        XCTAssertTrue(navigationItem.hidesBackButton)
        screen.save.complete(.success(()))
        XCTAssertFalse(navigationItem.hidesBackButton)
        XCTAssertTrue(close.isEnabled)
    }

    @MainActor
    private final class Screen {
        let save = ControlledSavePhotoThemeUseCase()
        let viewModel: PhotoThemeViewModel
        let viewController: PhotoThemeViewController

        init() {
            viewModel = PhotoThemeViewModel(savePhotoThemeUseCase: save)
            viewController = PhotoThemeViewController(viewModel: viewModel)
            // 온보딩 코디네이터처럼 닫기 버튼을 단 뒤 화면을 올린다
            viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close)
            viewController.loadViewIfNeeded()
        }

        func selectImage() throws {
            let (data, image) = try solidImage(color: .blue)
            viewModel.apply(data: data, image: image)
            viewModel.updateCropRect(CGRect(x: 0.25, y: 0, width: 0.5, height: 1), for: image)
        }
    }
}
