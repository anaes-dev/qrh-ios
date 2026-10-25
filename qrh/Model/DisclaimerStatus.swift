//
//  DisclaimerStatus.swift
//  qrh
//
//  Whether the disclaimer needs showing: on first launch, and again after
//  every app update (as the Android app does), until it's agreed to for
//  this build.
//

import Foundation

enum DisclaimerStatus: Equatable {
    case accepted
    case firstRun
    case updated

    static let hasAcceptedKey = "hasAcceptedDisclaimer"
    static let acceptedBuildKey = "acceptedDisclaimerBuild"

    static func status(hasAccepted: Bool, acceptedBuild: Int, currentBuild: Int) -> DisclaimerStatus {
        if hasAccepted && acceptedBuild >= currentBuild {
            return .accepted
        }
        return hasAccepted ? .updated : .firstRun
    }

    static var currentBuild: Int {
        Int(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "") ?? 0
    }

    static func current(_ defaults: UserDefaults = .standard) -> DisclaimerStatus {
        status(hasAccepted: defaults.bool(forKey: hasAcceptedKey),
               acceptedBuild: defaults.integer(forKey: acceptedBuildKey),
               currentBuild: currentBuild)
    }

    static func recordAcceptance(_ defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: hasAcceptedKey)
        defaults.set(currentBuild, forKey: acceptedBuildKey)
    }
}
