//
//  Router.swift
//  qrh
//

import Observation
import SwiftUI

//    Navigation stack of open guidelines (by code), shared by the list,
//    guideline links and breadcrumbs.

@Observable
@MainActor
final class Router {

    static let maxDepth = 20

    var path = [String]()
    var showDepthAlert = false

//    Where a search result should open its guideline: the card to scroll to
//    and the words to highlight. Taken by the guideline's view when it appears.
    struct Focus: Hashable, Sendable {
        let code: String
        let card: Int
        let terms: [SearchTerm]
    }

    private(set) var pendingFocus: Focus?

//    iPad sidebar collapsed (Slide Over, narrow Split View): which column shows
    var compactColumn = NavigationSplitViewColumn.sidebar

    func takeFocus(for code: String) -> Focus? {
        guard let focus = pendingFocus, focus.code == code else { return nil }
        pendingFocus = nil
        return focus
    }

//    Returns false (and raises the alert) if 20 guidelines are already open

    @discardableResult
    func push(_ code: String, focus: Focus? = nil) -> Bool {
        guard path.count < Self.maxDepth else {
            showDepthAlert = true
            return false
        }
        pendingFocus = focus
        path.append(code)
        return true
    }

//    Replace the stack with one guideline (iPad sidebar, Spotlight, quick actions)

    func open(_ code: String, focus: Focus? = nil) {
        pendingFocus = focus
        path = [code]
        compactColumn = .detail
    }

//    Pop back so the guideline at `index` in the path is on top

    func popTo(_ index: Int) {
        guard index >= 0, index < path.count else { return }
        path.removeLast(path.count - index - 1)
    }

    func popToRoot() {
        path.removeAll()
        compactColumn = .sidebar
    }
}
