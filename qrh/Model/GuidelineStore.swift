//
//  GuidelineStore.swift
//  qrh
//

import Foundation
import Observation

//    The handbook as loaded from data.json: every guideline and its cards,
//    each ending with the boilerplate cards

struct Handbook: Sendable {
    let version: String
    let guidelines: [Guideline]
    let cards: [String: [Card]]

    static let empty = Handbook(version: "", guidelines: [], cards: [:])
}

//    Loads data.json once at launch (it's small). Rendering cards runs off the
//    main thread and is cached.

@Observable
@MainActor
final class GuidelineStore {

    enum LoadError: Error {
        case missingFile(String)
    }

    let guidelines: [Guideline]

//    Titles only until loadSearchIndex() has rendered every guideline
    private(set) var searchIndex: SearchIndex
    private(set) var hasCardText = false

    @ObservationIgnored private let handbook: Handbook
    @ObservationIgnored private var cache = [String: [RenderedCard]]()

    init(bundle: Bundle = .main) {
        handbook = (try? Self.load(from: bundle)) ?? .empty
        guidelines = handbook.guidelines
        searchIndex = SearchIndex(guidelines: guidelines)
    }

//    Exact code match (the UIKit app matched with contains())

    func guideline(code: String) -> Guideline? {
        guidelines.first { $0.code == code }
    }

    func cachedCards(for code: String) -> [RenderedCard]? {
        cache[code]
    }

    func cards(for code: String) async -> [RenderedCard] {
        if let cached = cache[code] {
            return cached
        }
        let cards = handbook.cards[code] ?? []
        let rendered = await Task.detached(priority: .userInitiated) {
            CardRenderer.render(cards, code: code)
        }.value
        cache[code] = rendered
        return rendered
    }

//    Renders every guideline (filling the cache) and indexes the text

    func loadSearchIndex() async {
        let handbook = handbook
        let (cards, index) = await Task.detached(priority: .utility) {
            var cards = [String: [RenderedCard]]()
            for (code, content) in handbook.cards {
                cards[code] = CardRenderer.render(content, code: code)
            }
            return (cards, SearchIndex(guidelines: handbook.guidelines, cards: cards))
        }.value
        cache.merge(cards) { current, _ in current }
        searchIndex = index
        hasCardText = true
    }


//    Loading

    nonisolated static func load(from bundle: Bundle) throws -> Handbook {
        guard let url = bundle.url(forResource: "data", withExtension: "json") else {
            throw LoadError.missingFile("data.json")
        }
        let file = try JSONDecoder().decode(GuidelineData.self, from: Data(contentsOf: url))
        var cards = [String: [Card]]()
        for entry in file.data {
            cards[entry.code] = entry.content + Boilerplate.cards(for: entry.guideline, holders: file.copyrightHolders)
        }
        return Handbook(version: file.version, guidelines: file.data.map(\.guideline), cards: cards)
    }
}
