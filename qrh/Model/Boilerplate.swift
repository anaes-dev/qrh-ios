//
//  Boilerplate.swift
//  qrh
//
//  The cards every guideline ends with, which data.json doesn't repeat: the
//  version line, the disclaimer, and the licence footer naming the
//  guideline's publisher and year.
//

import Foundation

enum Boilerplate {

    static let disclaimer = "The guidelines in this handbook are not intended to be standards of medical care. The ultimate judgement with regard to a particular clinical procedure or treatment plan must be made by the clinician in the light of the clinical data presented and the diagnostic and treatment options available."

    static let licence = "Subject to Creative Commons license CC BY-NC-SA 4.0. You may distribute original version or adapt for yourself and distribute with acknowledgement of source. You may not use for commercial purposes. Visit website for details."

    static func cards(for guideline: Guideline, holders: [String: CopyrightHolder]) -> [Card] {
        let holder = holders[guideline.copyright.holder]
        let publisher = [holder?.name ?? guideline.copyright.holder, "\(guideline.copyright.year)."]
            .joined(separator: " ")
        let website = holder.map { " \($0.website)" } ?? ""
        return [
            Card(type: 11, head: "", body: "v.\(guideline.version)", step: ""),
            Card(type: 12, head: disclaimer, body: "", step: ""),
            Card(type: 1, head: "", body: "<p><small><b>\(publisher)\(website)</b></small></p><p><small>\(licence)</small></p>", step: ""),
        ]
    }
}
