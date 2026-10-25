//
//  BoxTable.swift
//  qrh
//
//  A box's table, drawn in place of its body (4-1's oxygen cylinder
//  contents). The first column, which names each row, is 0.6 the width of
//  each value column. Cells wrap rather than truncate, and use the box body's
//  text style, so they follow Dynamic Type. When a word wouldn't fit its
//  column (the largest text sizes), each row is stacked instead: its name,
//  then each value under its heading. VoiceOver reads each data row with its
//  headings; the heading row itself is hidden.
//

import SwiftUI
import UIKit

struct BoxTable: View {
    let table: CardTable
    let color: CalloutColor

    @Environment(\.searchHighlight) private var highlight
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var width: CGFloat?

    nonisolated static func weights(_ table: CardTable) -> [CGFloat] {
        table.columns.indices.map { $0 == 0 ? 0.6 : 1 }
    }

    private var weights: [CGFloat] { Self.weights(table) }

    var body: some View {
        Group {
            if let width, !Self.wordsFit(table, width: width, typeSize: typeSize) {
                stacked
            } else {
                grid
            }
        }
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { width = $0 }
    }

    private var grid: some View {
        VStack(spacing: 0) {
            row(table.columns.map(Self.heading), heading: true)
                .accessibilityHidden(true)
            Rectangle()
                .fill(color.color.opacity(0.5))
                .frame(height: 1.5)
            ForEach(Array(table.rows.enumerated()), id: \.offset) { index, cells in
                if index > 0 {
                    Rectangle()
                        .fill(color.color.opacity(0.2))
                        .frame(height: 1)
                }
                row(cells, heading: false)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(table.spokenRow(cells))
            }
        }
    }

//    One block per row: its name in bold, then each value after its heading

    private var stacked: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(table.rows.enumerated()), id: \.offset) { index, cells in
                if index > 0 {
                    Rectangle()
                        .fill(color.color.opacity(0.2))
                        .frame(height: 1)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(text(([table.columns.first, cells.first].compactMap { $0 }).joined(separator: " ")))
                        .font(HTMLRenderer.font(bold: true))
                        .foregroundStyle(color.foreground)
                    ForEach(Array(zip(table.columns, cells).dropFirst().enumerated()), id: \.offset) { _, pair in
                        Text(value(pair.1, heading: pair.0))
                            .font(HTMLRenderer.font())
                            .foregroundStyle(Color(.label))
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(table.spokenRow(cells))
            }
        }
    }

    private func text(_ string: String) -> AttributedString {
        AttributedString(string).highlighting(highlight)
    }

//    "25% full (34 bar): 43 L", the heading in the secondary colour

    private func value(_ cell: String, heading: String) -> AttributedString {
        var line = text(heading + ": ")
        line.foregroundColor = Color(.secondaryLabel)
        return line + text(cell)
    }

//    Whether every word of every cell fits its column at this text size, so
//    the grid never breaks a word

    nonisolated static func wordsFit(_ table: CardTable, width: CGFloat, typeSize: DynamicTypeSize) -> Bool {
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(typeSize))
        let plain = UIFont.preferredFont(forTextStyle: .subheadline, compatibleWith: traits)
        let bold = plain.fontDescriptor.withSymbolicTraits(.traitBold).map { UIFont(descriptor: $0, size: 0) } ?? plain
        let weights = weights(table)
        let total = weights.reduce(0, +)
        for (column, weight) in weights.enumerated() {
            let available = width * weight / total - 4
            let headings = heading(table.columns[column])
            let cells = table.rows.compactMap { column < $0.count ? $0[column] : nil }
            let words = headings.split(whereSeparator: \.isWhitespace).map { (String($0), bold) }
                + cells.flatMap { cell in
                    cell.split(whereSeparator: \.isWhitespace).map { (String($0), column == 0 ? bold : plain) }
                }
            for (word, font) in words where (word as NSString).size(withAttributes: [.font: font]).width > available {
                return false
            }
        }
        return true
    }

    private func row(_ cells: [String], heading: Bool) -> some View {
        TableRowLayout(weights: weights) {
            ForEach(Array(cells.enumerated()), id: \.offset) { column, cell in
                let first = column == 0
                Text(AttributedString(cell).highlighting(highlight))
                    .font(HTMLRenderer.font(bold: heading || first))
                    .foregroundStyle(heading || first ? color.foreground : Color(.label))
                    .multilineTextAlignment(first ? .leading : .center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: first ? .leading : .center)
            }
        }
    }

//    A bracketed part of a heading goes on its own line, so "25% full
//    (34 bar)" never breaks inside the brackets at the usual sizes

    nonisolated static func heading(_ text: String) -> String {
        text.replacingOccurrences(of: " (", with: "\n(")
    }
}


//    One row: cells side by side in widths proportional to their weights,
//    top-aligned, as tall as the tallest

struct TableRowLayout: Layout {
    let weights: [CGFloat]

    private func widths(_ total: CGFloat, count: Int) -> [CGFloat] {
        let weights = (0..<count).map { $0 < self.weights.count ? self.weights[$0] : 1 }
        let sum = max(weights.reduce(0, +), 1)
        return weights.map { total * $0 / sum }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? 320
        let widths = widths(width, count: subviews.count)
        let height = zip(subviews, widths).map { subview, width in
            subview.sizeThatFits(ProposedViewSize(width: width, height: nil)).height
        }.max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        for (subview, width) in zip(subviews, widths(bounds.width, count: subviews.count)) {
            subview.place(at: CGPoint(x: x, y: bounds.minY), anchor: .topLeading,
                          proposal: ProposedViewSize(width: width, height: nil))
            x += width
        }
    }
}

#if DEBUG
#Preview("Table", traits: .sizeThatFitsLayout) {
    PreviewData.cardPreview {
        CalloutBox(color: .gray, head: "Box B: OXYGEN CYLINDER REMAINING CONTENTS", blocks: [],
                   table: PreviewData.oxygenTable, expanded: true)
    }
}

#Preview("Table dark", traits: .sizeThatFitsLayout) {
    PreviewData.cardPreview {
        CalloutBox(color: .gray, head: "Box B: OXYGEN CYLINDER REMAINING CONTENTS", blocks: [],
                   table: PreviewData.oxygenTable, collapsible: false)
    }
    .preferredColorScheme(.dark)
}
#endif
