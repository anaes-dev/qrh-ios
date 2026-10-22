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

    var path = [String]() {
        didSet { prunePages() }
    }
    var showDepthAlert = false

//    Bumped each time the sidebar (or the system) opens a guideline, so
//    reopening the one already open starts it afresh
    private(set) var openCount = 0

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
        pages.removeAll()
        openCount += 1
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


//    Each open guideline's view state, by its position in the path, so it
//    survives the view being rebuilt (rotation, Split View and Stage Manager
//    resizing, the sidebar collapsing)

    @ObservationIgnored private var pages = [Int: (code: String, state: PageState)]()

    func pageState(depth: Int, code: String) -> PageState {
        if let page = pages[depth], page.code == code {
            return page.state
        }
        let state = PageState()
        pages[depth] = (code, state)
        return state
    }

//    Pushing a guideline over a closed one starts it afresh
    private func prunePages() {
        pages = pages.filter { depth, page in
            depth < path.count && path[depth] == page.code
        }
    }
}

//    What a guideline's view remembers: open boxes, the search that opened it
//    and where it's scrolled to

@Observable
@MainActor
final class PageState {
    var expanded = Set<Int>()
    var scrollPosition: RowID?
    var focus: Router.Focus?
    var tookFocus = false
    var openedFirstBox = false
}
