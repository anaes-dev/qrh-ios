//
//  HTMLRenderer.swift
//  qrh
//
//  Renders the small HTML subset used in the guideline JSON (b, strong, i, u,
//  small, p, br, ul, li and a few entities) to RichBlocks, replacing the slow
//  WebKit-backed NSAttributedString importer. The JSON is hand-written, so the
//  parser is forgiving: tag names are case-insensitive, unclosed and stray
//  tags are tolerated, and a "<" that doesn't start a tag is literal text.
//

import Foundation
import SwiftUI

enum HTMLRenderer {

//    Base 15 pt (subheadline at the default size) and small 13 pt (footnote),
//    so Dynamic Type scales the body text.

    static func font(bold: Bool = false, italic: Bool = false, small: Bool = false) -> Font {
        var font: Font = small ? .footnote : .subheadline
        if bold { font = font.bold() }
        if italic { font = font.italic() }
        return font
    }

    static func render(_ html: String) -> [RichBlock] {
        var builder = Builder()
        for token in tokenize(html) {
            switch token {
            case .text(let text):
                builder.append(text)
            case .open(let tag):
                builder.open(tag)
            case .close(let tag):
                builder.close(tag)
            }
        }
        return builder.finish()
    }


//    Tokenizer

    enum Token: Equatable {
        case text(String)
        case open(String)
        case close(String)
    }

    static func tokenize(_ html: String) -> [Token] {
        var tokens = [Token]()
        var text = ""
        var i = html.startIndex

        func flushText() {
            if !text.isEmpty {
                tokens.append(.text(decodeEntities(text)))
                text = ""
            }
        }

        while i < html.endIndex {
            let c = html[i]
            if c == "<", let (token, end) = parseTag(html, at: i) {
                flushText()
                tokens.append(token)
                i = end
            } else {
                text.append(c)
                i = html.index(after: i)
            }
        }
        flushText()
        return tokens
    }

//    A tag is "<" then an optional "/" then a letter, up to the next ">".
//    Anything else ("<3 breaths", "< 5.5 kPa") is text.

    private static func parseTag(_ html: String, at start: String.Index) -> (Token, String.Index)? {
        var i = html.index(after: start)
        guard i < html.endIndex else { return nil }
        let closing = html[i] == "/"
        if closing {
            i = html.index(after: i)
            guard i < html.endIndex else { return nil }
        }
        guard html[i].isLetter, let end = html[i...].firstIndex(of: ">") else { return nil }
        let name = String(html[i..<end].prefix { $0.isLetter }).lowercased()
        let token: Token = closing ? .close(name) : .open(name)
        return (token, html.index(after: end))
    }

    static func decodeEntities(_ text: String) -> String {
        guard text.contains("&") else { return text }
        var result = text
        for (entity, value) in [("&lt;", "<"), ("&gt;", ">"), ("&quot;", "\""),
                                ("&#39;", "'"), ("&nbsp;", "\u{00A0}"), ("&amp;", "&")] {
            result = result.replacingOccurrences(of: entity, with: value)
        }
        return result
    }


//    Block builder

    private struct Builder {
        var blocks = [RichBlock]()
        var paragraph = AttributedString()
        var items = [AttributedString]()
        var item: AttributedString?
        var inList = false

        var bold = 0
        var italic = 0
        var underline = 0
        var small = 0

        mutating func append(_ raw: String) {

//            Collapse whitespace as HTML does
            var text = raw.replacingOccurrences(of: "[ \\t\\r\\n]+", with: " ", options: .regularExpression)

            if inList && item == nil {
                guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                finishList()
            }

            let current = inList ? item! : paragraph
            if text.hasPrefix(" ") && (current.characters.isEmpty || current.characters.last?.isWhitespace == true) {
                text.removeFirst()
            }
            guard !text.isEmpty else { return }

            var run = AttributedString(text)
            run.swiftUI.font = HTMLRenderer.font(bold: bold > 0, italic: italic > 0, small: small > 0)
            if underline > 0 {
                run.swiftUI.underlineStyle = .single
            }
            appendRun(run)
        }

        mutating func appendRun(_ run: AttributedString) {
            if inList, item != nil {
                item!.append(run)
            } else {
                paragraph.append(run)
            }
        }

        mutating func lineBreak() {
            if inList && item == nil { return }

//            Whitespace before a line break isn't rendered
            if inList {
                if item!.characters.last == " " { item!.characters.removeLast() }
            } else if paragraph.characters.last == " " {
                paragraph.characters.removeLast()
            }

            var run = AttributedString("\n")
            run.swiftUI.font = HTMLRenderer.font()
            appendRun(run)
        }

        mutating func open(_ tag: String) {
            switch tag {
            case "b", "strong": bold += 1
            case "i", "em": italic += 1
            case "u": underline += 1
            case "small": small += 1
            case "br": lineBreak()
            case "p":
                if inList, let current = item {
                    if !current.characters.isEmpty && current.characters.last != "\n" {
                        lineBreak()
                    }
                } else {
                    finishList()
                    finishParagraph()
                }
            case "ul":
                finishParagraph()
                finishList()
                inList = true
            case "li":
                if !inList {
                    finishParagraph()
                    inList = true
                }
                finishItem()
                item = AttributedString()
            default:
                break
            }
        }

        mutating func close(_ tag: String) {
            switch tag {
            case "b", "strong": bold = max(0, bold - 1)
            case "i", "em": italic = max(0, italic - 1)
            case "u": underline = max(0, underline - 1)
            case "small": small = max(0, small - 1)
            case "p":
                if inList, item != nil {
                    lineBreak()
                } else {
                    finishParagraph()
                }
            case "li": finishItem()
            case "ul": finishList()
            default: break
            }
        }

        mutating func finishParagraph() {
            let text = paragraph.trimmingWhitespace()
            if !text.characters.isEmpty {
                blocks.append(.paragraph(text))
            }
            paragraph = AttributedString()
        }

        mutating func finishItem() {
            if let current = item {
                let text = current.trimmingWhitespace()
                if !text.characters.isEmpty {
                    items.append(text)
                }
            }
            item = nil
        }

        mutating func finishList() {
            guard inList else { return }
            finishItem()
            if !items.isEmpty {
                blocks.append(.bulletList(items))
            }
            items = []
            inList = false
        }

        mutating func finish() -> [RichBlock] {
            finishList()
            finishParagraph()
            return blocks
        }
    }
}
