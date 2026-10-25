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
#if DEBUG
                .preferredColorScheme(Self.uiTestColorScheme)
#endif
        }
    }

#if DEBUG
//    UI tests (App Store screenshots): light or dark whatever the device's
//    setting (-uiTestAppearance dark)
    static var uiTestColorScheme: ColorScheme? {
        switch UserDefaults.standard.string(forKey: "uiTestAppearance") {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }
#endif
}
