//
//  AppInfoHeader.swift
//  qrh
//
//  Logo, title, version, intro and licence block shared by About and the
//  Disclaimer.
//

import SwiftUI
import UIKit

struct AppInfoHeader: View {
    let licenceText: String

    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var typeSize

    @ScaledMetric(relativeTo: .largeTitle) private var logoSize: CGFloat = 48
    @ScaledMetric(relativeTo: .subheadline) private var introSize: CGFloat = 14
    @ScaledMetric(relativeTo: .caption2) private var licenceSize: CGFloat = 9
    @ScaledMetric(relativeTo: .caption2) private var ccHeight: CGFloat = 34
    @ScaledMetric(relativeTo: .subheadline) private var platformWidth: CGFloat = 37
    @ScaledMetric(relativeTo: .subheadline) private var versionWidth: CGFloat = 127

    static let ccLicenceURL = URL(string: "https://creativecommons.org/licenses/by-nc-sa/4.0/")!
    static let intro = "Unofficial open-source adaptation of the Association of Anaesthetists Quick Reference Handbook (QRH) June 2023 version. www.anaesthetists.org/qrh"

    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(uiImage: UIImage(named: "logo.png") ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: min(logoSize, 72), height: min(logoSize, 72))
                    .accessibilityHidden(true)
                Text("Quick Reference Handbook")
                    .font(.largeTitle)
                    .lineLimit(typeSize.isAccessibilitySize ? nil : 1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.leading, -6)

//            One row, or stacked at large text sizes
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 0) {
                    Text("iOS")
                        .frame(width: platformWidth, alignment: .leading)
                    Text("Version \(Self.version)")
                        .frame(width: versionWidth, alignment: .leading)
                    Text("Updated October 2026")
                }
                .fixedSize()
                VStack(alignment: .leading) {
                    Text("iOS")
                    Text("Version \(Self.version)")
                    Text("Updated October 2026")
                }
            }
            .font(.subheadline)
            .foregroundStyle(Color(.systemGray))
            .padding(.top, 8)

            Text(Self.linked("github.com/anaes-dev/qrh-ios", font: .body))
                .padding(.leading, 5)
                .padding(.top, 14)

            Text(Self.linked(Self.intro, font: .system(size: introSize)))
                .padding(.horizontal, 5)
                .padding(.top, 52)

            Button {
                openURL(Self.ccLicenceURL)
            } label: {
                Image(uiImage: UIImage(named: "by_nc_sa.png") ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: ccHeight)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Creative Commons licence BY-NC-SA 4.0")
            .padding(.leading, 5)
            .padding(.top, 44)

            Text(Self.linked(licenceText, font: .system(size: licenceSize)))
                .padding(.horizontal, 5)
                .padding(.top, 12)
        }
        .foregroundStyle(Color(.label))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

//    Text with web links detected, as the storyboard text views did

    static func linked(_ string: String, font: Font) -> AttributedString {
        var text = AttributedString(string)
        text.swiftUI.font = font
        LinkDetector.addLinks(to: &text, detecting: .link)
        return text
    }
}
