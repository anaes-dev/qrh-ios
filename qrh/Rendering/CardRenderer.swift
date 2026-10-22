//
//  CardRenderer.swift
//  qrh
//

import Foundation
import SwiftUI

//    Turns a guideline's cards into RenderedCards. Pure and nonisolated, so it
//    runs off the main thread.

enum CardRenderer {

    static func render(_ cards: [Card], code: String) -> [RenderedCard] {
        cards.enumerated().map { index, card in
            let kind = CardKind(type: card.type)
            return RenderedCard(index: index, card: card, kind: kind,
                                blocks: blocks(for: card, kind: kind, code: code, row: index))
        }
    }

    static func blocks(for card: Card, kind: CardKind, code: String, row: Int) -> [RichBlock] {
        switch kind {
        case .intro, .step, .stepBodyOnly, .callout:
            let types = LinkDetector.dataDetectorTypes(for: kind, code: code, row: row)
            return HTMLRenderer.render(card.body).map { LinkDetector.addLinks(to: $0, detecting: types) }
        case .start:
            return HTMLRenderer.render(card.body)
        case .unknown:
//            Shown as plain body text, as before
            var text = AttributedString(card.body)
            text.swiftUI.font = HTMLRenderer.font()
            return [.paragraph(text)]
        case .image, .version, .warning:
            return []
        }
    }
}
