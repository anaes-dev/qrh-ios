//
//  CalloutBox.swift
//  qrh
//
//  Types 5-9: coloured callout boxes. On iPhone they start collapsed and the
//  head toggles them; on iPad they are always open with no arrow.
//

import SwiftUI

struct CalloutBox: View {
    let color: CalloutColor
    let head: String
    let blocks: [RichBlock]
    var collapsible = true
    var expanded = false
    var toggle: () -> Void = {}

    @ScaledMetric(relativeTo: .body) private var arrowSize: CGFloat = 24

    private var showsBody: Bool { !collapsible || expanded }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if collapsible {
                Button(action: toggle) { header }
                    .buttonStyle(CalloutHeaderStyle(color: color.color))
                    .accessibilityValue(expanded ? "Expanded" : "Collapsed")
                    .accessibilityHint(expanded ? "Collapses the box" : "Expands the box")
                    .accessibilityAddTraits(.isHeader)
            } else {
                header
                    .accessibilityAddTraits(.isHeader)
            }
            if showsBody {
                RichTextView(blocks: blocks)
                    .padding(.horizontal, 13)
                    .padding(.top, 2)
                    .padding(.bottom, 12)
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.color.opacity(0.15))
        .card(cornerRadius: 6, shadowOpacity: 0.2)
        .animation(.easeInOut(duration: 0.25), value: expanded)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(head)
                .font(CardFont.head)
                .foregroundStyle(color.foreground)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            if collapsible {
                Image(systemName: expanded ? "arrow.up" : "arrow.down")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(color.foreground)
                    .frame(width: arrowSize, height: arrowSize)
                    .background(color.color.opacity(0.2))
                    .accessibilityHidden(true)
            }
        }
        .padding(8)
        .contentShape(Rectangle())
    }
}

//    0.1-alpha highlight while the head is pressed

struct CalloutHeaderStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? color.opacity(0.1) : .clear)
    }
}

#if DEBUG
#Preview("Callouts", traits: .sizeThatFitsLayout) {
    PreviewData.calloutPreview()
}

#Preview("Callouts dark", traits: .sizeThatFitsLayout) {
    PreviewData.calloutPreview()
        .preferredColorScheme(.dark)
}

#Preview("Callouts iPad", traits: .sizeThatFitsLayout) {
    PreviewData.calloutPreview(collapsible: false)
}
#endif
