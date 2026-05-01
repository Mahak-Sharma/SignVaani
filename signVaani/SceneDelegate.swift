//
//  SceneDelegate.swift
//  signVaani
//
//  Created by Shreya Bhardwaj on 1/30/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
//        //for orientation
//    func topViewController(from root: UIViewController?) -> UIViewController? {
//        
//        if let nav = root as? UINavigationController {
//            return topViewController(from: nav.visibleViewController)
//        }
//        
//        if let tab = root as? UITabBarController {
//            return topViewController(from: tab.selectedViewController)
//        }
//        
//        if let presented = root?.presentedViewController {
//            return topViewController(from: presented)
//        }
//        
//        return root
//    }
//
//    func windowScene(_ windowScene: UIWindowScene,
//                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
//        
//        let topVC = topViewController(from: window?.rootViewController)
//        return topVC?.supportedInterfaceOrientations ?? .portrait
//    }//for orientation
    func scene(_ scene: UIScene,
                 willConnectTo session: UISceneSession,
                 options connectionOptions: UIScene.ConnectionOptions) {

          guard let _ = (scene as? UIWindowScene) else { return }
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedIntroFlow")

        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        if hasSeenOnboarding {
            //Already seen → go to Home
            let homeVC = storyboard.instantiateViewController(withIdentifier: "HomeViewController")
            let nav = UINavigationController(rootViewController: homeVC)
            window?.rootViewController = nav
        } else {
            //First time → show onboarding
            let onboardingVC = storyboard.instantiateViewController(withIdentifier: "boardingViewController")
            let nav = UINavigationController(rootViewController: onboardingVC)
            window?.rootViewController = nav
        }

        window?.makeKeyAndVisible()
      }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

