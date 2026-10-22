//
//  ContentBlocks.swift
//  qrh
//
//  A guideline's cards grouped for display. Most cards stand alone; a fork is
//  a run of alternative branches (3-7's airway and non-airway fire, 3-10's
//  circulatory arrest or not) that share step numbers. Each branch is its
//  type 13 header followed by the cards tagged with the header's branch id.
//  A branch ends at the next header or the first card with another id.
//

import Foundation

struct Branch: Hashable, Sendable {
    let header: RenderedCard
    let cards: [RenderedCard]

    var id: String { header.card.branch }
}

struct Fork: Hashable, Sendable {
    let branches: [Branch]

//    The first header's index, which is unique within the guideline
    var id: Int { branches[0].header.index }

    var cards: [RenderedCard] {
        branches.flatMap { [$0.header] + $0.cards }
    }
}

enum ContentBlock: Hashable, Sendable, Identifiable {
    case card(RenderedCard)
    case fork(Fork)

    var id: RowID {
        switch self {
        case .card(let card): .card(card.index)
        case .fork(let fork): .fork(fork.id)
        }
    }

    var cards: [RenderedCard] {
        switch self {
        case .card(let card): [card]
        case .fork(let fork): fork.cards
        }
    }

    static func group(_ cards: [RenderedCard]) -> [ContentBlock] {
        var blocks = [ContentBlock]()
        var i = 0
        while i < cards.count {
            guard cards[i].kind == .branch else {
                blocks.append(.card(cards[i]))
                i += 1
                continue
            }
            var branches = [Branch]()
            while i < cards.count, cards[i].kind == .branch {
                let header = cards[i]
                let id = header.card.branch
                i += 1
                let start = i
                while i < cards.count, !id.isEmpty, cards[i].kind != .branch, cards[i].card.branch == id {
                    i += 1
                }
                branches.append(Branch(header: header, cards: Array(cards[start..<i])))
            }
            blocks.append(.fork(Fork(branches: branches)))
        }
        return blocks
    }
}

//    Scroll targets in a guideline: a card (anywhere, including inside a
//    fork) or a whole fork

enum RowID: Hashable, Sendable {
    case card(Int)
    case fork(Int)
}

extension Array where Element == RenderedCard {

//    Each branch id's header, for labelling the cards in that branch

    var branchHeaders: [String: RenderedCard] {
        var headers = [String: RenderedCard]()
        for card in self where card.kind == .branch && !card.card.branch.isEmpty {
            headers[card.card.branch] = headers[card.card.branch] ?? card
        }
        return headers
    }

//    The side column on iPad: boxes repeated in each branch (3-10's Box A)
//    once only. `merged` maps each dropped copy's index to the one kept.

    func sideColumn() -> (cards: [RenderedCard], merged: [Int: Int]) {
        var kept = [RenderedCard]()
        var merged = [Int: Int]()
        for card in self where card.kind.isRightColumn {
            if !card.card.branch.isEmpty, let original = kept.first(where: {
                !$0.card.branch.isEmpty && $0.card.branch != card.card.branch
                    && $0.card.type == card.card.type && $0.card.head == card.card.head
                    && $0.card.body == card.card.body && $0.card.step == card.card.step
            }) {
                merged[card.index] = original.index
            } else {
                kept.append(card)
            }
        }
        return (kept, merged)
    }
}
