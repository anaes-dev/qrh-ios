//
//  ImageCard.swift
//  qrh
//
//  Type 10: bundled image (body is the file name) with a bold caption.
//

import SwiftUI
import UIKit

struct ImageCard: View {
    let head: String
    let imageName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(head)
                .font(CardFont.head)
                .foregroundStyle(Color(.label))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let image = UIImage(named: imageName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(head)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

#if DEBUG
#Preview("Image", traits: .sizeThatFitsLayout) {
    PreviewData.cardPreview { ImageCard(head: "Image", imageName: "logo.png") }
}
#endif
