import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // Only check if user has completed signup
        let hasCompletedSignup = UserDefaults.standard.bool(forKey: "hasCompletedSignup")
        
        print("========== SCENE DELEGATE DEBUG ==========")
        print("hasCompletedSignup: \(hasCompletedSignup)")
        print("==========================================")
        
        if hasCompletedSignup {
            // User has completed signup, go directly to home
            print("✅ SIGNUP COMPLETED - Going directly to HOME SCREEN")
            let homeVC = storyboard.instantiateViewController(withIdentifier: "HomeViewController")
            let navController = UINavigationController(rootViewController: homeVC)
            window?.rootViewController = navController
        } else {
            // User hasn't signed up, show onboarding flow
            print("❌ SIGNUP NOT COMPLETED - Showing Boarding Screen")
            let boardingVC = storyboard.instantiateViewController(withIdentifier: "boardingViewController")
            let navController = UINavigationController(rootViewController: boardingVC)
            window?.rootViewController = navController
        }
        
        window?.makeKeyAndVisible()
    }
}
