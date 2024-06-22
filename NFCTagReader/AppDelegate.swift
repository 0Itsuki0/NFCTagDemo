//
//  AppDelegate.swift
//  universalLinkDemo
//
//  Created by Itsuki on 2024/06/16.
//


import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil,
            sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
    
}
