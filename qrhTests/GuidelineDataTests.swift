//
//  GuidelineDataTests.swift
//  qrhTests
//
//  Integrity of the bundled data.json (shared with qrh-android).
//

import Foundation
import Testing
import UIKit
@testable import qrh

struct GuidelineDataTests {

    static let handbook = (try? GuidelineStore.load(from: .main)) ?? .empty
    static let guidelines = handbook.guidelines
    static let codes = guidelines.map(\.code)

//    A guideline's cards, including the boilerplate ones the app adds
    static func cards(_ code: String) throws -> [Card] {
        try #require(handbook.cards[code])
    }

    static func file() throws -> GuidelineData {
        let url = try #require(Bundle.main.url(forResource: "data", withExtension: "json"))
        return try JSONDecoder().decode(GuidelineData.self, from: Data(contentsOf: url))
    }

    @Test func guidelineListLoadsInFileOrder() {
        #expect(Self.guidelines.count == 27)
        #expect(Self.codes.first == "0-3")
        #expect(Self.codes.last == "4-3")
        #expect(Set(Self.codes).count == Self.codes.count, "Duplicate codes")
    }

//    The old one-file-per-guideline JSON is gone
    @Test func dataJSONIsTheOnlyJSON() {
        let files = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? []
        #expect(files.map(\.lastPathComponent) == ["data.json"])
    }

//    The app adds these, so the file mustn't repeat them
    @Test func contentHasNoBoilerplateCards() throws {
        for entry in try Self.file().data {
            #expect(!entry.content.contains { $0.type == 11 || $0.type == 12 }, "\(entry.code)")
            #expect(!entry.content.contains { $0.body.contains("Creative Commons") }, "\(entry.code)")
        }
    }

    @Test func everyCopyrightHolderIsDefined() throws {
        let file = try Self.file()
        for entry in file.data {
            #expect(file.copyrightHolders[entry.copyright.holder] != nil, "\(entry.code)")
            #expect((2018...2030).contains(entry.copyright.year), "\(entry.code)")
        }
    }

    @Test func guidelinesEndWithVersionDisclaimerAndLicence() throws {
        let cards = try Self.cards("3-8")
        #expect(cards.suffix(3).map(\.type) == [11, 12, 1])
        #expect(cards.last?.body.hasPrefix("<p><small><b>Association of Anaesthetists 2021. www.anaesthetists.org/qrh</b></small></p>") == true)
        #expect(try Self.cards("2-5").last?.body.contains("Great Britain & Ireland 2018. www.aagbi.org/qrh") == true)
    }

//    App Store Connect rejects builds without it (UserDefaults is a
//    required-reason API)
    @Test func privacyManifestIsBundled() {
        #expect(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy") != nil)
    }

    @Test(arguments: codes)
    func guidelineDecodes(code: String) throws {
        let cards = try Self.cards(code)
        #expect(!cards.isEmpty)
    }

    @Test(arguments: codes)
    func everyCardTypeIsKnown(code: String) throws {
        for (row, card) in try Self.cards(code).enumerated() {
            #expect(CardKind(type: card.type) != .unknown, "\(code) row \(row) has type \(card.type)")
        }
    }

    @Test(arguments: codes)
    func everyGuidelineLinkResolves(code: String) throws {
        let known = Set(Self.codes)
        for (row, card) in try Self.cards(code).enumerated() {
            let text = HTMLRenderer.render(card.body).plainText
            for linked in LinkDetector.guidelineCodes(in: text) {
                #expect(known.contains(linked), "\(code) row \(row) links to unknown \(linked)")
            }
        }
    }

    @Test func guidelineLinksAreUsedThroughout() throws {
        var count = 0
        for code in Self.codes {
            for card in try Self.cards(code) {
                count += LinkDetector.guidelineCodes(in: HTMLRenderer.render(card.body).plainText).count
            }
        }
        #expect(count == 79)
    }

    @Test(arguments: codes)
    func imagesExistInBundle(code: String) throws {
        for card in try Self.cards(code) where CardKind(type: card.type) == .image {
            #expect(UIImage(named: card.body) != nil, "Missing image \(card.body)")
        }
    }

//    Tables: boxes only, rows as wide as the headings, and every cell also in
//    the body, which older app versions show and search reads

    @Test(arguments: codes)
    func tablesAreOnlyInBoxes(code: String) throws {
        for (row, card) in try Self.cards(code).enumerated() where card.table != nil {
            #expect((5...9).contains(card.type), "\(code) row \(row) has a table on type \(card.type)")
        }
    }

    @Test(arguments: codes)
    func tableRowsAreAsWideAsColumns(code: String) throws {
        for card in try Self.cards(code) {
            guard let table = card.table else { continue }
            #expect(!table.columns.isEmpty && !table.rows.isEmpty, "\(code) \(card.head)")
            for cells in table.rows {
                #expect(cells.count == table.columns.count, "\(code) row \(cells.first ?? "")")
            }
        }
    }

    @Test(arguments: codes)
    func tableCellsAreInBody(code: String) throws {
        for card in try Self.cards(code) {
            guard let table = card.table else { continue }
            let body = HTMLRenderer.render(card.body).plainText
            for cell in table.rows.joined() {
                #expect(body.contains(cell), "\(code): \"\(cell)\" is in the table but not the body")
            }
        }
    }

    @Test func oxygenCylinderTable() throws {
        let box = try #require(try Self.cards("4-1").first { $0.head == "Box B: OXYGEN CYLINDER REMAINING CONTENTS" })
        #expect(box.type == 8)
        let table = try #require(box.table)
        #expect(table.rows.map { $0[0] } == ["C", "D", "E", "F", "G", "J"])
        #expect(table.rows.last == ["J", "1700 L", "3400 L", "6800 L"])
        #expect(table.spokenRow(table.rows[0])
                == "Size C: 25% full (34 bar), 43 litres; 50% full (69 bar), 85 litres; 100% full (137 bar), 170 litres")
    }

//    The grid at usual sizes on an iPhone; stacked rows when words would break
    @Test func oxygenTableStacksWhenWordsWontFit() throws {
        let box = try #require(try Self.cards("4-1").first { $0.table != nil })
        let table = try #require(box.table)
        #expect(BoxTable.wordsFit(table, width: 344, typeSize: .large))
        #expect(BoxTable.wordsFit(table, width: 344, typeSize: .xxxLarge))
        #expect(!BoxTable.wordsFit(table, width: 344, typeSize: .accessibility5))
    }

    @Test func versionFooterMatchesList() throws {
        for guideline in Self.guidelines {
            let footers = try Self.cards(guideline.code).filter { $0.type == 11 }
            #expect(footers.map(\.body) == ["v.\(guideline.version)"], "\(guideline.code)")
        }
    }

    @MainActor
    @Test func storeLooksUpExactCode() async {
        let store = GuidelineStore()
        #expect(store.guideline(code: "3-1")?.title == "Anaphylaxis")
        #expect(store.guideline(code: "3-10")?.title == "Local anaesthetic toxicity")
        #expect(store.guideline(code: "3") == nil)

        let cards = await store.cards(for: "2-5")
        #expect(!cards.isEmpty)
        #expect(cards.first?.kind == .intro)
        #expect(store.cachedCards(for: "2-5") == cards)
        #expect(await store.cards(for: "9-9").isEmpty)
    }
}
