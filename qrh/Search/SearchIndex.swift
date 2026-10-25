//
//  SearchIndex.swift
//  qrh
//
//  Searches guideline codes, titles and card text. Results come in three
//  groups, each in handbook order: code matches ("3-8", or "3-" for every
//  3-x guideline), title matches, then guidelines whose text contains every
//  word of the query, with a snippet from the card that best matches.
//

import Foundation

struct SearchResult: Identifiable, Hashable, Sendable {
    enum Match: Hashable, Sendable {
        case code
        case title
//        The best-matching card, and a snippet of its text
        case content(card: Int, snippet: String)
    }

    let guideline: Guideline
    let match: Match
    let terms: [SearchTerm]

    var id: String { guideline.code }
}

struct SearchIndex: Sendable {

    struct CardText: Sendable {
        let index: Int
        let text: SearchText
    }

    struct Entry: Sendable {
        let guideline: Guideline
        let title: SearchText
        let cards: [CardText]
    }

//    Queries shorter than this (letters and digits) only search titles and
//    codes, so the first keystrokes don't match text throughout the handbook
    static let minimumContentLength = 3

    let entries: [Entry]

    init(guidelines: [Guideline], cards: [String: [RenderedCard]]) {
        entries = guidelines.map { guideline in
            Entry(guideline: guideline,
                  title: SearchText(guideline.title),
                  cards: Self.searchableCards(cards[guideline.code] ?? []).compactMap { card in
                      card.searchText.map { CardText(index: card.index, text: $0) }
                  })
        }
    }

//    Title-only index, used until the card text has loaded

    init(guidelines: [Guideline]) {
        self.init(guidelines: guidelines, cards: [:])
    }

    func search(_ query: String) -> [SearchResult] {
        if let prefix = Self.codePrefix(query) {
            let matches = entries.map(\.guideline).filter { $0.code.hasPrefix(prefix) }
            let exact = matches.filter { $0.code == prefix }
            return (exact + matches.filter { $0.code != prefix })
                .map { SearchResult(guideline: $0, match: .code, terms: []) }
        }

        let terms = SearchTerm.terms(in: query)
        guard !terms.isEmpty else { return [] }

        var titles = [SearchResult]()
        var contents = [SearchResult]()
        let searchContent = Self.searchesContent(terms)

        for entry in entries {
            if entry.title.contains(all: terms) {
                titles.append(SearchResult(guideline: entry.guideline, match: .title, terms: terms))
            } else if searchContent, let match = contentMatch(entry, terms: terms) {
                contents.append(SearchResult(guideline: entry.guideline, match: match, terms: terms))
            }
        }
        return titles + contents
    }

//    Every word must appear somewhere in the guideline (title or cards). The
//    snippet comes from the first card holding the most of them.

    private func contentMatch(_ entry: Entry, terms: [SearchTerm]) -> SearchResult.Match? {
        let found = terms.allSatisfy { term in
            entry.title.contains(term) || entry.cards.contains { $0.text.contains(term) }
        }
        guard found else { return nil }

        var best: (card: CardText, count: Int)?
        for card in entry.cards {
            let count = terms.filter(card.text.contains).count
            if count > (best?.count ?? 0) {
                best = (card, count)
            }
        }
        guard let card = best?.card,
              let term = terms.first(where: card.text.contains),
              let range = card.text.firstRange(of: term) else { return nil }
        return .content(card: card.index, snippet: Self.snippet(of: card.text.original, around: range))
    }


//    Whether a query looks in card text, not just titles and codes

    static func searchesContent(_ query: String) -> Bool {
        codePrefix(query) == nil && searchesContent(SearchTerm.terms(in: query))
    }

    private static func searchesContent(_ terms: [SearchTerm]) -> Bool {
        terms.reduce(0) { $0 + $1.scalars.count } >= minimumContentLength
    }


//    Codes: "3-8", "3-", "→3-8" or "(3-8)"

    static func codePrefix(_ query: String) -> String? {
        let trimmed = query.filter { !$0.isWhitespace && !"()→".contains($0) }
        guard trimmed.wholeMatch(of: /[0-9]-[0-9]{0,2}/) != nil else { return nil }
        return trimmed
    }


//    About a line of context before the match and the rest after it, cut at
//    word boundaries, on one line

    static func snippet(of text: String, around range: Range<String.Index>,
                        before: Int = 30, length: Int = 140) -> String {
        var start = text.index(range.lowerBound, offsetBy: -before, limitedBy: text.startIndex) ?? text.startIndex
        if start > text.startIndex {
            if let space = text[start..<range.lowerBound].firstIndex(where: \.isWhitespace) {
                start = text.index(after: space)
            } else {
                start = range.lowerBound
            }
        }
        var end = text.index(start, offsetBy: length, limitedBy: text.endIndex) ?? text.endIndex
        if end < text.endIndex, end > range.upperBound,
           let space = text[range.upperBound..<end].lastIndex(where: \.isWhitespace) {
            end = space
        }
        let body = text[start..<end]
            .split(whereSeparator: { $0.isNewline || $0.isWhitespace })
            .joined(separator: " ")
        return (start > text.startIndex ? "…" : "") + body + (end < text.endIndex ? "…" : "")
    }
}

extension SearchIndex {

//    Every guideline ends with the same disclaimer card and then a copyright
//    footer, so neither (nor anything after the disclaimer) is searched

    static func searchableCards(_ cards: [RenderedCard]) -> [RenderedCard] {
        Array(cards.prefix { $0.kind != .warning })
    }
}

extension RenderedCard {

//    The text search looks at: heads and bodies, but not boilerplate (the
//    START banner and version footer)

    var searchText: SearchText? {
        switch kind {
        case .start, .version, .warning:
            return nil
        default:
            let text = [card.head, blocks.plainText]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
            return text.isEmpty ? nil : SearchText(text)
        }
    }
}
