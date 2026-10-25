//
//  WarningCard.swift
//  qrh
//
//  Type 12: red warning text on a red-tinted card.
//

import SwiftUI

struct WarningCard: View {
    let text: String

    @ScaledMetric(relativeTo: .subheadline) private var size: CGFloat = 14

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(Color(.systemRed))
            .fixedSize(horizontal: false, vertical: true)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemRed).opacity(0.2))
            .card(shadowOpacity: 0.2)
    }
}

#if DEBUG
#Preview("Warning", traits: .sizeThatFitsLayout) {
    PreviewData.cardPreview { WarningCard(text: PreviewData.warning) }
}

#Preview("Warning dark", traits: .sizeThatFitsLayout) {
    PreviewData.cardPreview { WarningCard(text: PreviewData.warning) }
        .preferredColorScheme(.dark)
}
#endif
