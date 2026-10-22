//
//  LaunchReminderBanner.swift
//  qrh
//
//  The disclaimer reminder shown briefly over the list on each launch once
//  the disclaimer has been accepted.
//

import SwiftUI

struct LaunchReminderBanner: View {

    static let lines = [
        "Unofficial adaptation of the Quick Reference Handbook",
        "Not endorsed by the Association of Anaesthetists",
        "Untested and unregulated; please see full disclaimers",
        "No guarantees of completeness, accuracy or performance",
        "Should not override your own knowledge and judgement",
    ]

    @ScaledMetric(relativeTo: .caption2) private var size: CGFloat = 10

    var body: some View {
        Text(Self.lines.joined(separator: "\n"))
            .font(.system(size: size))
            .foregroundStyle(Color(.systemBackground))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(8)
            .background(Color(.label).opacity(0.8), in: RoundedRectangle(cornerRadius: 4))
            .padding(.horizontal, 16)
    }
}

#if DEBUG
#Preview("Reminder", traits: .sizeThatFitsLayout) {
    LaunchReminderBanner().padding()
}

#Preview("Reminder dark", traits: .sizeThatFitsLayout) {
    LaunchReminderBanner().padding()
        .preferredColorScheme(.dark)
}
#endif
