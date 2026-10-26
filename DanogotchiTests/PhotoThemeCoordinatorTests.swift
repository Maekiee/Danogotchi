import SwiftUI
import UIKit
import XCTest
@testable import Danogotchi

@MainActor
final class PhotoThemeCoordinatorTests: XCTestCase {

    func test_settingMyPhotoPushesPhotoThemeScreen() {
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = SettingCoordinator(
            container: AppDIContainer(screenPixelSize: CGSize(width: 1179, height: 2556), window: UIWindow())
                .makeMainDIContainer().makeSettingDIContainer(),
            navigationController: navigationController
        )

        coordinator.didTapMyPhoto()

        XCTAssertTrue(navigationController.topViewController is UIHostingController<PhotoThemeView>)
    }
}
