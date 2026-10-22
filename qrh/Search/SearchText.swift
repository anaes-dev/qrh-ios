//
//  SearchText.swift
//  qrh
//
//  Text folded for forgiving matching: case, accents and punctuation are
//  ignored ("Hyper-kalaemia" matches "hyperkalaemia"), and subscripts and
//  superscripts become plain digits ("SpO₂" matches "spo2"). Each folded
//  character remembers where it came from, so matches map back to ranges of
//  the original text.
//

import Foundation

//    One word of a query, folded

struct SearchTerm: Hashable, Sendable {
    let scalars: [Unicode.Scalar]

//    Query words, folded, with punctuation-only words dropped

    static func terms(in query: String) -> [SearchTerm] {
        var terms = [SearchTerm]()
        for word in query.split(whereSeparator: \.isWhitespace) {
            let scalars = SearchText(String(word)).scalars.filter { $0 != " " }
            let term = SearchTerm(scalars: scalars)
            if !scalars.isEmpty && !terms.contains(term) {
                terms.append(term)
            }
        }
        return terms
    }
}

struct SearchText: Sendable {
    let original: String
    fileprivate let scalars: [Unicode.Scalar]
    private let origins: [Range<String.Index>]

    init(_ text: String) {
        var scalars = [Unicode.Scalar]()
        var origins = [Range<String.Index>]()
        var lastWasSpace = true
        var i = text.startIndex
        while i < text.endIndex {
            let next = text.index(after: i)
            for scalar in Self.fold(text[i..<next]) {
                if scalar.properties.isAlphabetic || scalar.properties.numericType != nil {
                    scalars.append(scalar)
                    origins.append(i..<next)
                    lastWasSpace = false
                } else if scalar.properties.isWhitespace && !lastWasSpace {
//                    Words stay apart; other punctuation is dropped
                    scalars.append(" ")
                    origins.append(i..<next)
                    lastWasSpace = true
                }
            }
            i = next
        }
        self.original = text
        self.scalars = scalars
        self.origins = origins
    }

    private static func fold(_ character: Substring) -> String.UnicodeScalarView {
        String(character)
            .precomposedStringWithCompatibilityMapping
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
            .unicodeScalars
    }

    func contains(_ term: SearchTerm) -> Bool {
        firstOffset(of: term, from: 0) != nil
    }

    func contains(all terms: [SearchTerm]) -> Bool {
        terms.allSatisfy(contains)
    }

//    Ranges of the original text matching the term, in order

    func ranges(of term: SearchTerm) -> [Range<String.Index>] {
        var ranges = [Range<String.Index>]()
        var from = 0
        while let offset = firstOffset(of: term, from: from) {
            let end = offset + term.scalars.count
            ranges.append(origins[offset].lowerBound..<origins[end - 1].upperBound)
            from = end
        }
        return ranges
    }

    func firstRange(of term: SearchTerm) -> Range<String.Index>? {
        guard let offset = firstOffset(of: term, from: 0) else { return nil }
        return origins[offset].lowerBound..<origins[offset + term.scalars.count - 1].upperBound
    }

    private func firstOffset(of term: SearchTerm, from start: Int) -> Int? {
        let needle = term.scalars
        guard let first = needle.first, needle.count <= scalars.count else { return nil }
        var i = start
        let last = scalars.count - needle.count
        while i <= last {
            if scalars[i] == first {
                var j = 1
                while j < needle.count && scalars[i + j] == needle[j] { j += 1 }
                if j == needle.count { return i }
            }
            i += 1
        }
        return nil
    }
}
