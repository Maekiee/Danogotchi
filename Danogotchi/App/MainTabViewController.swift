
import UIKit

final class MainTabViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        createTabBarController()
    }
    

    private func createTabBarController() {
        let characterVC = UIViewController()
        let vocabVC = UIViewController()
        let settingVC = UIViewController()
        
        let firstTabNav = UINavigationController(rootViewController: characterVC)
        
        let secondTabNav = UINavigationController(rootViewController: vocabVC)
        
        let thridTabNav = UINavigationController(rootViewController: settingVC)
        
        firstTabNav.tabBarItem = UITabBarItem(title: "캐릭터", image: UIImage(systemName: "house.fill"), selectedImage: UIImage(systemName: ""))
        secondTabNav.tabBarItem = UITabBarItem(title: "단어장", image: UIImage(systemName: "magnifyingglass"), selectedImage: UIImage(systemName: ""))
        thridTabNav.tabBarItem = UITabBarItem(title: "설정", image: UIImage(systemName: "person.fill"), selectedImage: UIImage(systemName: ""))
        
        setViewControllers([firstTabNav, secondTabNav, thridTabNav], animated: false)
        configTabBarAppearance()
    }
    
    private func configTabBarAppearance() {
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = .white
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        navigationBarAppearance.shadowColor =  UIColor.gray
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .white
        tabBarAppearance.shadowColor = .clear
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.black
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.black]
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}


