//
//  AppDelegate.swift
//  qrh
//
//  Created by user185107 on 10/13/20.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let htmlInput = "<span>HTML frameworks initialised</span>"
        
        let attrStrFromHtml = try! NSAttributedString(
            data: htmlInput.data(using: .utf8)!,
            options: [.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil)
        
        print(attrStrFromHtml.string)
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    
    

}

