//
//  AppDelegate.swift
//  MobileTest
//
//  Created by 郭嘉俊 on 2025/9/26.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    /*
     去掉Scene, 使用Window
     */
    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        
        window?.rootViewController = BaseNavigationController.init(rootViewController: MainViewController())
        window?.makeKeyAndVisible()
        
        return true
    }


}

