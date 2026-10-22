import SwiftUI
import UIKit
import XCTest
@testable import Danogotchi

@MainActor
final class PhotoThemeCoordinatorTests: XCTestCase {

    func test_settingMyPhotoPushesPhotoThemeScreen() {
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = SettingCoordinator(
            container: AppDIContainer().makeMainDIContainer().makeSettingDIContainer(),
            navigationController: navigationController
        )

        coordinator.didTapMyPhoto()

        XCTAssertTrue(navigationController.topViewController is UIHostingController<PhotoThemeView>)
    }
}
