//
//  DisclaimerTextTests.swift
//  qrhTests
//

import Foundation
import SwiftUI
import Testing
@testable import qrh

@MainActor
struct DisclaimerTextTests {

    let text = DisclaimerView.section2Text

    func runs(with intent: InlinePresentationIntent) -> [String] {
        text.runs.filter { $0.inlinePresentationIntent?.contains(intent) == true }
            .map { String(text[$0.range].characters) }
    }

    @Test func markdownIsApplied() {
        #expect(!String(text.characters).contains("*"))
        #expect(runs(with: .stronglyEmphasized) == [
            "This application has not been professionally developed nor tested. You must evaluate the application and its content, and exercise your own discretionary judgement about its appropriate use.",
            "It carries no certification markings, regulatory approvals or technical assessment appraisals.",
        ])
        #expect(runs(with: .emphasized) == ["\"Medical device stand-alone software including apps\""])
    }

    @Test func notIsUnderlinedInMedicalDeviceSentence() {
        let underlined = text.runs.filter { $0[AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] != nil && $0.link == nil }
        #expect(underlined.map { String(text[$0.range].characters) } == ["not"])
        let phrase = text.range(of: "is not presented as a medical device")!
        let not = text[phrase].range(of: "not")!
        #expect(text[not].runs.allSatisfy { $0[AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] != nil })
    }

    @Test func paragraphsAndLinksSurvive() {
        #expect(String(text.characters).contains("\n\nThis application is not presented"))
        let links = text.runs.compactMap(\.link).map(\.absoluteString)
        #expect(links.contains("https://www.gov.uk/government/publications/medical-devices-software-applications-apps"))
        #expect(DisclaimerView.linked(DisclaimerView.section3).runs.contains { $0.link?.absoluteString.contains("github.com/anaes-dev/qrh-ios") == true })
    }
}
