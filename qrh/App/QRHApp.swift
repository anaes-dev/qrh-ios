//
//  QRHApp.swift
//  qrh
//

import SwiftUI

@main
struct QRHApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    init() {
#if DEBUG
//        UI tests: start as a fresh install
        if ProcessInfo.processInfo.arguments.contains("-resetDisclaimer") {
            UserDefaults.standard.removeObject(forKey: DisclaimerStatus.hasAcceptedKey)
            UserDefaults.standard.removeObject(forKey: DisclaimerStatus.acceptedBuildKey)
        }
#endif
        Appearance.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
