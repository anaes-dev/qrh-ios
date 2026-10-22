//
//  Card.swift
//  qrh
//

import Foundation

//    One card of a guideline's content in data.json. The format is shared with
//    qrh-android, so the keys must not change.

struct Card: Codable, Hashable, Sendable {
    var type: Int
    var head: String
    var body: String
    var step: String
}


//    Card types as used in the JSON

enum CalloutColor: Hashable, Sendable, CaseIterable {
    case orange, blue, green, gray, purple
}

enum CardKind: Hashable, Sendable {
    case intro              // 1
    case start              // 2
    case step               // 3: badge, head and body
    case stepBodyOnly       // 4: badge and body
    case callout(CalloutColor) // 5-9
    case image              // 10
    case version            // 11
    case warning            // 12
    case unknown

    init(type: Int) {
        switch type {
        case 1: self = .intro
        case 2: self = .start
        case 3: self = .step
        case 4: self = .stepBodyOnly
        case 5: self = .callout(.orange)
        case 6: self = .callout(.blue)
        case 7: self = .callout(.green)
        case 8: self = .callout(.gray)
        case 9: self = .callout(.purple)
        case 10: self = .image
        case 11: self = .version
        case 12: self = .warning
        default: self = .unknown
        }
    }

    var isCallout: Bool {
        if case .callout = self { return true }
        return false
    }

//    On iPad, callouts and images go in the right-hand (40%) column

    var isRightColumn: Bool {
        isCallout || self == .image
    }
}


//    A card with its body HTML already rendered, ready for display

struct RenderedCard: Identifiable, Hashable, Sendable {
    let index: Int
    let card: Card
    let kind: CardKind
    let blocks: [RichBlock]

    var id: Int { index }
}
