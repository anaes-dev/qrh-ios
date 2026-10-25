//
//  LinkDetector.swift
//  qrh
//
//  Adds tappable links to rendered card text:
//  - references to other guidelines ("→3-5", "(→ 2-1)") become
//    qrh://guideline/<code> links, underlined, routed in-app by RootView;
//  - web addresses and phone numbers are found with NSDataDetector, per card
//    kind, matching the data detectors the UIKit text views had.
//

import Foundation
import SwiftUI

enum LinkDetector {

    static let guidelinePattern = "[(]?[→][\\s]?[1-4][-][0-9]{1,2}[)]?"
    static let scheme = "qrh"
    static let host = "guideline"

    private static let guidelineRegex = try! NSRegularExpression(pattern: guidelinePattern)


//    Guideline link URLs (an internal marker only; not registered in Info.plist)

    static func guidelineURL(code: String) -> URL {
        URL(string: "\(scheme)://\(host)/\(code)")!
    }

    static func guidelineCode(from url: URL) -> String? {
        guard url.scheme == scheme, url.host == host else { return nil }
        let code = url.lastPathComponent
        return code.isEmpty || code == "/" ? nil : code
    }

//    Codes referenced in text, in order of appearance

    static func guidelineCodes(in text: String) -> [String] {
        guidelineMatches(in: text).map(\.code)
    }

    static func guidelineMatches(in text: String) -> [(range: NSRange, code: String)] {
        let ns = text as NSString
        return guidelineRegex.matches(in: text, range: NSRange(location: 0, length: ns.length)).map { match in
            let matched = ns.substring(with: match.range)
            let code = matched.filter { !"()→".contains($0) && !$0.isWhitespace }
            return (match.range, code)
        }
    }


//    Data detection
//
//    Some dose ranges ("500-1000 ml") are misdetected as phone numbers, so data
//    detection is switched off for these rows (index into the card list).

    struct CardRef: Hashable, Sendable {
        let code: String
        let row: Int
    }

    static let dataDetectionExclusions: Set<CardRef> = [
        CardRef(code: "3-5", row: 7),
        CardRef(code: "3-9", row: 8),
        CardRef(code: "2-5", row: 12),
    ]

    static func dataDetectorTypes(for kind: CardKind, code: String, row: Int) -> NSTextCheckingResult.CheckingType {
        if dataDetectionExclusions.contains(CardRef(code: code, row: row)) {
            return []
        }
        switch kind {
        case .intro:
            return [.link]
        case .step, .stepBodyOnly, .callout:
            return [.link, .phoneNumber]
        default:
            return []
        }
    }

    private static let linkDetector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    private static let linkAndPhoneDetector = try! NSDataDetector(
        types: NSTextCheckingResult.CheckingType.link.rawValue | NSTextCheckingResult.CheckingType.phoneNumber.rawValue)


//    Add links to one block of text

    static func addLinks(to text: inout AttributedString, detecting types: NSTextCheckingResult.CheckingType) {
        let plain = String(text.characters)
        let fullRange = NSRange(location: 0, length: (plain as NSString).length)
        var linked = [NSRange]()

        for match in guidelineMatches(in: plain) {
            guard let range = Range(match.range, in: text) else { continue }
            text[range].link = guidelineURL(code: match.code)
            text[range].swiftUI.underlineStyle = .single
            linked.append(match.range)
        }

        let detector: NSDataDetector?
        if types.contains(.phoneNumber) {
            detector = linkAndPhoneDetector
        } else if types.contains(.link) {
            detector = linkDetector
        } else {
            detector = nil
        }
        guard let detector else { return }

        for result in detector.matches(in: plain, range: fullRange) {
            guard !linked.contains(where: { NSIntersectionRange($0, result.range).length > 0 }),
                  let url = url(for: result),
                  let range = Range(result.range, in: text) else { continue }
            text[range].link = url
            linked.append(result.range)
        }
    }

    static func addLinks(to block: RichBlock, detecting types: NSTextCheckingResult.CheckingType) -> RichBlock {
        switch block {
        case .paragraph(var text):
            addLinks(to: &text, detecting: types)
            return .paragraph(text)
        case .bulletList(let items):
            return .bulletList(items.map { item in
                var text = item
                addLinks(to: &text, detecting: types)
                return text
            })
        }
    }

    private static func url(for result: NSTextCheckingResult) -> URL? {
        switch result.resultType {
        case .link:
            return result.url
        case .phoneNumber:
            guard let number = result.phoneNumber else { return nil }
            let digits = number.filter { $0.isNumber || $0 == "+" }
            return digits.isEmpty ? nil : URL(string: "tel:\(digits)")
        default:
            return nil
        }
    }
}
