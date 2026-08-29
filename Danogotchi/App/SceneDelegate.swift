import UIKit
import OSLog

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var appCoordinator: AppFlowCoordinator?
    
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        let container = AppDIContainer()
        window = UIWindow(windowScene: scene)
        appCoordinator = AppFlowCoordinator(window: window!, container: container)
        appCoordinator?.start()

        // TODO: 날씨 API 연동 검증용 임시 호출 — 확인 후 제거
        #if DEBUG
        Task {
            do {
                let weather = try await container.makeFetchCurrentWeatherUseCase().getWeather()
                AppLogger.network.debug("현재 날씨 조회 성공 — 도시=\(weather.cityName, privacy: .public), 기온=\(weather.temperature, privacy: .public)℃, 체감=\(weather.feelsLike, privacy: .public)℃, 습도=\(weather.humidity, privacy: .public)%, 상태=\(weather.description, privacy: .public)(\(weather.condition, privacy: .public))")
            } catch {
                AppLogger.network.error("현재 날씨 조회 실패: \(String(describing: error), privacy: .public)")
            }
        }
        #endif
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

