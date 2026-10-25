//
//  BreadcrumbBar.swift
//  qrh
//
//  "Home > Guideline > Guideline" trail shown when two or more guidelines
//  are stacked. Scrolls horizontally, starting at the trailing end, and fades
//  out at both edges.
//

import SwiftUI

struct BreadcrumbBar: View {
    let titles: [String]
    var onHome: () -> Void = {}
    var onSelect: (Int) -> Void = { _ in }

    @ScaledMetric(relativeTo: .caption) private var height: CGFloat = 32

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    crumb(icon: "house", title: "Home", action: onHome)
                        .accessibilityIdentifier("Breadcrumb-Home")
                        .id(-1)
                    ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                        crumb(icon: "chevron.forward", title: title) { onSelect(index) }
                            .accessibilityIdentifier("Breadcrumb-\(index)")
                            .id(index)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onAppear {
                proxy.scrollTo(titles.count - 1, anchor: .trailing)
            }
        }
        .frame(height: height)
        .overlay {
            HStack(spacing: 0) {
                LinearGradient(stops: [.init(color: Color(.systemGray6), location: 0.2),
                                       .init(color: Color(.systemGray6).opacity(0), location: 1)],
                               startPoint: .leading, endPoint: .trailing)
                    .frame(width: 16)
                Spacer()
                LinearGradient(stops: [.init(color: Color(.systemGray6).opacity(0), location: 0),
                                       .init(color: Color(.systemGray6), location: 0.8)],
                               startPoint: .leading, endPoint: .trailing)
                    .frame(width: 16)
            }
            .allowsHitTesting(false)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Breadcrumbs")
    }

    private func crumb(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.body)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.caption)
            }
            .padding(.trailing, 8)
            .frame(height: height)
        }
        .buttonStyle(BreadcrumbStyle())
    }
}

struct BreadcrumbStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.accentColor.opacity(configuration.isPressed ? 0.7 : 1))
    }
}

#if DEBUG
#Preview("Breadcrumbs", traits: .sizeThatFitsLayout) {
    BreadcrumbBar(titles: ["Bradycardia", "Cardiac arrest", "Anaphylaxis", "Bronchospasm"])
        .background(Color(.systemGray6))
}

#Preview("Breadcrumbs dark", traits: .sizeThatFitsLayout) {
    BreadcrumbBar(titles: ["Bradycardia", "Cardiac arrest"])
        .background(Color(.systemGray6))
        .preferredColorScheme(.dark)
}
#endif
