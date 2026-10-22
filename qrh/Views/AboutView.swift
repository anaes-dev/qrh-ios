//
//  AboutView.swift
//  qrh
//

import SwiftUI

struct AboutView: View {

    static let licence = """
        This material is a derivative of the "Quick Reference Handbook" (www.anaesthetists.org/qrh) by The Association of Anaesthetists (www.anaesthetists.org), used under Creative Commons license CC BY-NC-SA 4.0 (www.creativecommons.org/licenses/by-nc-sa/4.0).

        Subject to Creative Commons license CC BY-NC-SA 4.0. You may distribute original version or adapt for yourself and distribute with acknowledgement of source. You may not use for commercial purposes.
        """
    static let privacyURL = URL(string: "http://qrh.anaes.dev/privacy")!

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var showDisclaimer = false

    @ScaledMetric(relativeTo: .subheadline) private var textSize: CGFloat = 14
    @ScaledMetric(relativeTo: .title2) private var iconSize: CGFloat = 26
    @ScaledMetric(relativeTo: .body) private var barHeight: CGFloat = 50

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    AppInfoHeader(licenceText: Self.licence)

                    VStack(alignment: .leading, spacing: 16) {
                        explainer(icon: "arrow.down.doc",
                                  text: "Click this icon at the top-right of each guideline to access the original PDF file from the Association of Anaesthetists website.")
                        explainer(icon: "arrow.right",
                                  text: "Click highlighted links to jump to related guidelines.")
                    }
                    .padding(.top, 24)

                    Text("Please report any bugs via the github page.")
                        .font(.system(size: textSize))
                        .padding(.top, 24)

                    HStack {
                        Button("Privacy Policy") { openURL(Self.privacyURL) }
                            .frame(maxWidth: .infinity)
                        Button("Disclaimers") { showDisclaimer = true }
                            .frame(maxWidth: .infinity)
                    }
                    .font(.body)
                    .tint(Color(.link))
                    .frame(minHeight: barHeight)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 4))
                    .shadow(color: .black.opacity(0.1), radius: 2)
                    .padding(.horizontal, 15)
                    .padding(.top, 12)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton { dismiss() }
                }
            }
            .sheet(isPresented: $showDisclaimer) {
                DisclaimerView()
            }
        }
    }

    private func explainer(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .light))
                .foregroundStyle(Color(.systemGray))
                .frame(width: iconSize + 2)
                .accessibilityHidden(true)
            Text(text)
                .font(.system(size: textSize))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#if DEBUG
#Preview("About") {
    AboutView()
}

#Preview("About dark") {
    AboutView()
        .preferredColorScheme(.dark)
}
#endif
