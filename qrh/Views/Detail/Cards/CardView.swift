//
//  CardView.swift
//  qrh
//

import SwiftUI

//    Picks the view for a card's kind

struct CardView: View {
    let card: RenderedCard
    let code: String
    var isPad = false
    var expanded = false
    var toggle: () -> Void = {}

//    Setting in About: boxes always open, as on iPad
    @AppStorage("expandingDisabled") private var expandingDisabled = false

    var body: some View {
        switch card.kind {
        case .intro:
//            Some guidelines have more than one intro card; only the first shows the code
            IntroCard(blocks: card.blocks, code: card.index == 0 ? code : nil)
        case .start:
            StartCard(blocks: card.blocks)
        case .step:
            StepCard(step: card.card.step, head: card.card.head, blocks: card.blocks)
        case .stepBodyOnly:
            StepCard(step: card.card.step, blocks: card.blocks)
        case .callout(let color):
            CalloutBox(color: color, head: card.card.head, blocks: card.blocks,
                       collapsible: !isPad && !expandingDisabled, expanded: expanded, toggle: toggle)
        case .image:
            ImageCard(head: card.card.head, imageName: card.card.body)
        case .version:
            VersionFooter(version: card.card.body)
        case .warning:
            WarningCard(text: card.card.head)
        case .unknown:
//            Plain body on iPhone, hidden on iPad
            if !isPad {
                IntroCard(blocks: card.blocks)
            }
        }
    }
}

#if DEBUG
#Preview("All card kinds") {
    ScrollView {
        VStack(spacing: 0) {
            ForEach(PreviewData.cards) { card in
                CardView(card: card, code: "2-5", expanded: true)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
        }
    }
    .background(Color(.systemGray6))
}

#Preview("All card kinds dark") {
    ScrollView {
        VStack(spacing: 0) {
            ForEach(PreviewData.cards) { card in
                CardView(card: card, code: "2-5", expanded: true)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
        }
    }
    .background(Color(.systemGray6))
    .preferredColorScheme(.dark)
}
#endif
