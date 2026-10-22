//
//  LinkDetectorTests.swift
//  qrhTests
//

import Foundation
import SwiftUI
import Testing
@testable import qrh

struct LinkDetectorTests {

    func links(in blocks: [RichBlock]) -> [URL] {
        blocks.flatMap { block -> [AttributedString] in
            switch block {
            case .paragraph(let text): return [text]
            case .bulletList(let items): return items
            }
        }.flatMap { text in
            text.runs.compactMap(\.link)
        }
    }

    func renderedCard(_ code: String, row: Int) throws -> RenderedCard {
        let cards = try #require(GuidelineStore.load(from: .main).cards[code])
        return CardRenderer.render(cards, code: code)[row]
    }


//    Guideline references

    @Test(arguments: [
        ("go to →3-5 now", ["3-5"]),
        ("(→ 2-1)", ["2-1"]),
        ("→3-10 and →1-1", ["3-10", "1-1"]),
        ("→2-1 (Cardiac arrest)", ["2-1"]),
        ("no links 3-5 here", []),
    ])
    func guidelineCodes(text: String, expected: [String]) {
        #expect(LinkDetector.guidelineCodes(in: text) == expected)
    }

    @Test func guidelineURLRoundTrip() throws {
        let url = LinkDetector.guidelineURL(code: "3-10")
        #expect(url.absoluteString == "qrh://guideline/3-10")
        #expect(LinkDetector.guidelineCode(from: url) == "3-10")
        #expect(LinkDetector.guidelineCode(from: try #require(URL(string: "https://anaes.dev/3-10"))) == nil)
        #expect(LinkDetector.guidelineCode(from: try #require(URL(string: "tel:0123"))) == nil)
    }

    @Test func guidelineLinkIsLinkedAndUnderlined() throws {
        var text = AttributedString("key basic plan →1-1 now")
        LinkDetector.addLinks(to: &text, detecting: [])
        let range = try #require(text.range(of: "→1-1"))
        #expect(text[range].link == LinkDetector.guidelineURL(code: "1-1"))
        #expect(text[range].swiftUI.underlineStyle == .single)
        let plain = try #require(text.range(of: "now"))
        #expect(text[plain].link == nil)
    }

    @Test func parenthesisedLinkCoversWholeMatch() throws {
        var text = AttributedString("see (→3-6) here")
        LinkDetector.addLinks(to: &text, detecting: [])
        let range = try #require(text.range(of: "(→3-6)"))
        #expect(text[range].runs.count == 1)
        #expect(text[range].link == LinkDetector.guidelineURL(code: "3-6"))
    }


//    Data detection per card kind

    @Test func detectorTypesPerKind() {
        #expect(LinkDetector.dataDetectorTypes(for: .intro, code: "1-1", row: 0) == [.link])
        #expect(LinkDetector.dataDetectorTypes(for: .step, code: "1-1", row: 3) == [.link, .phoneNumber])
        #expect(LinkDetector.dataDetectorTypes(for: .stepBodyOnly, code: "1-1", row: 3) == [.link, .phoneNumber])
        for color in CalloutColor.allCases {
            #expect(LinkDetector.dataDetectorTypes(for: .callout(color), code: "1-1", row: 3) == [.link, .phoneNumber])
        }
        for kind in [CardKind.start, .image, .version, .warning, .unknown] {
            #expect(LinkDetector.dataDetectorTypes(for: kind, code: "1-1", row: 3) == [])
        }
    }

    @Test func exclusionTable() {
        #expect(LinkDetector.dataDetectionExclusions == [
            .init(code: "3-5", row: 7),
            .init(code: "3-9", row: 8),
            .init(code: "2-5", row: 12),
        ])
        #expect(LinkDetector.dataDetectorTypes(for: .stepBodyOnly, code: "3-5", row: 7) == [])
        #expect(LinkDetector.dataDetectorTypes(for: .stepBodyOnly, code: "3-9", row: 8) == [])
        #expect(LinkDetector.dataDetectorTypes(for: .callout(.blue), code: "2-5", row: 12) == [])
        #expect(LinkDetector.dataDetectorTypes(for: .stepBodyOnly, code: "3-5", row: 6) == [.link, .phoneNumber])
    }

    @Test(arguments: [("3-5", 7), ("3-9", 8), ("2-5", 12)])
    func excludedRowsHaveNoLinks(code: String, row: Int) throws {
        let card = try renderedCard(code, row: row)
        #expect(links(in: card.blocks).isEmpty)
    }

    @Test func phoneNumbersInCallout() throws {
        let card = try renderedCard("3-8", row: 2)
        #expect(card.kind == .callout(.purple))
        let urls = links(in: card.blocks)
        #expect(urls.contains { $0.scheme == "tel" && $0.absoluteString.contains("07947609601") })
        #expect(urls.contains { $0.scheme == "tel" && $0.absoluteString.contains("01132433144") })
        #expect(urls.contains { $0.host?.contains("ukmhr.ac.uk") == true })
    }

    @Test func webLinkInIntro() throws {
        let card = try renderedCard("0-3", row: 0)
        #expect(card.kind == .intro)
        #expect(links(in: card.blocks).contains { $0.absoluteString.contains("anaesthetists.org/Quick-Reference-Handbook") })
    }

    @Test func introDoesNotDetectPhoneNumbers() {
        var text = AttributedString("Call 07947609601")
        LinkDetector.addLinks(to: &text, detecting: LinkDetector.dataDetectorTypes(for: .intro, code: "x", row: 0))
        #expect(text.runs.allSatisfy { $0.link == nil })
    }

    @Test func guidelineLinksInRenderedCard() throws {
        let card = try renderedCard("2-5", row: 1)
        #expect(links(in: card.blocks) == [LinkDetector.guidelineURL(code: "1-1")])
    }

    @Test func startBannerHasNoLinks() throws {
        let card = try renderedCard("2-5", row: 2)
        #expect(card.kind == .start)
        #expect(card.blocks.plainText == "START")
        #expect(links(in: card.blocks).isEmpty)
    }
}
