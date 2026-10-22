//
//  SearchTests.swift
//  qrhTests
//

import Foundation
import Testing
@testable import qrh

struct SearchTextTests {

    func matches(_ query: String, in text: String) -> [String] {
        let search = SearchText(text)
        return SearchTerm.terms(in: query).flatMap { search.ranges(of: $0) }.map { String(text[$0]) }
    }

    @Test func ignoresCaseAccentsAndPunctuation() {
        #expect(matches("hyperkalaemia", in: "Treat Hyper-kalaemia now") == ["Hyper-kalaemia"])
        #expect(matches("hyper-kalaemia", in: "hyperkalaemia") == ["hyperkalaemia"])
        #expect(matches("cafe", in: "Café") == ["Café"])
    }

    @Test func subscriptsAndSuperscriptsAreDigits() {
        #expect(matches("spo2", in: "Check SpO₂ now") == ["SpO₂"])
        #expect(matches("kg1", in: "1 mg.kg⁻¹") == ["kg⁻¹"])
    }

    @Test func findsEveryOccurrence() {
        #expect(matches("ab", in: "ab xab ab") == ["ab", "ab", "ab"])
    }

    @Test func termsAreFoldedWordsWithoutDuplicates() {
        #expect(SearchTerm.terms(in: "  Hyper-K  hyperk – ").count == 1)
        #expect(SearchTerm.terms(in: "- –").isEmpty)
    }
}

@MainActor
struct SearchIndexTests {

    static let store: GuidelineStore = {
        let store = GuidelineStore()
        return store
    }()

    func index() async -> SearchIndex {
        await Self.store.loadSearchIndex()
        return Self.store.searchIndex
    }

    @Test func codeFindsExactThenPrefix() async {
        let index = await index()
        #expect(index.search("3-8").map(\.guideline.code) == ["3-8"])
        #expect(index.search("→ 3-1").map(\.guideline.code) == ["3-1", "3-10", "3-11", "3-12", "3-13", "3-14"])
        #expect(index.search("4-").map(\.guideline.code) == ["4-1", "4-2", "4-3"])
    }

    @Test func titleMatchesComeBeforeContentMatches() async {
        let results = await index().search("hypoxia")
        #expect(results.first?.guideline.code == "2-2")
        #expect(results.first?.match == .title)
        #expect(results.dropFirst().allSatisfy {
            if case .content = $0.match { return true } else { return false }
        })
        #expect(results.count > 1)
    }

    @Test func contentMatchHasSnippetAndCard() async throws {
        let results = await index().search("dantrolene")
        #expect(results.map(\.guideline.code) == ["3-8"])
        guard case .content(let card, let snippet) = try #require(results.first).match else {
            Issue.record("Expected a content match")
            return
        }
        #expect(snippet.localizedCaseInsensitiveContains("dantrolene"))
        let cards = await Self.store.cards(for: "3-8")
        #expect(cards[card].searchText?.contains(SearchTerm.terms(in: "dantrolene")[0]) == true)
    }

    @Test func everyWordMustAppear() async {
        let index = await index()
        #expect(!index.search("dantrolene cooling").isEmpty)
        #expect(index.search("dantrolene zzzz").isEmpty)
    }

    @Test func shortQueriesOnlySearchTitles() async {
        let index = await index()
        for query in ["x", "hy", "o2", "h-y"] {
            #expect(index.search(query).allSatisfy { $0.match == .title }, "\(query)")
        }
        #expect(index.search("hy").contains { $0.guideline.code == "2-5" })
    }

    @Test func threeCharactersSearchText() async {
        let results = await index().search("dan")
        #expect(results.contains {
            if case .content = $0.match { $0.guideline.code == "3-8" } else { false }
        })
    }

    @Test func boilerplateCardsAreNotSearched() async {
        let index = await index()
//        The disclaimer card and copyright footer every guideline ends with
        #expect(index.search("not intended to be standards").isEmpty)
        #expect(index.search("creative commons").isEmpty)
        #expect(index.search("aagbi").isEmpty)
    }

    @Test func snippetIsCutAtWordsWithEllipses() {
        let text = String(repeating: "alpha ", count: 20) + "target " + String(repeating: "omega ", count: 40)
        let range = text.range(of: "target")!
        let snippet = SearchIndex.snippet(of: text, around: range)
        #expect(snippet.hasPrefix("…alpha"))
        #expect(snippet.hasSuffix("omega…"))
        #expect(snippet.contains("target"))
    }
}
