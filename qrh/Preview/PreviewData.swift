//
//  PreviewData.swift
//  qrh
//
//  Sample content for #Previews (Debug builds only).
//

import SwiftUI

#if DEBUG

@MainActor
enum PreviewData {

    static let store = GuidelineStore()

    static let introBlocks = HTMLRenderer.render("Hypertension is most commonly due to inappropriate depth of anaesthesia or inadequate analgesia.")

    static let richBlocks = CardRenderer.blocks(
        for: Card(type: 3, head: "", body: "<p>Consider <b>bold</b>, <i>italic</i>, <u>underline</u> and F<small>i</small>O₂ <b>→1-1</b>:</p><ul><li>Call 07947609601</li><li>See www.anaesthetists.org/qrh</li></ul>", step: "1"),
        kind: .step, code: "preview", row: 0)

    static let warning = "The guidelines in this handbook are not intended to be standards of medical care."

    static var cards: [RenderedCard] {
        let samples = [
            Card(type: 1, head: "", body: "Hypertension is most commonly due to inappropriate depth of anaesthesia.", step: ""),
            Card(type: 2, head: "", body: "<b>START</b>", step: ""),
            Card(type: 3, head: "Immediate actions", body: "Recheck blood pressure AND increase anaesthesia.", step: "1"),
            Card(type: 4, head: "", body: "Call for help and consider temporising drug (Box C).", step: "2"),
            Card(type: 5, head: "Box A: CRITICAL CHANGES", body: "Go back to <b>START</b> of <b>key basic plan →1-1</b>", step: ""),
            Card(type: 6, head: "Box B: DRUGS", body: "<ul><li>Alfentanil 10 µg.kg⁻¹ <small>(adult 0.5-1 mg)</small></li></ul>", step: ""),
            Card(type: 7, head: "Green box", body: "CPR information", step: ""),
            Card(type: 8, head: "Gray box", body: "Other information", step: ""),
            Card(type: 9, head: "Purple box", body: "Call 07947609601", step: ""),
            Card(type: 10, head: "Box B: OXYGEN CYLINDER REMAINING CONTENTS", body: "oxygen.png", step: ""),
            Card(type: 11, head: "", body: "v.1", step: ""),
            Card(type: 12, head: warning, body: "", step: ""),
        ]
        return CardRenderer.render(samples, code: "preview")
    }

    static func cardPreview(@ViewBuilder _ content: () -> some View) -> some View {
        content()
            .padding(16)
            .background(Color(.systemGray6))
    }

    static func calloutPreview(collapsible: Bool = true) -> some View {
        cardPreview {
            VStack(spacing: 16) {
                ForEach(Array(CalloutColor.allCases.enumerated()), id: \.offset) { index, color in
                    CalloutBox(color: color, head: "Box \(index): CALLOUT", blocks: richBlocks,
                               collapsible: collapsible, expanded: index == 0)
                }
            }
        }
    }

    static func detailPreview(code: String) -> some View {
        let router = Router()
        router.path = ["2-6", code]
        return NavigationStack {
            GuidelineDetailView(code: code)
        }
        .environment(store)
        .environment(router)
    }

    static func listPreview(reminder: ReminderState) -> some View {
        NavigationStack {
            GuidelineListView(reminder: .constant(reminder))
        }
        .environment(store)
        .environment(Router())
    }
}
#endif
