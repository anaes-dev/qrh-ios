//
//  ContentBlockTests.swift
//  qrhTests
//
//  Branches (type 13) and how cards group into forks.
//

import Foundation
import Testing
@testable import qrh

struct ContentBlockTests {

    static let handbook = (try? GuidelineStore.load(from: .main)) ?? .empty

    static func rendered(_ code: String) throws -> [RenderedCard] {
        CardRenderer.render(try #require(handbook.cards[code]), code: code)
    }

    static func forks(_ blocks: [ContentBlock]) -> [Fork] {
        blocks.compactMap { if case .fork(let fork) = $0 { fork } else { nil } }
    }

    static func card(_ type: Int, _ branch: String = "", step: String = "") -> Card {
        Card(type: type, head: "", body: "b", step: step, branch: branch)
    }

    @Test func fireHasOneForkOfTwoBranches() throws {
        let cards = try Self.rendered("3-7")
        let forks = Self.forks(ContentBlock.group(cards))
        #expect(forks.count == 1)
        let branches = try #require(forks.first).branches
        #expect(branches.map(\.id) == ["airway", "non-airway"])
        #expect(branches.map(\.cards.count) == [2, 2])
        #expect(branches.map { $0.cards.map(\.card.step) } == [["2", "3"], ["2", "3"]])
//        Nothing lost or repeated
        #expect(ContentBlock.group(cards).flatMap(\.cards).map(\.index) == cards.map(\.index))
    }

    @Test func localAnaestheticToxicityHasOneForkOfTwoBranches() throws {
        let cards = try Self.rendered("3-10")
        let blocks = ContentBlock.group(cards)
        let forks = Self.forks(blocks)
        #expect(forks.count == 1)
        let branches = try #require(forks.first).branches
        #expect(branches.map(\.id) == ["arrest", "no-arrest"])
//        Step 6 and Box A in each
        #expect(branches.map(\.cards.count) == [2, 2])
        #expect(branches.allSatisfy { $0.cards.map(\.kind) == [.stepBodyOnly, .callout(.blue)] })
        #expect(blocks.flatMap(\.cards).map(\.index) == cards.map(\.index))
//        Step 7 follows the fork on its own
        let after = try #require(blocks.firstIndex { if case .fork = $0 { true } else { false } }) + 1
        #expect(blocks[after].cards.first?.card.step == "7")
    }

    @Test func onlyFireAndToxicityBranch() throws {
        for code in Self.handbook.guidelines.map(\.code) {
            let forks = Self.forks(ContentBlock.group(try Self.rendered(code)))
            #expect(forks.isEmpty == !["3-7", "3-10"].contains(code), "\(code)")
        }
    }

    @Test func branchEndsAtNextHeaderOrOtherBranch() {
        let cards = CardRenderer.render([
            Self.card(3, step: "1"),
            Self.card(13, "a"), Self.card(3, "a"), Self.card(3, "a"),
            Self.card(13, "b"), Self.card(3, "b"),
            Self.card(3, "c"),
            Self.card(13, "d"), Self.card(13, "e"), Self.card(3, "e"),
        ], code: "test")
        let blocks = ContentBlock.group(cards)
        #expect(blocks.count == 4)
        let forks = Self.forks(blocks)
        #expect(forks.map { $0.branches.map(\.id) } == [["a", "b"], ["d", "e"]])
        #expect(forks.map { $0.branches.map(\.cards.count) } == [[2, 1], [0, 1]])
        #expect(blocks[2].cards.map(\.index) == [6])
    }

    @Test func conditionIsSpokenLowercaseWithoutColon() throws {
        let headers = try Self.rendered("3-10").branchHeaders
        #expect(headers["arrest"]?.spokenCondition == "if circulatory arrest")
        #expect(headers["no-arrest"]?.spokenCondition == "if no circulatory arrest")
        #expect(try Self.rendered("3-7").branchHeaders["airway"]?.spokenCondition == "if AIRWAY fire")
    }

//    3-10's Box A, repeated in each branch, shows once beside the steps;
//    3-8's EMERGENCY HELP, repeated but not branched, shows each time
    @Test func sideColumnMergesOnlyBranchedCopies() throws {
        let toxicity = try Self.rendered("3-10").sideColumn()
        #expect(toxicity.cards.map(\.card.head) == ["Box A: LIPID EMULSION REGIME", "Box B: CRITICAL CHANGES", "Box C: AFTER THE EVENT"])
        #expect(toxicity.merged == [12: 9])

        let hyperthermia = try Self.rendered("3-8")
        let boxes = hyperthermia.filter(\.kind.isRightColumn)
        #expect(hyperthermia.sideColumn().cards == boxes)
        #expect(hyperthermia.sideColumn().merged.isEmpty)
        #expect(Dictionary(grouping: boxes, by: \.card.head).values.contains { $0.count > 1 })
    }

    @Test func branchKeyIsOptional() throws {
        let json = #"[{"type": 13, "head": "", "body": "<b>If x:</b>", "step": "", "branch": "x"}, {"type": 3, "head": "h", "body": "b", "step": "1"}]"#
        let cards = try JSONDecoder().decode([Card].self, from: Data(json.utf8))
        #expect(cards.map(\.branch) == ["x", ""])
        #expect(CardKind(type: cards[0].type) == .branch)
    }

//    A newer app's card type, or missing keys, still shows the text
    @MainActor
    @Test func unknownTypesKeepTheirContent() throws {
        let json = #"[{"type": 99, "head": "Heading", "body": "<p>Body text</p>"}]"#
        let cards = try JSONDecoder().decode([Card].self, from: Data(json.utf8))
        let rendered = CardRenderer.render(cards, code: "test")
        #expect(rendered[0].kind == .unknown)
        #expect(rendered[0].blocks.plainText == "Heading\nBody text")
        #expect(CardDeckView.deckCards(rendered).count == 1)
    }
}
