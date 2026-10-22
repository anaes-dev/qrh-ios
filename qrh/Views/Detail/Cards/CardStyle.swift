//
//  CardStyle.swift
//  qrh
//
//  Shared card styling, matching the CardCell XIBs: systemBackground,
//  rounded corners and a soft black shadow.
//

import SwiftUI

struct CardBackground: ViewModifier {
    var cornerRadius: CGFloat = 4
    var shadowOpacity: Double = 0.1

    func body(content: Content) -> some View {
        content
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(shadowOpacity), radius: 2)
    }
}

extension View {
    func card(cornerRadius: CGFloat = 4, shadowOpacity: Double = 0.1) -> some View {
        modifier(CardBackground(cornerRadius: cornerRadius, shadowOpacity: shadowOpacity))
    }
}


//    Inverted round step badge (types 3 and 4)

struct StepBadge: View {
    let step: String
//    What VoiceOver says (the disclaimer's numbered sections aren't steps)
    var spokenAs: String?

    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 32

    var body: some View {
        Text(step)
            .font(.body.bold())
            .foregroundStyle(Color(.systemBackground))
            .frame(width: size, height: size)
            .background(Circle().fill(Color(.label)))
            .accessibilityLabel(spokenAs ?? "Step \(step)")
    }
}


//    Callout colours (types 5-9), from CardCell5.boxCol

extension CalloutColor {
    var color: Color {
        switch self {
        case .orange: Color(.systemOrange)
        case .blue: Color(.systemBlue)
        case .green: Color(.systemGreen)
        case .gray: Color(.systemGray)
        case .purple: Color(.systemPurple)
        }
    }

//    Gray boxes use the label colour for the head and arrow

    var foreground: Color {
        self == .gray ? Color(.label) : color
    }
}

//    Sizes are text styles (or @ScaledMetric) so they follow Dynamic Type;
//    at the default size they match the XIBs (head: 17 pt bold)

enum CardFont {
    static let head = Font.body.bold()
}
