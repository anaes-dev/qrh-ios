//
//  DisclaimerView.swift
//  qrh
//
//  Shown on first launch, after each app update, and from About. Agree
//  records acceptance for this build and dismisses; Disagree leaves the
//  user at a dead end, as before.
//

import SwiftUI

struct DisclaimerView: View {

    enum Mode {
        case firstRun
        case updated
//        Opened from About: no intro line
        case review
    }

    let mode: Mode

    static let licence = """
        This material is a derivative of the "Quick Reference Handbook" (www.anaesthetists.org/qrh) by The Association of Anaesthetists (www.anaesthetists.org), used under Creative Commons license CC BY-NC-SA 4.0 (www.creativecommons.org/licenses/by-nc-sa/4.0).

        Subject to Creative Commons license CC BY-NC-SA 4.0. You may distribute original version or adapt for yourself and distribute with acknowledgement of source. You may not use for commercial purposes.
        """

    static let section1 = "This application is an unofficial open-source adaptation of the Association of Anaesthetists Quick Reference Handbook (QRH); a collection of guidelines for unexpected or uncommon anaesthesia-related emergencies. As per the original accompanying guidance:"

    static let section1Quote = """
        "The QRH is not a substitute for learning and practising clinical skills. Nor is it a substitute for being familiar with more detailed guidelines and algorithms, such as those for managing cardiac arrest or difficult airway.

        It's essential that clinicians learn about these and practice their implementation elsewhere. For example, it's expected that in using the QRH guideline for managing cardiac arrest, clinicians will already have underlying knowledge of conditions causing cardiac arrest and will be competent in providing advanced life support.

        The QRH is also not intended to be used as a rule book every single time one of the guideline situations is encountered. For instance, most ordinary occasions of hypotension will have a simple cause and will respond to obvious remedies. The hypotension guideline becomes useful if the situation is out of the ordinary or becomes unremitting. Conversely, for the more immediate and uncommon problems, such as cardiac arrest in theatre, the guideline should be used from the outset to help avoid missing out useful steps in resolving the situation."
        """

    static let section1Warning = "The guidelines in this handbook are not intended to be standards of medical care. The ultimate judgement with regard to a particular clinical procedure or treatment plan must be made by the clinician in the light of the clinical data presented and the diagnostic and treatment options available."

//    Inline markdown for the bold and italic parts, as the Android app has
    static let section2 = """
        This application is intended for use only by healthcare professionals in the United Kingdom who are already familiar with the QRH. It is intended to complement and improve access to, but not replace, the original QRH. **This application has not been professionally developed nor tested. You must evaluate the application and its content, and exercise your own discretionary judgement about its appropriate use.** The developer accepts no responsibility for or liability arising from any decision to use in a clinical setting despite this warning. You should consider the advice of your employer, regulatory and professional bodies regarding the use of software applications, and always exercise professional judgement before relying on information from any source.

        This application is not presented as a medical device in the United Kingdom. **It carries no certification markings, regulatory approvals or technical assessment appraisals.** According to the latest Medicines and Healthcare products Regulatory Agency guidance *"Medical device stand-alone software including apps"* (Published 8 August 2014, last updated 1 July 2023) at the time of this release; software has no medical purpose if it only provides reference information to help a Healthcare Professional to use their knowledge to make a clinical decision, and is unlikely to be a medical device if it just reproduces a paper document in digital format, provides reference information to follow the path of a procedure/treatment, or it has decision points (options may be explained) but the healthcare professional decides which path to take. This application does not perform any automated reasoning or calculations.

        Regulations may change with time. Distribution by the developer will be ceased if advised to do so or if this application subsequently becomes subject to regulatory approval. Please periodically check whether regulations have changed, and stop using this application if you are unsure about its status. Due to the offline and open-source nature of the application, however, the developer cannot be held responsible for ongoing use and distribution of the application or its source code by other parties beyond such a time.

        For more information please see: https://www.gov.uk/government/publications/medical-devices-software-applications-apps
        """

    static let section3 = """
        This application reproduces the June 2023 version of the QRH, adapted to fit the mobile application format. Content has largely been transcribed verbatim, except for minor formatting, punctuation and structure tweaks that do not meaningfully alter the guidelines, and the introduction of TALLman Lettering to improve the readability of certain words. The developer assumes no responsibility or liability for any errors or omissions in the content. The information is provided on an "as is" basis with no guarantees of completeness, accuracy, usefulness or timeliness. Drug indications and doses may be incorrect, and do not take into account individual circumstances such as comorbidities, interactions, renal and hepatic function. Likewise, the application is provided on an "as is" basis with no guarantees of usefulness, performance or reliability. A copy of the original QRH should always be retained for reference and backup. The developer, original QRH authors, or anyone else connected in any way with the QRH or application, cannot be held responsible for your use of the information contained in or linked from this application. Links to external websites and telephone numbers are provided for convenience and informational purposes only; they do not constitute an endorsement and the developer is not responsible for any third-party content accessed through them.

        The QRH is updated from time to time. A version number is displayed next to each guideline in the list view, and in the guideline footer when opened; these correspond with the Association of Anaesthetists guideline versioning. You must check that the guidelines you are using are up to date. The developer will endeavour to keep the application updated with any new QRH revision, but there will be a delay between release from the Association of Anaesthetists and release of an application update. If any guidelines contained within the application become superseded, please revert to using the latest version from the Association of Anaesthetists. Alternatively, the source code could be obtained from github.com/anaes-dev/qrh-ios and updated by the end-user.
        """

    static let section4 = "The privacy policy for this application is available at qrh.anaes.dev/privacy. This application does not itself collect, access, use, store, transmit or sell any personal data. Basic de-identified data may be collected by the iOS operating system and/or the App Store - as governed by their respective privacy policies - unless you have opted-out of providing these; we may access these anonymised statistics to help improve future versions of the application."

    static let section5 = "If you disagree with any of the above, please click the 'Disagree' button below and uninstall the application. If you agree, please click the 'Agree' button to launch the application. This disclaimer can be accessed at any time from the About page by clicking the icon at the top-right corner of the main application screen. A small popup reminder will be displayed at each launch."

    @Environment(\.dismiss) private var dismiss
    @State private var disagreed = false

    @ScaledMetric(relativeTo: .subheadline) private var introSize: CGFloat = 14
    @ScaledMetric(relativeTo: .title3) private var agreeSize: CGFloat = 18
    @ScaledMetric(relativeTo: .body) private var barHeight: CGFloat = 50

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                AppInfoHeader(licenceText: Self.licence)

                if let intro {
                    Text(intro)
                        .font(.system(size: introSize))
                        .padding(.top, 52)
                }

                VStack(alignment: .leading, spacing: 40) {
                    section(1) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(Self.linked(Self.section1))
                            Text(Self.linked(Self.section1Quote)).italic()
                            Text(Self.section1Warning)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color(.systemRed))
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemRed).opacity(0.2))
                                .card(shadowOpacity: 0.2)
                                .padding(.top, 8)
                        }
                    }
                    section(2) { Text(Self.section2Text) }
                    section(3) { Text(Self.linked(Self.section3)) }
                    section(4) { Text(Self.linked(Self.section4)) }
                    section(5) { Text(Self.linked(Self.section5)) }
                }
                .padding(.top, mode == .review ? 52 : 24)

                HStack {
                    Button {
                        disagreed = true
                    } label: {
                        Label("Disagree", systemImage: "xmark.square")
                            .font(.callout)
                    }
                    .tint(Color(.secondaryLabel))
                    .frame(maxWidth: .infinity)

                    Button {
                        DisclaimerStatus.recordAcceptance()
                        dismiss()
                    } label: {
                        Label("Agree", systemImage: "checkmark.square")
                            .font(.system(size: agreeSize))
                    }
                    .tint(Color(.link))
                    .frame(maxWidth: .infinity)
                }
                .frame(minHeight: barHeight)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 4))
                .shadow(color: .black.opacity(0.1), radius: 2)
                .padding(.top, 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .foregroundStyle(Color(.label))
        .interactiveDismissDisabled()
        .overlay {
            if disagreed {
                DisagreedOverlay()
            }
        }
    }

//    Section 2 with its markdown applied and "not" underlined in "is not
//    presented as a medical device"

    static var section2Text: AttributedString {
        var text = (try? AttributedString(markdown: section2, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(section2)
        if let phrase = text.range(of: "is not presented as a medical device"),
           let not = text[phrase].range(of: "not") {
            text[not].swiftUI.underlineStyle = .single
        }
        LinkDetector.addLinks(to: &text, detecting: .link)
        return text
    }

//    Web links tappable, as in AppInfoHeader (the section's font applies)

    static func linked(_ string: String) -> AttributedString {
        var text = AttributedString(string)
        LinkDetector.addLinks(to: &text, detecting: .link)
        return text
    }

    private var intro: String? {
        switch mode {
        case .firstRun: "As this is your first launch, please read and consider all of the following:"
        case .updated: "Please check for any changes to the disclaimers with this update:"
        case .review: nil
        }
    }

    private func section(_ number: Int, @ViewBuilder content: () -> some View) -> some View {
        HStack(alignment: .top, spacing: 16) {
            StepBadge(step: "\(number)", spokenAs: "Section \(number)")
            content()
                .font(.caption2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
        }
    }
}


//    Terminal state after Disagree. SwiftUI alerts always have a button, so
//    this draws an alert-like panel with no way to continue.

struct DisagreedOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 8) {
                Text("Thank you for your time")
                    .font(.headline)
                Text("Please close and uninstall the app")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(maxWidth: 300, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isModal)
        .accessibilityIdentifier("DisagreedMessage")
    }
}

#if DEBUG
#Preview("Disclaimer") {
    DisclaimerView(mode: .firstRun)
}

#Preview("Disclaimer after update") {
    DisclaimerView(mode: .updated)
}

#Preview("Disclaimer dark") {
    DisclaimerView(mode: .review)
        .preferredColorScheme(.dark)
}

#Preview("Disagreed", traits: .sizeThatFitsLayout) {
    DisagreedOverlay()
        .frame(height: 300)
}
#endif

extension DisclaimerView.Mode: Identifiable {
    var id: Self { self }
}
