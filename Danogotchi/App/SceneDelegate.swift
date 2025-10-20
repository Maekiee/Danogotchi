import UIKit
import RealmSwift

enum Coordinator {
    static func switchToMainVieWController() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate else { return }
  
        let vm = WordTabViewModel()
        let NavVC = UINavigationController(rootViewController: WordTabViewController(viewModel: vm))
        
//        configureNavigationBar(NavVC)
//        sceneDelegate.changeRootVC(NavVC)
//        
        sceneDelegate.changeRootVC(MainTabViewController())
    }
    
    
    // 임시 파일
    static func configureNavigationBar(_ navController: UINavigationController) {
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithTransparentBackground()

        navigationBarAppearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
        navigationBarAppearance.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        
        navigationBarAppearance.shadowColor = .clear
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
    }
}


class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let scene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: scene)
        
        let realm = try? Realm()
        
        print("Realm is located at:", realm!.configuration.fileURL!)
        
        if UserInfoManager.shared.username != nil {
            // 탭바 없는거
//            let vm = WordTabViewModel()
//            let vc = WordTabViewController(viewModel: vm)
//            let navVC = UINavigationController(rootViewController: vc)
//            Coordinator.configureNavigationBar(navVC)
//            window?.rootViewController = navVC
            
            // 탭바 있는거
            window?.rootViewController = MainTabViewController()
        } else {
            window?.rootViewController = SetUserNameViewController()
        }
        
        
        window?.makeKeyAndVisible()
    }
    
    func changeRootVC(_ vc: UIViewController ) {
        guard let window = self.window else { return }
        window.rootViewController = vc
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) { }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        
    }

    func sceneWillResignActive(_ scene: UIScene) {
        
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        
    }


}

