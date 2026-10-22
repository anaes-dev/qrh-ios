//
//  StartCard.swift
//  qrh
//
//  Type 2: the inverted START banner.
//

import SwiftUI

struct StartCard: View {
    let blocks: [RichBlock]

    var body: some View {
        Text(text)
            .foregroundStyle(Color(.systemBackground))
            .padding(4)
            .background(Color(.label))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var text: AttributedString {
        if case .paragraph(let text) = blocks.first {
            return text
        }
        var text = AttributedString(blocks.plainText)
        text.swiftUI.font = HTMLRenderer.font(bold: true)
        return text
    }
}

#if DEBUG
#Preview("Start", traits: .sizeThatFitsLayout) {
    PreviewData.cardPreview { StartCard(blocks: HTMLRenderer.render("<b>START</b>")) }
}

#Preview("Start dark", traits: .sizeThatFitsLayout) {
    PreviewData.cardPreview { StartCard(blocks: HTMLRenderer.render("<b>START</b>")) }
        .preferredColorScheme(.dark)
}
#endif
