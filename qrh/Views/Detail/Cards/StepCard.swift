//
//  StepCard.swift
//  qrh
//
//  Type 3: step badge, bold head and body below.
//  Type 4: step badge with the body beside it.
//

import SwiftUI

struct StepCard: View {
    let step: String
    var head: String?
    let blocks: [RichBlock]

//    Lines a type 4 body's first line up with the middle of the badge
    @ScaledMetric(relativeTo: .body) private var bodyOffset: CGFloat = 7

    var body: some View {
        Group {
            if let head {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        StepBadge(step: step)
                        Text(head)
                            .font(CardFont.head)
                            .foregroundStyle(Color(.label))
                            .fixedSize(horizontal: false, vertical: true)
                    }
//                    "Step 1, Immediate actions", as a heading
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isHeader)
                    RichTextView(blocks: blocks)
                        .padding(.horizontal, 5)
                }
            } else {
                HStack(alignment: .top, spacing: 8) {
                    StepBadge(step: step)
                        .accessibilityAddTraits(.isHeader)
                    RichTextView(blocks: blocks)
                        .padding(.top, bodyOffset)
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

#if DEBUG
#Preview("Steps", traits: .sizeThatFitsLayout) {
    PreviewData.cardPreview {
        VStack(spacing: 16) {
            StepCard(step: "1", head: "Immediate actions", blocks: PreviewData.richBlocks)
            StepCard(step: "2", blocks: HTMLRenderer.render("Call for help and consider temporising drug (Box C)."))
        }
    }
}

#Preview("Steps dark", traits: .sizeThatFitsLayout) {
    PreviewData.cardPreview {
        VStack(spacing: 16) {
            StepCard(step: "1", head: "Immediate actions", blocks: PreviewData.richBlocks)
            StepCard(step: "!", blocks: HTMLRenderer.render("The original handbook PDF can be downloaded."))
        }
    }
    .preferredColorScheme(.dark)
}
#endif
