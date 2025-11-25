//
//  AppDelegate.swift
//  MyCal360
//
//  Created by Shivang Gulati on 07/11/25.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        checkAndRestoreSession()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    

    private func checkAndRestoreSession() {
        if SessionManager.shared.isSessionValid(),
           let userId = SessionManager.shared.getUserId() {
            
            print("✅ Valid session found, auto-configuring FamilyStore")
            AuthSession.shared.loadUser()
            // Configure FamilyStore for the logged-in user
            FamilyStore.shared.configureForUser(id: userId, migrateLegacyIfPresent: false) { result in
                switch result {
                case .success:
                    print("✅ Auto-login successful")
                case .failure(let error):
                    print("⚠️ Auto-login failed: \(error.localizedDescription)")
                    SessionManager.shared.clearSession()
                }
            }
        } else {
            print("ℹ️ No valid session, user needs to log in")
        }
    }
    
}

