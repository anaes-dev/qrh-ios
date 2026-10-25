//
//  QuickActionTests.swift
//  qrhTests
//

import Foundation
import Testing
import UIKit
@testable import qrh

@MainActor
@Suite(.serialized)
struct QuickActionTests {

    let store = GuidelineStore()

    init() {
        UserDefaults.standard.removeObject(forKey: "recentGuidelines")
    }

    @Test func mostRecentFirstWithoutDuplicatesAndAtMostFour() {
        for code in ["2-5", "1-1", "3-8", "2-5", "4-1", "3-1"] {
            QuickActions.noteOpened(store.guideline(code: code)!)
        }
        QuickActions.update(store: store)
        let items = UIApplication.shared.shortcutItems ?? []
        #expect(items.compactMap(QuickActions.code(from:)) == ["3-1", "4-1", "2-5", "3-8"])
        #expect(items.first?.localizedTitle == store.guideline(code: "3-1")?.title)
        #expect(items.first?.localizedSubtitle == "3-1")
        UserDefaults.standard.removeObject(forKey: "recentGuidelines")
        UIApplication.shared.shortcutItems = []
    }

    @Test func otherShortcutTypesAreIgnored() {
        let item = UIApplicationShortcutItem(type: "other", localizedTitle: "x", localizedSubtitle: nil,
                                             icon: nil, userInfo: ["code": "2-5" as NSString])
        #expect(QuickActions.code(from: item) == nil)
    }
}
