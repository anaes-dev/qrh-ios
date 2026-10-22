//
//  RouterTests.swift
//  qrhTests
//

import Testing
@testable import qrh

@MainActor
struct RouterTests {

    @Test func pushAndPop() {
        let router = Router()
        #expect(router.push("2-5"))
        #expect(router.push("1-1"))
        #expect(router.push("3-6"))
        #expect(router.path == ["2-5", "1-1", "3-6"])

        router.popTo(0)
        #expect(router.path == ["2-5"])

        router.popToRoot()
        #expect(router.path.isEmpty)
    }

    @Test func popToCurrentOrInvalidIndexDoesNothing() {
        let router = Router()
        router.push("2-5")
        router.push("1-1")
        router.popTo(1)
        #expect(router.path == ["2-5", "1-1"])
        router.popTo(5)
        router.popTo(-1)
        #expect(router.path == ["2-5", "1-1"])
    }

    @Test func atMostTwentyGuidelinesOpen() {
        let router = Router()
        for _ in 0..<20 {
            #expect(router.push("1-1"))
        }
        #expect(!router.showDepthAlert)
        #expect(!router.push("2-1"))
        #expect(router.showDepthAlert)
        #expect(router.path.count == Router.maxDepth)
        #expect(router.path.last == "1-1")
    }
}
