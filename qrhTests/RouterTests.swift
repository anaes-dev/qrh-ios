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
        for index in 0..<20 {
            #expect(router.push(index.isMultiple(of: 2) ? "1-1" : "1-2"))
        }
        #expect(!router.showDepthAlert)
        #expect(!router.push("2-1"))
        #expect(router.showDepthAlert)
        #expect(router.path.count == Router.maxDepth)
        #expect(router.path.last == "1-2")
    }

//    A double tap on a row or link
    @Test func guidelineOnTopIsNotPushedAgain() {
        let router = Router()
        #expect(router.push("2-5"))
        #expect(!router.push("2-5"))
        #expect(router.path == ["2-5"])
        #expect(!router.showDepthAlert)
//        Further down the stack is fine: 2-5 → 1-1 → 2-5
        #expect(router.push("1-1"))
        #expect(router.push("2-5"))
        #expect(router.path == ["2-5", "1-1", "2-5"])
    }

//    "Go back to START of key basic plan →1-1", in 1-1
    @Test func linkToGuidelineOnTopGoesToItsStart() {
        let router = Router()
        router.push("1-1")
        router.follow("1-1")
        #expect(router.path == ["1-1"])
        #expect(router.startRequest == 1)
        router.follow("2-1")
        #expect(router.path == ["1-1", "2-1"])
        #expect(router.startRequest == 1)
    }
}
