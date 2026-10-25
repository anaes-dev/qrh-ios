//
//  GuidelineDetailView.swift
//  qrh
//
//  One guideline's cards. Compact width: a single column. Regular width
//  (iPad): two independently scrolling columns, 60% steps and 40% callouts
//  and images, if the guideline has any. Branches (ForkView) are shown
//  side by side or stacked, as they fit.
//

import SwiftUI

struct GuidelineDetailView: View {
    let code: String

    @Environment(GuidelineStore.self) private var store
    @Environment(Router.self) private var router
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var cards: [RenderedCard]?
    @State private var depth: Int?
//    Kept by the router, so it survives this view being rebuilt
    @State private var page = PageState()
    @State private var showPDF = false
    @State private var showDeck = false
//    A guideline link tapped in the card deck, opened once the deck has closed
    @State private var deckLink: String?

    private var guideline: Guideline? { store.guideline(code: code) }
    //    Two columns on iPad only, as before; large iPhones in landscape keep one
    private var isRegular: Bool {
        sizeClass == .regular && UIDevice.current.userInterfaceIdiom == .pad
    }

//    Boxes and images go beside the steps, if the guideline has any
    private func hasSideColumn(_ cards: [RenderedCard]) -> Bool {
        isRegular && cards.contains(where: \.kind.isRightColumn)
    }

    var body: some View {
        ScrollViewReader { proxy in
            Group {
                if let cards = cards ?? store.cachedCards(for: code) {
                    if hasSideColumn(cards) {
                        twoColumns(cards)
                    } else {
                        singleColumn(cards)
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .environment(\.searchHighlight, page.focus?.terms ?? [])
            .task {
                attach()
                if cards == nil {
                    cards = await store.cards(for: code)
                }
                if let cards {
                    openFirstBox(cards)
                }
                await scrollToFocus(proxy)
            }
//            A link to this guideline, from itself or its card deck
            .onChange(of: router.startRequest) {
                guard depth == router.path.count - 1 else { return }
                withAnimation {
                    proxy.scrollTo(RowID.top, anchor: .top)
                }
            }
        }
        .background(Color(.systemGray6))
        .navigationTitle(guideline?.title ?? code)
//        iPad: an inline title over an always-shown bar background. The bar
//        follows only one scroll view, so with two columns a large title
//        collapsed with whichever was scrolled, and the background appeared
//        only once the followed one scrolled. (The red title is drawn below,
//        as SwiftUI's bar background replaces the bar's own title colour.)
        .navigationBarTitleDisplayMode(isRegular ? .inline : .automatic)
        .toolbarBackground(isRegular ? .visible : .automatic, for: .navigationBar)
        .backButtonTitle(guideline?.title ?? code)
//        iPad: the sidebar and breadcrumb already go back, so no back button
//        beside them. (Compact width, e.g. Slide Over, keeps it, with its
//        swipe back.)
        .navigationBarBackButtonHidden(isRegular && stack.count >= 2)
        .toolbar {
            if isRegular {
                ToolbarItem(placement: .principal) {
                    Text(guideline?.title ?? code)
                        .font(.headline)
                        .foregroundStyle(Color(.systemRed))
                        .lineLimit(1)
                        .accessibilityAddTraits(.isHeader)
                }
            }
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
                router.follow(code)
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
            attach()
            if let cached = store.cachedCards(for: code) {
                openFirstBox(cached)
            }
        }
    }


//    Remember where this guideline sits in the stack, for its breadcrumb, and
//    pick up its saved state

    private func attach() {
        guard depth == nil else { return }
        let depth = max(router.path.count - 1, 0)
        self.depth = depth
        page = router.pageState(depth: depth, code: code)
    }


//    Instructions for use (0-3) opens with its first box expanded, as on
//    Android. Once only, so the user's own toggles are kept.

    private func openFirstBox(_ cards: [RenderedCard]) {
        guard !page.openedFirstBox else { return }
        page.openedFirstBox = true
        if code == "0-3", let box = cards.first(where: { $0.card.type == 5 }) {
            page.expanded.insert(box.index)
        }
    }


//    Search result: open the boxes with matches, then scroll to the best card

    private func scrollToFocus(_ proxy: ScrollViewProxy) async {
        guard !page.tookFocus else { return }
        page.tookFocus = true
        page.focus = router.takeFocus(for: code)
        guard let focus = page.focus, let cards else { return }
        for card in cards where card.kind.isCallout {
            if let text = card.searchText, focus.terms.contains(where: text.contains) {
                page.expanded.insert(card.index)
            }
        }
        var target = focus.card
        if hasSideColumn(cards), let kept = cards.sideColumn().merged[target] {
            target = kept
        }
//        Let the expanded boxes lay out first
        try? await Task.sleep(for: .milliseconds(150))
        withAnimation {
            proxy.scrollTo(RowID.card(target), anchor: .top)
        }
    }


//    Layouts. Plain stacks, not lazy ones: a guideline is a few dozen cards at
//    most, already rendered, and a fork is one tall row. A lazy stack only
//    estimated the rows off screen, and correcting those estimates while
//    scrolling past or to a fork could keep the page re-laying out forever.
//    The scroll position lives in the router's page state, so a rebuilt page
//    (rotation, Split View and Stage Manager resizing) keeps its place.

    private func singleColumn(_ cards: [RenderedCard]) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                top
                breadcrumb
                ForEach(ContentBlock.group(cards)) { block in
                    blockRow(block, boxesOpen: false)
                }
            }
            .scrollTargetLayout()
            .padding(.vertical, 8)
        }
        .scrollPosition(id: $page.scrollPosition, anchor: .top)
    }

    private func twoColumns(_ cards: [RenderedCard]) -> some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        top
                        breadcrumb
                        ForEach(ContentBlock.group(cards.filter { !$0.kind.isRightColumn })) { block in
                            blockRow(block, boxesOpen: true)
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.vertical, 8)
                }
                .scrollPosition(id: $page.scrollPosition, anchor: .top)
                .frame(width: geometry.size.width * 0.6)

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(cards.sideColumn().cards) { card in
                            cardRow(card, boxesOpen: true)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(width: geometry.size.width * 0.4)
            }
        }
    }

    @ViewBuilder
    private func blockRow(_ block: ContentBlock, boxesOpen: Bool) -> some View {
        switch block {
        case .card(let card):
            cardRow(card, boxesOpen: boxesOpen)
        case .fork(let fork):
            ForkView(fork: fork) { card, header in
                cardRow(card, branch: header, boxesOpen: boxesOpen)
            }
            .id(RowID.fork(fork.id))
        }
    }

    private func cardRow(_ card: RenderedCard, branch: RenderedCard? = nil, boxesOpen: Bool) -> some View {
        CardView(card: card, code: code, isPad: boxesOpen, branch: branch,
                 expanded: page.expanded.contains(card.index)) {
            if page.expanded.contains(card.index) {
                page.expanded.remove(card.index)
            } else {
                page.expanded.insert(card.index)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
//        No search highlights in the version, disclaimer and licence footer
        .environment(\.searchHighlight, isFooter(card) ? [] : page.focus?.terms ?? [])
        .id(RowID.card(card.index))
    }

    private func isFooter(_ card: RenderedCard) -> Bool {
        guard let start = (cards ?? store.cachedCards(for: code))?.firstIndex(where: { $0.kind == .version }) else {
            return false
        }
        return card.index >= start
    }


//    The top of the page, to scroll back to

    private var top: some View {
        Color.clear
            .frame(height: 0)
            .id(RowID.top)
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
