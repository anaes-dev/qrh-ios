//
//  GuidelineListView.swift
//  qrh
//
//  The searchable guideline list, with the About button and the launch
//  reminder banner.
//

import SwiftUI
import UIKit

//    The launch reminder runs once per launch, and only if the disclaimer was
//    already accepted at launch

enum ReminderState {
    case pending, showing, done
}

struct GuidelineListView: View {
    @Binding var reminder: ReminderState
//    iPad: the list is a sidebar beside the open guideline, which it replaces
    var isSidebar = false

    @Environment(GuidelineStore.self) private var store
    @Environment(Router.self) private var router

    @State private var query = ""
//    The query, kept across relaunches. (Binding the search field straight
//    to it lost keystrokes typed quickly.)
    @SceneStorage("searchQuery") private var savedQuery = ""
    @State private var restoredQuery = false
    @State private var showAbout = false
    @State private var listWidth: CGFloat?

//    nil when not searching

    private var results: [SearchResult]? {
        query.trimmingCharacters(in: .whitespaces).isEmpty ? nil : store.searchIndex.search(query)
    }

    var body: some View {
        let results = results
        List {
            if let results {
                ForEach(results) { result in
                    row(result.guideline, result: result)
                }
            } else {
                ForEach(store.guidelines) { guideline in
                    row(guideline)
                }
            }
        }
        .listStyle(.plain)
        .overlay {
            if results?.isEmpty == true {
                Text("No Results")
                    .font(.body)
                    .foregroundStyle(Color(.label))
            }
        }
        .navigationTitle("QRH")
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search guidelines")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAbout = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .tint(.primary)
                .accessibilityLabel("About")
            }
        }
        .backButtonTitle("Home")
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .overlay(alignment: .bottom) {
            if reminder == .showing {
                LaunchReminderBanner()
                    .padding(.bottom, 8)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .onScrollStarted { fadeReminder() }
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { width in
//            Rotation. Height changes as the bars settle, and the first
//            layout pass has zero width, so neither counts.
            guard width > 0 else { return }
            if let listWidth, listWidth != width {
                hideReminder()
            }
            listWidth = width
        }
//        Restored once, when the scene's saved state arrives
        .onChange(of: savedQuery, initial: true) {
            if !restoredQuery && !savedQuery.isEmpty {
                restoredQuery = true
                if query.isEmpty {
                    query = savedQuery
                }
            }
        }
        .onChange(of: query) {
            restoredQuery = true
            savedQuery = query
        }
        .task {
            await runReminder()
        }
    }


    private func row(_ guideline: Guideline, result: SearchResult? = nil) -> some View {
        Button {
            hideReminder()
            open(guideline, result: result)
        } label: {
            if case .content(_, let snippet) = result?.match {
                GuidelineRow(guideline: guideline, highlight: result?.terms ?? [], snippet: snippet)
            } else {
                GuidelineRow(guideline: guideline, highlight: result?.terms ?? [])
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 8))
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
        .listRowBackground(isSidebar && router.path.first == guideline.code ? Self.selection : nil)
        .accessibilityAddTraits(isSidebar && router.path.first == guideline.code ? .isSelected : [])
    }

//    The open guideline's row in the sidebar: a pale tint of the bar red in
//    light mode, a lifted grey in dark mode

    static let selection = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0x3A / 255, green: 0x3A / 255, blue: 0x3A / 255, alpha: 1)
            : UIColor(red: 0xFF / 255, green: 0xDA / 255, blue: 0xD6 / 255, alpha: 1)
    })

//    A match inside a guideline opens it at the matching card, with the
//    search words highlighted

    private func open(_ guideline: Guideline, result: SearchResult?) {
        var focus: Router.Focus?
        if case .content(let card, _) = result?.match, let result {
            focus = Router.Focus(code: guideline.code, card: card, terms: result.terms)
        }
        if isSidebar {
            router.open(guideline.code, focus: focus)
        } else {
            router.push(guideline.code, focus: focus)
        }
    }


//    Reminder: fade in after 0.2 s over 0.6 s, fade out at 5 s

    private func runReminder() async {
        if reminder == .pending {
            try? await Task.sleep(for: .milliseconds(200))
            guard reminder == .pending else { return }
            withAnimation(.linear(duration: 0.6)) {
                reminder = .showing
            }
        }
//        Also if the view (and this task) restarted while it was showing
        guard reminder == .showing else { return }
        try? await Task.sleep(for: .milliseconds(4800))
        fadeReminder()
    }

    private func fadeReminder() {
        guard reminder != .done else { return }
        withAnimation(.linear(duration: 0.6)) {
            reminder = .done
        }
    }

    private func hideReminder() {
        reminder = .done
    }
}


//    Scroll detection for the reminder: scroll phases from iOS 18, a
//    simultaneous drag before that

private struct ScrollStartedModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.onScrollPhaseChange { _, phase in
//                User-driven scrolling only, not layout or programmatic scrolls
                if phase == .tracking || phase == .interacting { action() }
            }
        } else {
            content.simultaneousGesture(DragGesture(minimumDistance: 10).onChanged { _ in action() })
        }
    }
}

extension View {
    func onScrollStarted(perform action: @escaping () -> Void) -> some View {
        modifier(ScrollStartedModifier(action: action))
    }
}

#if DEBUG
#Preview("List") {
    PreviewData.listPreview(reminder: .done)
}

#Preview("List with reminder") {
    PreviewData.listPreview(reminder: .showing)
}

#Preview("List dark") {
    PreviewData.listPreview(reminder: .showing)
        .preferredColorScheme(.dark)
}
#endif
