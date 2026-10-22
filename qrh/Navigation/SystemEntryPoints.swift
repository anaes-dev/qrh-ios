//
//  SystemEntryPoints.swift
//  qrh
//
//  Ways into a guideline from outside the app:
//  - Spotlight: every guideline is indexed (title, code and text), and a
//    result opens it via RootView's onContinueUserActivity;
//  - Home Screen quick actions: the last four guidelines opened, delivered
//    to the scene delegate.
//

import CoreSpotlight
import SwiftUI
import UIKit

//    Guidelines asked for by the system, picked up by RootView

@Observable
@MainActor
final class OpenRequests {
    static let shared = OpenRequests()

    var code: String?
}


//    Spotlight

@MainActor
enum Spotlight {

    private static let indexedVersionKey = "spotlightIndexedVersion"

//    The guideline code for a Spotlight result
    static func code(from activity: NSUserActivity) -> String? {
        activity.userInfo?[CSSearchableItemActivityIdentifier] as? String
    }

//    Indexes once per app build, since the guidelines only change with the app.
//    Items are keyed by code, so reindexing replaces them.

    static func index(_ index: SearchIndex) async {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        guard CSSearchableIndex.isIndexingAvailable(),
              UserDefaults.standard.string(forKey: indexedVersionKey) != version,
              index.entries.contains(where: { !$0.cards.isEmpty }) else { return }

        let items = index.entries.map { entry in
            let attributes = CSSearchableItemAttributeSet(contentType: .text)
            attributes.title = entry.guideline.title
            attributes.contentDescription = "\(entry.guideline.code) · " + (entry.cards.first?.text.original ?? "")
            attributes.textContent = entry.cards.map(\.text.original).joined(separator: "\n")
            attributes.keywords = [entry.guideline.code, "QRH"]
            return CSSearchableItem(uniqueIdentifier: entry.guideline.code, domainIdentifier: "guidelines",
                                    attributeSet: attributes)
        }
        do {
            try await CSSearchableIndex.default().indexSearchableItems(items)
            UserDefaults.standard.set(version, forKey: indexedVersionKey)
        } catch {
//            Not essential; tried again next launch
        }
    }
}


//    Home Screen quick actions

@MainActor
enum QuickActions {

    static let type = "dev.anaes.qrh.guideline"
    private static let recentsKey = "recentGuidelines"
    private static let maxRecents = 4

    static func noteOpened(_ guideline: Guideline) {
        var recents = UserDefaults.standard.stringArray(forKey: recentsKey) ?? []
        recents.removeAll { $0 == guideline.code }
        recents.insert(guideline.code, at: 0)
        UserDefaults.standard.set(Array(recents.prefix(maxRecents)), forKey: recentsKey)
    }

//    Sets the quick actions from the recents (called as the app goes to the
//    background, which is when the system reads them)

    static func update(store: GuidelineStore) {
        let recents = UserDefaults.standard.stringArray(forKey: recentsKey) ?? []
        UIApplication.shared.shortcutItems = recents.compactMap(store.guideline(code:)).map { guideline in
            UIApplicationShortcutItem(type: type, localizedTitle: guideline.title,
                                      localizedSubtitle: guideline.code,
                                      icon: UIApplicationShortcutIcon(systemImageName: "doc.text"),
                                      userInfo: ["code": guideline.code as NSString])
        }
    }

    static func code(from item: UIApplicationShortcutItem) -> String? {
        item.type == type ? item.userInfo?["code"] as? String : nil
    }
}


//    Delegates, for quick actions (SwiftUI has no modifier for them)

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting session: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: session.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}

final class SceneDelegate: NSObject, UIWindowSceneDelegate {

//    Launched from a quick action
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        if let item = connectionOptions.shortcutItem {
            OpenRequests.shared.code = QuickActions.code(from: item)
        }
    }

//    Already running
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        let code = QuickActions.code(from: shortcutItem)
        OpenRequests.shared.code = code
        completionHandler(code != nil)
    }
}
