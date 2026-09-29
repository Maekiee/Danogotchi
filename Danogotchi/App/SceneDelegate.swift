import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var appCoordinator: AppFlowCoordinator?
    #if DEBUG
    private var studyReportTestCoordinator: MainCoordinator?
    #endif
    
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        #if DEBUG
        UITestingSupport.resetIfRequested()
        #endif
        let container = AppDIContainer()
        window = UIWindow(windowScene: scene)
        #if DEBUG
        if let coordinator = UITestingSupport.startStudyReportIfRequested(window: window!, container: container) {
            studyReportTestCoordinator = coordinator
            return
        }
        #endif
        appCoordinator = AppFlowCoordinator(window: window!, container: container)
        appCoordinator?.start()
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

