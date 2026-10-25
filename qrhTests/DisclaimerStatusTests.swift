//
//  DisclaimerStatusTests.swift
//  qrhTests
//

import Testing
@testable import qrh

struct DisclaimerStatusTests {

    @Test func firstRunWhenNeverAccepted() {
        #expect(DisclaimerStatus.status(hasAccepted: false, acceptedBuild: 0, currentBuild: 13) == .firstRun)
        #expect(DisclaimerStatus.status(hasAccepted: false, acceptedBuild: 13, currentBuild: 13) == .firstRun)
    }

    @Test func acceptedForThisBuild() {
        #expect(DisclaimerStatus.status(hasAccepted: true, acceptedBuild: 13, currentBuild: 13) == .accepted)
    }

//    Includes upgrades from 2.16, which stored no build
    @Test func updatedWhenAcceptedForAnOlderBuild() {
        #expect(DisclaimerStatus.status(hasAccepted: true, acceptedBuild: 12, currentBuild: 13) == .updated)
        #expect(DisclaimerStatus.status(hasAccepted: true, acceptedBuild: 0, currentBuild: 13) == .updated)
    }

//    e.g. after a downgrade, or the UI tests' -acceptedDisclaimerBuild 999999
    @Test func acceptedWhenSavedBuildIsNewer() {
        #expect(DisclaimerStatus.status(hasAccepted: true, acceptedBuild: 999999, currentBuild: 13) == .accepted)
    }
}
