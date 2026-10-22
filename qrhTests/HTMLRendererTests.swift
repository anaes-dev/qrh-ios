//
//  HTMLRendererTests.swift
//  qrhTests
//

import Foundation
import SwiftUI
import Testing
@testable import qrh

struct HTMLRendererTests {

    func paragraphs(_ html: String) -> [String] {
        HTMLRenderer.render(html).compactMap {
            if case .paragraph(let text) = $0 { return String(text.characters) }
            return nil
        }
    }

    func single(_ html: String) throws -> AttributedString {
        let blocks = HTMLRenderer.render(html)
        try #require(blocks.count == 1)
        guard case .paragraph(let text) = blocks[0] else {
            Issue.record("Expected a paragraph")
            return AttributedString()
        }
        return text
    }

    func font(of substring: String, in text: AttributedString) -> Font? {
        guard let range = text.range(of: substring) else { return nil }
        return text[range].runs.first?.swiftUI.font ?? nil
    }

    func underline(of substring: String, in text: AttributedString) -> Text.LineStyle? {
        guard let range = text.range(of: substring) else { return nil }
        return text[range].runs.first?.swiftUI.underlineStyle ?? nil
    }


//    Plain text and whitespace

    @Test func plainTextIsOneParagraphInBaseFont() throws {
        let text = try single("Recheck blood pressure.")
        #expect(String(text.characters) == "Recheck blood pressure.")
        #expect(font(of: "Recheck", in: text) == HTMLRenderer.font())
        #expect(HTMLRenderer.font() == .subheadline)
    }

    @Test func whitespaceIsCollapsedAndTrimmed() throws {
        let text = try single("  a \n  b\t c  ")
        #expect(String(text.characters) == "a b c")
    }

    @Test func emptyBodyRendersNothing() {
        #expect(HTMLRenderer.render("").isEmpty)
        #expect(HTMLRenderer.render("<p> </p>").isEmpty)
    }


//    Inline tags

    @Test func boldStrongAndUppercaseB() throws {
        for html in ["a <b>bold</b> c", "a <strong>bold</strong> c", "a <B>bold</b> c"] {
            let text = try single(html)
            #expect(String(text.characters) == "a bold c")
            #expect(font(of: "bold", in: text) == HTMLRenderer.font(bold: true), "\(html)")
            #expect(font(of: "c", in: text) == HTMLRenderer.font())
        }
    }

    @Test func italic() throws {
        let text = try single("<i>slanted</i> upright")
        #expect(font(of: "slanted", in: text) == HTMLRenderer.font(italic: true))
        #expect(font(of: "upright", in: text) == HTMLRenderer.font())
    }

    @Test func underlineTag() throws {
        let text = try single("<u>DO NOT</u> stop")
        #expect(underline(of: "DO NOT", in: text) == .single)
        #expect(underline(of: "stop", in: text) == nil)
    }

    @Test func smallUsesFootnote() throws {
        let text = try single("F<small>i</small>O₂")
        #expect(String(text.characters) == "FiO₂")
        #expect(font(of: "i", in: text) == HTMLRenderer.font(small: true))
        #expect(HTMLRenderer.font(small: true) == .footnote)
    }

    @Test func nestedInlineTagsCombine() throws {
        let text = try single("<small><b>bold small</b></small>")
        #expect(font(of: "bold small", in: text) == HTMLRenderer.font(bold: true, small: true))
    }

    @Test func strayClosingTagIsIgnored() throws {
        let text = try single("Biphasic 4 J (adult 150-200 J)</small> more")
        #expect(String(text.characters) == "Biphasic 4 J (adult 150-200 J) more")
        #expect(font(of: "more", in: text) == HTMLRenderer.font())
    }


//    Entities and literal "<"

    @Test func entities() throws {
        let text = try single("heart rate &lt;60 bpm &gt; 2 &amp; more")
        #expect(String(text.characters) == "heart rate <60 bpm > 2 & more")
    }

    @Test func lessThanThatIsNotATagIsText() throws {
        #expect(try String(single("RR <3 breaths.").characters) == "RR <3 breaths.")
        #expect(try String(single("PaCO₂ < 5.5 kPa").characters) == "PaCO₂ < 5.5 kPa")
    }


//    Paragraphs and line breaks

    @Test func paragraphsBecomeBlocks() {
        #expect(paragraphs("<p>One</p><p>Two</p>") == ["One", "Two"])
    }

    @Test func textBeforeUnclosedParagraph() {
        #expect(paragraphs("First sentence.<p>Second sentence.") == ["First sentence.", "Second sentence."])
    }

    @Test func unclosedParagraphIsClosedByNext() {
        #expect(paragraphs("<p>Give atropine.<p>If no pulse:</p>") == ["Give atropine.", "If no pulse:"])
    }

    @Test func lineBreak() throws {
        let text = try single("Nebuliser:<br>Child 0.5 ml <br> Adult 5 ml")
        #expect(String(text.characters) == "Nebuliser:\nChild 0.5 ml\nAdult 5 ml")
    }


//    Lists

    @Test func bulletList() {
        let blocks = HTMLRenderer.render("<ul><li>One</li><li>Two</li></ul>")
        #expect(blocks.count == 1)
        guard case .bulletList(let items) = blocks.first else {
            Issue.record("Expected a list")
            return
        }
        #expect(items.map { String($0.characters) } == ["One", "Two"])
    }

    @Test func paragraphThenListThenParagraph() {
        let blocks = HTMLRenderer.render("<p>Control seizures:</p><ul><li>One</li></ul>After")
        #expect(blocks.plainText == "Control seizures:\n• One\nAfter")
    }

    @Test func unclosedItemsAndList() {
        let blocks = HTMLRenderer.render("<ul><li>One<li>Two</li><li>Three")
        #expect(blocks.plainText == "• One\n• Two\n• Three")
    }

    @Test func itemsWithoutListAreStillAList() {
        let blocks = HTMLRenderer.render("<li>One<li>Two</li>")
        #expect(blocks.plainText == "• One\n• Two")
    }

    @Test func paragraphsInsideItemAreLines() {
        let blocks = HTMLRenderer.render("<ul><li>Causes:<p>- One</p><p>- Two</p></li><li>Next</li></ul>")
        #expect(blocks.plainText == "• Causes:\n- One\n- Two\n• Next")
    }

    @Test func lineBreaksInsideItem() {
        let blocks = HTMLRenderer.render("<ul><li>IntraMUSCULAR:<br>&lt;6 mo 50 µg<br>Adult 500 µg</li></ul>")
        #expect(blocks.plainText == "• IntraMUSCULAR:\n<6 mo 50 µg\nAdult 500 µg")
    }

    @Test func formattingInsideItems() throws {
        let blocks = HTMLRenderer.render("<ul><li>Alfentanil <small>(adult 0.5-1 mg)</small></li></ul>")
        guard case .bulletList(let items) = blocks.first, let item = items.first else {
            Issue.record("Expected a list")
            return
        }
        #expect(font(of: "(adult", in: item) == HTMLRenderer.font(small: true))
        #expect(font(of: "Alfentanil", in: item) == HTMLRenderer.font())
    }
}
