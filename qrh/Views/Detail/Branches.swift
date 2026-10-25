//
//  Branches.swift
//  qrh
//
//  A fork's alternative branches (3-7, 3-10). Each branch has its condition
//  as a heading, then a rail joined to it down the leading side of its cards. Every
//  branch is always shown: side by side when the fork is at least 600 pt
//  wide, otherwise stacked. (The fork's own width counts, not the screen's:
//  beside the iPad sidebar in portrait, side by side squeezed the steps.)
//

import SwiftUI

struct ForkView<Row: View>: View {
    let fork: Fork
//    An item card in a branch, given the branch's header
    @ViewBuilder let row: (RenderedCard, RenderedCard) -> Row

    var body: some View {
        ForkLayout {
            ForEach(fork.branches, id: \.header.index) { branch in
                VStack(spacing: 0) {
                    BranchHeading(header: branch.header, joinsRail: true)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .id(RowID.card(branch.header.index))
//                    The rail carries on from the heading's square corner, in
//                    line with its outline (and over it, so no seam shows),
//                    down to the end of the last card
                    VStack(spacing: 0) {
                        ForEach(branch.cards) { card in
                            row(card, branch.header)
                        }
                    }
                    .padding(.leading, 14)
                    .background(alignment: .topLeading) {
                        UnevenRoundedRectangle(bottomLeadingRadius: BranchStyle.width / 2,
                                               bottomTrailingRadius: BranchStyle.width / 2)
                            .fill(BranchStyle.line)
                            .frame(width: BranchStyle.width)
                            .padding(.leading, 16)
                            .padding(.top, -BranchStyle.width)
                            .padding(.bottom, 8)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
    }
}


//    The condition: an outlined box with a split symbol and the bold text,
//    with search words highlighted. Above a rail, its corner over the rail is
//    square, so the two read as one bracket.

struct BranchHeading: View {
    let header: RenderedCard
    var joinsRail = false

    @Environment(\.searchHighlight) private var highlight

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "arrow.triangle.branch")
                .font(.subheadline.weight(.semibold))
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Color(.label))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.systemBackground), in: shape)
        .overlay {
            shape.strokeBorder(BranchStyle.line, lineWidth: BranchStyle.width)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(header.blocks.plainText)
        .accessibilityAddTraits(.isHeader)
    }

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: joinsRail ? 0 : 4,
                               bottomTrailingRadius: 4, topTrailingRadius: 4)
    }

    private var text: AttributedString {
        Self.condition(header).highlighting(highlight)
    }

//    The condition's text, bold (15 pt at the default size), keeping its
//    underlines

    static func condition(_ header: RenderedCard) -> AttributedString {
        var text = AttributedString()
        for block in header.blocks {
            if !text.characters.isEmpty {
                text.append(AttributedString("\n"))
            }
            switch block {
            case .paragraph(let paragraph): text.append(paragraph)
            case .bulletList: text.append(AttributedString(block.plainText))
            }
        }
        text.swiftUI.font = HTMLRenderer.font(bold: true)
        return text
    }
}

enum BranchStyle {
    static let line = Color(.systemGray2)
//    The heading's outline and the rail
    static let width: CGFloat = 2
}


//    Branches side by side in equal widths if the proposed width allows,
//    otherwise one above the other

struct ForkLayout: Layout {
    var minimumSideBySideWidth: CGFloat = 600
    var spacing: CGFloat = 8

    private func sideBySide(_ width: CGFloat?, count: Int) -> Bool {
        count > 1 && (width ?? 0) >= minimumSideBySideWidth && width?.isFinite == true
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        if sideBySide(proposal.width, count: subviews.count), let width = proposal.width {
            let column = ProposedViewSize(width: width / CGFloat(subviews.count), height: nil)
            return CGSize(width: width, height: subviews.map { $0.sizeThatFits(column).height }.max() ?? 0)
        }
        let sizes = subviews.map { $0.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil)) }
        let height = sizes.map(\.height).reduce(0, +) + spacing * CGFloat(subviews.count - 1)
        return CGSize(width: proposal.width ?? sizes.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        if sideBySide(bounds.width, count: subviews.count) {
            let width = bounds.width / CGFloat(subviews.count)
            for (index, subview) in subviews.enumerated() {
                subview.place(at: CGPoint(x: bounds.minX + width * CGFloat(index), y: bounds.minY),
                              anchor: .topLeading, proposal: ProposedViewSize(width: width, height: nil))
            }
        } else {
            var y = bounds.minY
            let column = ProposedViewSize(width: bounds.width, height: nil)
            for subview in subviews {
                subview.place(at: CGPoint(x: bounds.minX, y: y), anchor: .topLeading, proposal: column)
                y += subview.sizeThatFits(column).height + spacing
            }
        }
    }
}

#if DEBUG
#Preview("Fork stacked") {
    PreviewData.detailPreview(code: "3-10")
}

#Preview("Fork side by side", traits: .landscapeLeft) {
    PreviewData.detailPreview(code: "3-7")
        .environment(\.horizontalSizeClass, .regular)
}
#endif
