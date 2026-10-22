//
//  RootView.swift
//  qrh
//
//  Navigation (a stack on iPhone; on iPad, a sidebar list beside the open
//  guideline's stack), link routing, the depth alert and the disclaimer.
//

import CoreSpotlight
import SwiftUI
import UIKit

struct RootView: View {
    @State private var store = GuidelineStore()
    @State private var router = Router()
    @AppStorage("hasAcceptedDisclaimer") private var hasAcceptedDisclaimer = false
    @State private var showDisclaimer = false
    @State private var reminder: ReminderState
    @State private var requests = OpenRequests.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var columns = NavigationSplitViewVisibility.all

    init() {
        let accepted = UserDefaults.standard.bool(forKey: "hasAcceptedDisclaimer")
        _reminder = State(initialValue: accepted ? .pending : .done)
    }

    var body: some View {
        navigation
        .environment(store)
        .environment(router)
        .environment(\.openURL, OpenURLAction { url in
//            Guideline links are pushed in-app; web and phone links open externally
            guard let code = LinkDetector.guidelineCode(from: url) else {
                return .systemAction
            }
            if store.guideline(code: code) != nil {
                router.push(code)
            }
            return .handled
        })
        .alert("Too many guidelines open", isPresented: $router.showDepthAlert) {
            Button("Close", role: .cancel) {}
        } message: {
            Text("Please do not try to open more than 20 guidelines at once")
        }
        .sheet(isPresented: $showDisclaimer) {
            DisclaimerView()
        }
        .onAppear {
            if !hasAcceptedDisclaimer {
                showDisclaimer = true
            }
#if DEBUG
//            UI tests: start with these guidelines open (-uiTestPath 3-8,2-8,...)
            if let codes = UserDefaults.standard.string(forKey: "uiTestPath") {
                router.path = codes.split(separator: ",").map(String.init)
            }
#endif
        }
        .task {
            await store.loadSearchIndex()
            await Spotlight.index(store.searchIndex)
        }
//        Spotlight results and Home Screen quick actions
        .onContinueUserActivity(CSSearchableItemActionType) { activity in
            requests.code = Spotlight.code(from: activity)
        }
        .onChange(of: requests.code, initial: true) {
            if let code = requests.code {
                requests.code = nil
                openFromSystem(code)
            }
        }
        .onChange(of: router.path) {
            if let guideline = router.path.last.flatMap(store.guideline(code:)) {
                QuickActions.noteOpened(guideline)
            }
        }
        .onChange(of: scenePhase) {
            if scenePhase == .background {
                QuickActions.update(store: store)
            }
        }
    }

//    Opened from outside the app: the guideline alone, on top of the list

    private func openFromSystem(_ code: String) {
        guard store.guideline(code: code) != nil else { return }
        router.open(code)
    }

    @ViewBuilder
    private var navigation: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            NavigationSplitView(columnVisibility: $columns, preferredCompactColumn: $router.compactColumn) {
                GuidelineListView(reminder: $reminder, isSidebar: true)
            } detail: {
//                The first guideline is the stack's root, so it has no back button
                NavigationStack(path: detailPath) {
                    Group {
                        if let code = router.path.first {
                            GuidelineDetailView(code: code)
                                .id(code)
                        } else {
                            ContentUnavailableView("No Guideline Selected", systemImage: "list.bullet",
                                                   description: Text("Choose a guideline from the list."))
                        }
                    }
                    .navigationDestination(for: String.self) { code in
                        GuidelineDetailView(code: code)
                    }
                }
            }
//            The list shows until a guideline is chosen; then the system
//            decides (beside it in landscape, hidden in portrait)
            .onChange(of: router.path.first) {
                columns = router.path.isEmpty ? .all : .automatic
            }
        } else {
            NavigationStack(path: $router.path) {
                GuidelineListView(reminder: $reminder)
                    .navigationDestination(for: String.self) { code in
                        GuidelineDetailView(code: code)
                    }
            }
        }
    }

    private var detailPath: Binding<[String]> {
        Binding {
            Array(router.path.dropFirst())
        } set: { tail in
            router.path = Array(router.path.prefix(1)) + tail
        }
    }
}


//    Navigation bar styling from the storyboard: red large titles. (Its
//    white inline titles on a red bar tint predate iOS 13 bar styling and are
//    unreadable on iOS 26's translucent bars, so they're dropped.)

@MainActor
enum Appearance {
    static func configure() {
        let bar = UINavigationBar.appearance()
        bar.largeTitleTextAttributes = [.foregroundColor: UIColor.systemRed]
        bar.prefersLargeTitles = true

//        Card deck page dots: the default white current dot is lost on light
//        backgrounds
        let dots = UIPageControl.appearance()
        dots.currentPageIndicatorTintColor = .label
        dots.pageIndicatorTintColor = .tertiaryLabel
    }
}


//    Sets the title the next screen's back button shows (the list's is "Home")

private struct BackButtonTitle: UIViewControllerRepresentable {
    let title: String

    func makeUIViewController(context: Context) -> Controller {
        Controller(title: title)
    }

    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.backTitle = title
        controller.apply()
    }

    final class Controller: UIViewController {
        var backTitle: String

        init(title: String) {
            backTitle = title
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) { fatalError() }

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            apply()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            apply()
        }

//        The screen's own controller is the ancestor directly inside the
//        navigation controller
        func apply() {
            var controller: UIViewController? = self
            while let current = controller, !(current.parent is UINavigationController) {
                controller = current.parent
            }
            controller?.navigationItem.backButtonTitle = backTitle
        }
    }
}

extension View {
    func backButtonTitle(_ title: String) -> some View {
        background(BackButtonTitle(title: title).frame(width: 0, height: 0).accessibilityHidden(true))
    }
}
