//
//  GuidelineRow.swift
//  qrh
//
//  Code, title and version, laid out as GuidelinesCell was.
//

import SwiftUI

struct GuidelineRow: View {
    let guideline: Guideline
//    While searching: words to highlight, and text from inside the guideline
    var highlight: [SearchTerm] = []
    var snippet: String?

    @ScaledMetric(relativeTo: .caption) private var codeWidth: CGFloat = 50
    @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = 51
    @ScaledMetric(relativeTo: .caption2) private var versionSize: CGFloat = 10
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
//        Code beside the title, or above it at accessibility text sizes
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(spacing: 0))
        HStack(spacing: 0) {
            layout {
                Text(guideline.code)
                    .font(.caption)
                    .foregroundStyle(Color(.secondaryLabel))
                    .frame(width: typeSize.isAccessibilitySize ? nil : codeWidth, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    Text(Self.highlighted(guideline.title, terms: highlight))
                        .font(.body)
                        .foregroundStyle(Color(.label))
                        .multilineTextAlignment(.leading)
                    if let snippet {
                        Text(Self.highlighted(snippet, terms: highlight))
                            .font(.footnote)
                            .foregroundStyle(Color(.secondaryLabel))
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                    }
                }
            }
            Spacer(minLength: 24)
        }
        .padding(.vertical, 8)
        .frame(minHeight: minHeight)
        .overlay(alignment: .bottomTrailing) {
            Text("v.\(guideline.version)")
                .font(.system(size: versionSize))
                .foregroundStyle(Color(.secondaryLabel))
                .padding(.bottom, 4)
                .accessibilityLabel("version \(guideline.version)")
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    static func highlighted(_ string: String, terms: [SearchTerm]) -> AttributedString {
        AttributedString(string).highlighting(terms)
    }
}

extension AttributedString {

//    Copy with the search words given a yellow background

    func highlighting(_ terms: [SearchTerm]) -> AttributedString {
        guard !terms.isEmpty else { return self }
        var text = self
        let string = String(characters)
        let search = SearchText(string)
        for term in terms {
            for range in search.ranges(of: term) {
                if let range = Range(NSRange(range, in: string), in: text) {
                    text[range].backgroundColor = Color(.systemYellow).opacity(0.4)
                }
            }
        }
        return text
    }
}

#if DEBUG
#Preview("Rows", traits: .sizeThatFitsLayout) {
    List(PreviewData.store.guidelines.prefix(4)) { GuidelineRow(guideline: $0) }
        .listStyle(.plain)
        .frame(height: 260)
}

#Preview("Search results", traits: .sizeThatFitsLayout) {
    let results = PreviewData.store.searchIndex.search("hyperthermia")
    List(results) { result in
        GuidelineRow(guideline: result.guideline, highlight: result.terms,
                     snippet: "…give dantrolene 2.5 mg.kg⁻¹ and treat hyperthermia with active cooling…")
    }
    .listStyle(.plain)
    .frame(height: 260)
}

#Preview("Rows dark", traits: .sizeThatFitsLayout) {
    List(PreviewData.store.guidelines.prefix(4)) { GuidelineRow(guideline: $0) }
        .listStyle(.plain)
        .frame(height: 260)
        .preferredColorScheme(.dark)
}
#endif
