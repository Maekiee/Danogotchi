
import UIKit

final class MainTabViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configTabBarAppearance()
        createTabBarController()
    }
    
    let characterTabVm = CharacterTabViewModel()
    let wordTabVm = WordTabViewModel()
    let settingVm = SettingTabViewModel()

    private func createTabBarController() {
        
        let characterVC = CharacterTabViewController()
        let wordTabVC = WordTabViewController(viewModel: wordTabVm)
        let settingVC = SettingTabViewController()
        
        let firstTabNav = UINavigationController(rootViewController: characterVC)
        let secondTabNav = UINavigationController(rootViewController: wordTabVC)
        let thridTabNav = UINavigationController(rootViewController: settingVC)
        
        firstTabNav.tabBarItem = UITabBarItem(title: "캐릭터", image: UIImage(systemName: "house.fill"), selectedImage: UIImage(systemName: ""))
        secondTabNav.tabBarItem = UITabBarItem(title: "단어장", image: UIImage(systemName: "book.fill"), selectedImage: UIImage(systemName: ""))
        thridTabNav.tabBarItem = UITabBarItem(title: "설정", image: UIImage(systemName: "person.fill"), selectedImage: UIImage(systemName: ""))
        
        setViewControllers([firstTabNav, secondTabNav, thridTabNav], animated: false)
        
        [firstTabNav, secondTabNav, thridTabNav].forEach { nav in
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithTransparentBackground()
            navBarAppearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
            navBarAppearance.backgroundColor = UIColor.white.withAlphaComponent(0.1)
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.black]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
            navBarAppearance.shadowColor = .clear
            
            nav.navigationBar.standardAppearance = navBarAppearance
            nav.navigationBar.scrollEdgeAppearance = navBarAppearance
            nav.navigationBar.compactAppearance = navBarAppearance
        }
        
    }
    
    private func configTabBarAppearance() {
        let navigationBarAppearance = UINavigationBarAppearance()
        //        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.configureWithTransparentBackground()

        navigationBarAppearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
//        navigationBarAppearance.backgroundColor = AppColor.appBackgroundColor
        navigationBarAppearance.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        
        
//        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.black]
//        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        
        navigationBarAppearance.shadowColor = .clear
        
        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        
        
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemMaterial)
        tabBarAppearance.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        
        tabBarAppearance.shadowColor = .clear

        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.black
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.black]
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        self.tabBar.standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}


