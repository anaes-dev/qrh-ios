//
//  Card.swift
//  qrh
//

import Foundation

//    One card of a guideline's content in data.json. The format is shared with
//    qrh-android, so the keys must not change.
//
//    branch: the alternative path the card belongs to ("arrest", "no-arrest"),
//    on the branch's type 13 header and each card in it; "" (no key) outside
//    a branch. Missing keys decode as empty, so a card is never dropped.
//
//    table: optional, on boxes (types 5-9) only. Drawn instead of the body,
//    which still holds the same numbers for search and for app versions
//    without tables.

struct Card: Codable, Hashable, Sendable {
    var type: Int
    var head: String
    var body: String
    var step: String
    var branch: String = ""
    var table: CardTable?

    init(type: Int, head: String, body: String, step: String, branch: String = "", table: CardTable? = nil) {
        self.type = type
        self.head = head
        self.body = body
        self.step = step
        self.branch = branch
        self.table = table
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = (try? container.decode(Int.self, forKey: .type)) ?? 0
        head = (try? container.decode(String.self, forKey: .head)) ?? ""
        body = (try? container.decode(String.self, forKey: .body)) ?? ""
        step = (try? container.decode(String.self, forKey: .step)) ?? ""
        branch = (try? container.decode(String.self, forKey: .branch)) ?? ""
        table = try? container.decodeIfPresent(CardTable.self, forKey: .table)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(head, forKey: .head)
        try container.encode(body, forKey: .body)
        try container.encode(step, forKey: .step)
        if !branch.isEmpty {
            try container.encode(branch, forKey: .branch)
        }
        try container.encodeIfPresent(table, forKey: .table)
    }

    private enum CodingKeys: String, CodingKey {
        case type, head, body, step, branch, table
    }
}


//    A box's table (4-1's oxygen cylinder contents). Plain-text cells; every
//    row is as wide as columns, and its first cell names the row.

struct CardTable: Codable, Hashable, Sendable {
    var columns: [String]
    var rows: [[String]]

//    What VoiceOver says for a row: "Size C: 25% full (34 bar), 43 litres;
//    50% full (69 bar), 85 litres; ..."

    func spokenRow(_ row: [String]) -> String {
        guard let name = row.first else { return "" }
        let values = zip(columns.dropFirst(), row.dropFirst()).map { column, cell in
            "\(column), \(Self.spoken(cell))"
        }
        let title = columns.first.map { "\($0) \(name)" } ?? name
        return values.isEmpty ? title : "\(title): \(values.joined(separator: "; "))"
    }

//    "43 L" is spoken as "43 litres"

    static func spoken(_ cell: String) -> String {
        cell.replacing(/(\d)\s+L\b/) { "\($0.1) litres" }
    }
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
    case branch             // 13: a branch's condition ("If circulatory arrest:")
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
        case 13: self = .branch
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

//    The condition as VoiceOver says it after a step number: "If circulatory
//    arrest:" becomes "if circulatory arrest"

    var spokenCondition: String {
        var text = blocks.plainText.trimmingCharacters(in: .whitespacesAndNewlines)
        while text.hasSuffix(":") {
            text.removeLast()
        }
        guard let first = text.first else { return text }
        return first.lowercased() + text.dropFirst()
    }
}
