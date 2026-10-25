//
//  VersionFooter.swift
//  qrh
//
//  Type 11: right-aligned "Adapted from QRH section v.N".
//

import SwiftUI

struct VersionFooter: View {
    let version: String

    var body: some View {
        Text("Adapted from QRH section " + version)
            .font(.footnote)
            .foregroundStyle(Color(.systemGray))
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

#if DEBUG
#Preview("Version", traits: .sizeThatFitsLayout) {
    PreviewData.cardPreview { VersionFooter(version: "v.1") }
}
#endif
