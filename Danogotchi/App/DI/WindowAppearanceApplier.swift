import UIKit

/// 앱 창에 모드를 건다 — 창 아래 화면·모달이 모두 따라간다
final class WindowAppearanceApplier: AppearanceApplying {
    private weak var window: UIWindow?

    init(window: UIWindow) {
        self.window = window
    }

    func apply(_ mode: AppearanceMode) {
        window?.overrideUserInterfaceStyle = mode.userInterfaceStyle
    }
}
