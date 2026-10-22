//
//  CardDeckView.swift
//  qrh
//
//  Full-screen card view (as in qrh-android): one card per page with larger
//  text, swiped left and right, with page dots that can be tapped or
//  scrubbed. Boxes are always open. Boilerplate (START, version, the
//  disclaimer and the copyright footer) is left out. A card in a branch
//  shows the branch's condition, so 3-10's two step 6s can be told apart.
//
//  Guideline links close the deck and open the linked guideline in the
//  normal view, so going back returns to this guideline's normal view.
//

import SwiftUI

struct CardDeckView: View {
    let code: String
    let title: String
    let cards: [RenderedCard]
//    Called with a linked guideline's code, after the deck has closed
    let openGuideline: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.openURL) private var openURL
    @State private var page = 0

    static func deckCards(_ cards: [RenderedCard]) -> [RenderedCard] {
        cards.prefix { $0.kind != .warning }.filter { card in
            switch card.kind {
            case .start, .version, .warning, .branch: false
            default: true
            }
        }
    }

    var body: some View {
        let deck = Self.deckCards(cards)
        let headers = cards.branchHeaders
        NavigationStack {
            TabView(selection: $page) {
                ForEach(Array(deck.enumerated()), id: \.element.id) { offset, card in
                    cardPage(card, branch: headers[card.card.branch])
                        .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
//            Larger text on the cards only; the bar keeps the system size
            .dynamicTypeSize(Self.largerSize(than: typeSize))
            .background(Color(.systemGray6))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton { dismiss() }
                }
//                Title with the position under it. (As a trailing item the
//                counter overflowed iOS 26's fixed-width bar button slot.)
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(title)
                            .font(.headline)
                            .lineLimit(1)
                        Text("\(page + 1) of \(deck.count)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Color(.secondaryLabel))
                            .accessibilityLabel("Card \(page + 1) of \(deck.count)")
                    }
                }
            }
        }
        .environment(\.openURL, OpenURLAction { url in
            guard let linked = LinkDetector.guidelineCode(from: url) else {
                openURL(url)
                return .handled
            }
            openGuideline(linked)
            dismiss()
            return .handled
        })
    }

//    A card, centred when it's short, scrolling when it's long. The bottom
//    inset keeps it clear of the page dots.

    private func cardPage(_ card: RenderedCard, branch: RenderedCard?) -> some View {
        GeometryReader { geometry in
            ScrollView {
                CardView(card: card, code: code, isPad: true, branch: branch, showsCondition: true)
//                    Readable line lengths on iPad
                    .frame(maxWidth: 720)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 56)
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height, alignment: .center)
            }
        }
    }

//    Three sizes up, but no bigger than accessibility 2, so long cards still fit

    static func largerSize(than size: DynamicTypeSize) -> DynamicTypeSize {
        let sizes = DynamicTypeSize.allCases
        let index = sizes.firstIndex(of: size) ?? sizes.firstIndex(of: .large)!
        let cap = sizes.firstIndex(of: .accessibility2)!
        return sizes[min(max(index + 3, sizes.firstIndex(of: .xxxLarge)!), cap)]
    }
}

#if DEBUG
#Preview("Card deck") {
    CardDeckView(code: "2-5", title: "Hypertension", cards: PreviewData.cards) { _ in }
}

#Preview("Card deck dark") {
    CardDeckView(code: "2-5", title: "Hypertension", cards: PreviewData.cards) { _ in }
        .preferredColorScheme(.dark)
}
#endif
