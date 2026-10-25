//
//  IntroCard.swift
//  qrh
//
//  Type 1: intro body. The guideline code is drawn large and faint behind
//  the top-right of the first card only.
//

import SwiftUI

struct IntroCard: View {
    let blocks: [RichBlock]
    var code: String?

    @ScaledMetric(relativeTo: .largeTitle) private var codeSize: CGFloat = 48

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let code {
                Text(code)
                    .font(.system(size: codeSize, weight: .black))
                    .foregroundStyle(Color(.systemGray5))
                    .padding(.trailing, 4)
                    .offset(y: -10)
                    .accessibilityHidden(true)
            }
            RichTextView(blocks: blocks)
                .padding(.horizontal, 9)
                .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

#if DEBUG
#Preview("Intro", traits: .sizeThatFitsLayout) {
    PreviewData.cardPreview { IntroCard(blocks: PreviewData.introBlocks, code: "2-5") }
}

#Preview("Intro dark", traits: .sizeThatFitsLayout) {
    PreviewData.cardPreview { IntroCard(blocks: PreviewData.introBlocks, code: "2-5") }
        .preferredColorScheme(.dark)
}
#endif
