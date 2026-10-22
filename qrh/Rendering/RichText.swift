//
//  RichText.swift
//  qrh
//

import Foundation

//    Rendered card body: a sequence of paragraphs and bullet lists. Line
//    breaks inside a paragraph or bullet item are "\n" characters.

enum RichBlock: Hashable, Sendable {
    case paragraph(AttributedString)
    case bulletList([AttributedString])

    var plainText: String {
        switch self {
        case .paragraph(let text):
            return String(text.characters)
        case .bulletList(let items):
            return items.map { "• " + String($0.characters) }.joined(separator: "\n")
        }
    }
}

extension Array where Element == RichBlock {
    var plainText: String {
        map(\.plainText).joined(separator: "\n")
    }
}

extension AttributedString {

//    Copy with leading and trailing whitespace (including newlines) removed

    func trimmingWhitespace() -> AttributedString {
        let chars = characters
        guard let first = chars.firstIndex(where: { !$0.isWhitespace }),
              let last = chars.lastIndex(where: { !$0.isWhitespace }) else {
            return AttributedString()
        }
        return AttributedString(self[first...last])
    }
}
