//
//  ParityTests.swift
//  qrhTests
//
//  Checks the new HTMLRenderer produces the same text as the legacy
//  WebKit-backed NSAttributedString importer the UIKit app used, ignoring
//  whitespace and bullet markers. Line-break placement differs in places
//  (e.g. WebKit adds no break before a <p> inside an <li>), which the visual
//  comparison covers instead.
//
//  The importer is very slow, so its output is stored in
//  Fixtures/legacy-html-text.json with each card's source HTML. After editing
//  a guideline in data.json, regenerate the fixture:
//
//    TEST_RUNNER_QRH_PARITY_FIXTURE_OUT="$PWD/qrhTests/Fixtures/legacy-html-text.json" \
//    xcodebuild test -project qrh.xcodeproj -scheme qrh \
//      -destination 'platform=iOS Simulator,name=iPhone 17' \
//      -only-testing:'qrhTests/ParityTests/regenerateFixture()'
//

import Foundation
import Testing
import UIKit
@testable import qrh

private final class BundleToken {}

struct ParityTests {

    struct Entry: Codable, Equatable {
        let body: String
        let text: String
    }

//    code -> card index -> entry
    typealias Fixture = [String: [String: Entry]]

    static let handbook = (try? GuidelineStore.load(from: .main)) ?? .empty
    static let codes = handbook.guidelines.map(\.code)

    static func cards(_ code: String) throws -> [Card] {
        try #require(handbook.cards[code])
    }

    static func isHTML(_ card: Card) -> Bool {
        switch CardKind(type: card.type) {
        case .intro, .start, .step, .stepBodyOnly, .callout: true
        default: false
        }
    }

    static func loadFixture() throws -> Fixture {
        let url = try #require(Bundle(for: BundleToken.self).url(forResource: "legacy-html-text", withExtension: "json"))
        return try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
    }

    static func normalise(_ text: String) -> String {
        text.replacingOccurrences(of: "•", with: "")
            .replacingOccurrences(of: "[\\s\\x{00A0}\\x{2028}\\x{2029}]+", with: "", options: .regularExpression)
    }

    @Test(arguments: codes)
    func newRendererMatchesLegacyImporter(code: String) throws {
        let fixture = try Self.loadFixture()
        let cards = try Self.cards(code)
        for (row, card) in cards.enumerated() where Self.isHTML(card) {
            guard let entry = fixture[code]?[String(row)], entry.body == card.body else {
                Issue.record("\(code) row \(row) changed since the fixture was made; regenerate it (see ParityTests.swift)")
                continue
            }
            let rendered = HTMLRenderer.render(card.body).plainText
            #expect(Self.normalise(rendered) == Self.normalise(entry.text), "\(code) row \(row)")
        }
    }


//    Fixture generation, only when asked for

//    Copied from DetailController.parseHtmlAttributes (minus link handling)

    @MainActor
    static func legacyRender(_ htmlText: String) throws -> String {
        let htmlInput = """
                        <style type=\"text/css\">
                        body {
                            font-family: -apple-system, 'HelveticaNeue';
                            font-size: 15;
                        }
                        ul {
                            padding: 8px 0 0 0;
                        }
                        li {
                            margin: 0 0 8 0;
                        }
                        </style>
                        \(htmlText)
                        """
        let attrStr = try NSMutableAttributedString(
            data: htmlInput.data(using: String.Encoding.utf8)!,
            options: [.documentType: NSMutableAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil)
        if let lastCharacter = attrStr.string.last, lastCharacter == "\n" {
            attrStr.deleteCharacters(in: NSRange(location: attrStr.length - 1, length: 1))
        }
        return attrStr.string
    }

    @MainActor
    @Test(.enabled(if: ProcessInfo.processInfo.environment["QRH_PARITY_FIXTURE_OUT"] != nil))
    func regenerateFixture() throws {
        var fixture = Fixture()
        for code in Self.codes {
            var entries = [String: Entry]()
            for (row, card) in try Self.cards(code).enumerated() where Self.isHTML(card) {
                entries[String(row)] = Entry(body: card.body, text: try Self.legacyRender(card.body))
            }
            fixture[code] = entries
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let path = try #require(ProcessInfo.processInfo.environment["QRH_PARITY_FIXTURE_OUT"])
        try encoder.encode(fixture).write(to: URL(fileURLWithPath: path))
    }
}
