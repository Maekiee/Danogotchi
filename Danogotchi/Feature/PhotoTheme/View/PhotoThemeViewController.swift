import ComposableArchitecture
import SwiftUI
import UIKit

/// 설정 push·온보딩 모달이 공유하는 사진 테마 화면 컨테이너
final class PhotoThemeViewController: UIHostingController<PhotoThemeView> {
    let store: StoreOf<PhotoThemeFeature>
    private var didAutoPresentPicker = false

    /// Store는 MainActor 전용이라 DI가 아닌 여기서 만든다
    init(feature: PhotoThemeFeature) {
        let store = Store(initialState: PhotoThemeFeature.State()) { feature }
        self.store = store
        super.init(rootView: PhotoThemeView(store: store))
        title = "내 사진으로 지정"

        // 검은 배경 위 투명 바 — 타이틀을 흰색으로
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: AppColor.white]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
    }

    @MainActor
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // 저장 중 이탈 차단 — 설정의 뒤로(스와이프 포함), 온보딩의 닫기
        observe { [weak self] in
            guard let self else { return }
            navigationItem.hidesBackButton = store.isSaving
            navigationItem.leftBarButtonItem?.isEnabled = !store.isSaving
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 전환 애니메이션 종료 후 사진첩 자동 표시 — 모달 위 모달 충돌 방지
        guard !didAutoPresentPicker else { return }
        didAutoPresentPicker = true
        store.isPickerPresented = true
    }
}
