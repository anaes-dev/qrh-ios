//
//  GuidelineDetailView.swift
//  qrh
//
//  One guideline's cards. Compact width: a single column. Regular width
//  (iPad): two independently scrolling columns, 60% steps and 40% callouts
//  and images.
//

import SwiftUI

struct GuidelineDetailView: View {
    let code: String

    @Environment(GuidelineStore.self) private var store
    @Environment(Router.self) private var router
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var cards: [RenderedCard]?
    @State private var expanded = Set<Int>()
    @State private var depth: Int?
    @State private var showPDF = false
    @State private var showDeck = false
//    A guideline link tapped in the card deck, opened once the deck has closed
    @State private var deckLink: String?
    @State private var focus: Router.Focus?
    @State private var scrolledToFocus = false

    private var guideline: Guideline? { store.guideline(code: code) }
    //    Two columns on iPad only, as before; large iPhones in landscape keep one
    private var isRegular: Bool {
        sizeClass == .regular && UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        ScrollViewReader { proxy in
            Group {
                if let cards = cards ?? store.cachedCards(for: code) {
                    if isRegular {
                        twoColumns(cards)
                    } else {
                        singleColumn(cards)
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .environment(\.searchHighlight, focus?.terms ?? [])
            .task {
                if cards == nil {
                    cards = await store.cards(for: code)
                }
                await scrollToFocus(proxy)
            }
        }
        .background(Color(.systemGray6))
        .navigationTitle(guideline?.title ?? code)
        .backButtonTitle(guideline?.title ?? code)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showDeck = true
                } label: {
                    Image(systemName: "rectangle.portrait.on.rectangle.portrait")
                }
                .tint(.primary)
                .disabled((cards ?? store.cachedCards(for: code)) == nil)
                .accessibilityLabel("Full screen cards")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showPDF = true
                } label: {
                    Image(systemName: "arrow.down.doc")
                }
                .tint(.primary)
                .accessibilityLabel("PDF")
            }
        }
        .fullScreenCover(isPresented: $showDeck, onDismiss: {
            if let code = deckLink {
                deckLink = nil
                router.push(code)
            }
        }) {
            CardDeckView(code: code, title: guideline?.title ?? code,
                         cards: cards ?? store.cachedCards(for: code) ?? []) { linked in
                deckLink = linked
            }
        }
        .sheet(isPresented: $showPDF) {
            if let url = guideline.flatMap({ URL(string: $0.url) }) {
                PDFSheet(url: url)
            }
        }
        .onAppear {
//            Remember where this guideline sits in the stack, for its breadcrumb
            if depth == nil {
                depth = router.path.count - 1
            }
        }
    }


//    Search result: open the boxes with matches, then scroll to the best card

    private func scrollToFocus(_ proxy: ScrollViewProxy) async {
        guard !scrolledToFocus else { return }
        scrolledToFocus = true
        focus = router.takeFocus(for: code)
        guard let focus, let cards else { return }
        for card in cards where card.kind.isCallout {
            if let text = card.searchText, focus.terms.contains(where: text.contains) {
                expanded.insert(card.index)
            }
        }
//        Let the expanded boxes lay out first
        try? await Task.sleep(for: .milliseconds(150))
        withAnimation {
            proxy.scrollTo(focus.card, anchor: .top)
        }
    }


//    Layouts

    private func singleColumn(_ cards: [RenderedCard]) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                breadcrumb
                ForEach(cards) { card in
                    cardRow(card)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func twoColumns(_ cards: [RenderedCard]) -> some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        breadcrumb
                        ForEach(cards.filter { !$0.kind.isRightColumn }) { card in
                            cardRow(card)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(width: geometry.size.width * 0.6)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(cards.filter(\.kind.isRightColumn)) { card in
                            cardRow(card)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(width: geometry.size.width * 0.4)
            }
        }
    }

    private func cardRow(_ card: RenderedCard) -> some View {
        CardView(card: card, code: code, isPad: isRegular,
                 expanded: expanded.contains(card.index)) {
            if expanded.contains(card.index) {
                expanded.remove(card.index)
            } else {
                expanded.insert(card.index)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .id(card.index)
    }


//    Breadcrumb for this guideline's position in the stack

    private var stack: [String] {
        guard let depth, depth < router.path.count else { return router.path }
        return Array(router.path.prefix(depth + 1))
    }

    @ViewBuilder
    private var breadcrumb: some View {
        let stack = stack
        if stack.count >= 2 {
            BreadcrumbBar(titles: stack.map { store.guideline(code: $0)?.title ?? $0 },
                          onHome: { router.popToRoot() },
                          onSelect: { router.popTo($0) })
        }
    }
}

#if DEBUG
#Preview("Detail iPhone") {
    PreviewData.detailPreview(code: "2-5")
}

#Preview("Detail iPhone dark") {
    PreviewData.detailPreview(code: "2-6")
        .preferredColorScheme(.dark)
}

#Preview("Detail iPad", traits: .landscapeLeft) {
    PreviewData.detailPreview(code: "2-6")
        .environment(\.horizontalSizeClass, .regular)
}

#Preview("Detail iPad dark", traits: .landscapeLeft) {
    PreviewData.detailPreview(code: "3-1")
        .environment(\.horizontalSizeClass, .regular)
        .preferredColorScheme(.dark)
}
#endif
