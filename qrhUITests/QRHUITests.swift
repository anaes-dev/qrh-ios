//
//  QRHUITests.swift
//  qrhUITests
//
//  End-to-end flows: disclaimer, reminder, search, links and breadcrumbs, PDF, About.
//

import XCTest

final class QRHUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() {
        app.terminate()
    }


//    Helpers

//    accepted: nil leaves the stored value alone; true/false overrides it for
//    this launch only (argument domain)
    func launch(accepted: Bool? = true, reset: Bool = false) {
        var arguments = [String]()
        if reset { arguments.append("-resetDisclaimer") }
        if let accepted {
//            A build far ahead of the app's, so the update disclaimer doesn't show
            arguments += ["-hasAcceptedDisclaimer", accepted ? "YES" : "NO", "-acceptedDisclaimerBuild", "999999"]
        }
        app.launchArguments = arguments
        app.launch()
    }

    var list: XCUIElement { app.navigationBars["QRH"] }

    var reminder: XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Not endorsed by the Association of Anaesthetists'")).firstMatch
    }

    func row(_ title: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", title)).firstMatch
    }

    func open(_ title: String) {
        let row = row(title)
        for _ in 0..<10 where !row.isHittable {
            app.swipeUp()
        }
        row.tap()
        XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 20), "\(title) didn't open")
    }

    func link(_ code: String) -> XCUIElement {
        app.links.matching(NSPredicate(format: "label CONTAINS %@", "→" + code)).firstMatch
    }

    func scrollTo(_ element: XCUIElement) {
        for _ in 0..<10 where !(element.exists && element.isHittable) {
            app.swipeUp()
        }
    }


//    Disclaimer

    func testFirstLaunchDisclaimerCannotBeDismissedAndDisagreeIsTerminal() {
        launch(accepted: false)
        let agree = app.buttons["Agree"]
        XCTAssertTrue(agree.waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["As this is your first launch, please read and consider all of the following:"].exists)

        app.swipeDown(velocity: .fast)
        XCTAssertTrue(agree.waitForExistence(timeout: 2), "Disclaimer was swiped away")

        let disagree = app.buttons["Disagree"]
        scrollTo(disagree)
        disagree.tap()
        XCTAssertTrue(app.staticTexts["Thank you for your time"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Please close and uninstall the app"].exists)
        XCTAssertFalse(agree.isHittable, "Can still continue after Disagree")
    }

//    Agreed for an older build: the disclaimer shows again with the update line
    func testUpdateShowsDisclaimerAgain() {
        app.launchArguments = ["-hasAcceptedDisclaimer", "YES", "-acceptedDisclaimerBuild", "0"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Please check for any changes to the disclaimers with this update:"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.staticTexts["As this is your first launch, please read and consider all of the following:"].exists)
        let agree = app.buttons["Agree"]
        scrollTo(agree)
        XCTAssertTrue(agree.isHittable)
        agree.tap()
        XCTAssertTrue(list.waitForExistence(timeout: 5))
    }

    func testAgreeThenRelaunchShowsReminderNotDisclaimer() {
        launch(accepted: nil, reset: true)
        let agree = app.buttons["Agree"]
        XCTAssertTrue(agree.waitForExistence(timeout: 15))
        scrollTo(agree)
        agree.tap()
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Agree"].waitForExistence(timeout: 2))
        app.terminate()

        launch(accepted: nil)
        XCTAssertTrue(list.waitForExistence(timeout: 15))
        XCTAssertTrue(reminder.waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Agree"].exists)

//        Auto-hides after 5 s
        let gone = NSPredicate(format: "exists == false")
        expectation(for: gone, evaluatedWith: reminder)
        waitForExpectations(timeout: 10)
    }


//    List and search

    func testSearchFiltersByTitle() {
        launch()
        XCTAssertTrue(list.waitForExistence(timeout: 15))
        let search = app.searchFields["Search guidelines"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("hypo")
        XCTAssertTrue(row("Hypotension").waitForExistence(timeout: 5))
        XCTAssertTrue(row("Hypoxia").exists)
        XCTAssertFalse(app.staticTexts["No Results"].exists)

        search.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 4) + "zzz")
        XCTAssertTrue(app.staticTexts["No Results"].waitForExistence(timeout: 5))
    }

    func testSearchByCode() {
        launch()
        XCTAssertTrue(list.waitForExistence(timeout: 15))
        let search = app.searchFields["Search guidelines"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("3-8")
        XCTAssertTrue(row("Malignant hyperthermia crisis").waitForExistence(timeout: 5))
        XCTAssertFalse(row("Hypertension").exists)
    }

    func testSearchInsideGuidelineOpensAtMatch() {
        launch()
        XCTAssertTrue(list.waitForExistence(timeout: 15))
        let search = app.searchFields["Search guidelines"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("leeds")
        let result = row("Malignant hyperthermia crisis")
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        result.tap()
        XCTAssertTrue(app.navigationBars["Malignant hyperthermia crisis"].waitForExistence(timeout: 10))
        let text = app.textViews.matching(NSPredicate(format: "value CONTAINS[c] 'Leeds'")).firstMatch
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        XCTAssertTrue(text.isHittable, "Didn't scroll to the match")
    }


//    Guideline detail

    func testCalloutLinkBreadcrumbAndHome() {
        launch()
        XCTAssertTrue(list.waitForExistence(timeout: 15))
        open("Hypertension")

        let link = link("1-1")
        if UIDevice.current.userInterfaceIdiom == .phone {
//            Callouts start collapsed on iPhone
            let box = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Box A: CRITICAL CHANGES'")).firstMatch
            XCTAssertTrue(box.waitForExistence(timeout: 5))
            XCTAssertFalse(link.exists)
            box.tap()
            XCTAssertTrue(link.waitForExistence(timeout: 5))
            box.tap()
            XCTAssertTrue(link.waitForNonExistence(timeout: 5))
            box.tap()
        }
        XCTAssertTrue(link.waitForExistence(timeout: 5))
        link.tap()
        XCTAssertTrue(app.navigationBars["Key basic plan"].waitForExistence(timeout: 10))

        let home = app.buttons["Breadcrumb-Home"]
        XCTAssertTrue(home.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Breadcrumb-0"].exists)
        XCTAssertTrue(app.buttons["Breadcrumb-1"].exists)
        home.tap()
        XCTAssertTrue(list.waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars["Hypertension"].exists)
    }

    func testCardDeckSwipesAndLinksOpenInNormalView() {
        launch()
        XCTAssertTrue(list.waitForExistence(timeout: 15))
        open("Hypertension")
        app.navigationBars["Hypertension"].buttons["Full screen cards"].tap()

        let first = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Card 1 of '")).firstMatch
        XCTAssertTrue(first.waitForExistence(timeout: 10))
        app.swipeLeft()
        let second = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Card 2 of '")).firstMatch
        XCTAssertTrue(second.waitForExistence(timeout: 5))

//        Box A's link opens Key basic plan in the normal view; back returns
//        to Hypertension's normal view, not the deck
        let link = link("1-1")
        XCTAssertTrue(link.waitForExistence(timeout: 5))
        link.tap()
        let keyBasicPlan = app.navigationBars["Key basic plan"]
        XCTAssertTrue(keyBasicPlan.waitForExistence(timeout: 10))
        keyBasicPlan.buttons["Hypertension"].tap()
        XCTAssertTrue(app.navigationBars["Hypertension"].waitForExistence(timeout: 5))
        XCTAssertFalse(second.exists)
    }

    func testPDFSheetOpensAndCloses() {
        launch()
        XCTAssertTrue(list.waitForExistence(timeout: 15))
        open("Hypertension")
        app.navigationBars["Hypertension"].buttons["PDF"].tap()
        let sheet = app.navigationBars["Original PDF"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 10))
        sheet.buttons["Close"].tap()
        XCTAssertTrue(sheet.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["Hypertension"].exists)
    }

    func testTooManyGuidelinesAlert() {
//        Start 19 deep (3-8 and 2-8 link to each other), follow one link to
//        reach the limit of 20, then one more
        let path = (0..<19).map { $0.isMultiple(of: 2) ? "3-8" : "2-8" }
        app.launchArguments = ["-hasAcceptedDisclaimer", "YES", "-acceptedDisclaimerBuild", "999999",
                               "-uiTestPath", path.joined(separator: ",")]
        app.launch()
        XCTAssertTrue(app.navigationBars["Malignant hyperthermia crisis"].waitForExistence(timeout: 20))

        let first = link("2-8")
        scrollTo(first)
        first.tap()
        XCTAssertTrue(app.navigationBars["Peri-operative hyperthermia"].waitForExistence(timeout: 10))

        let link = link("3-8")
        scrollTo(link)
        link.tap()
        let alert = app.alerts["Too many guidelines open"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(alert.staticTexts["Please do not try to open more than 20 guidelines at once"].exists)
        alert.buttons["Close"].tap()
        XCTAssertTrue(app.navigationBars["Peri-operative hyperthermia"].exists)
    }


//    About

    func testAboutDisclaimersAgreeReturnsToAbout() {
        launch()
        XCTAssertTrue(list.waitForExistence(timeout: 15))
        app.navigationBars["QRH"].buttons["About"].tap()
        let about = app.navigationBars["About"]
        XCTAssertTrue(about.waitForExistence(timeout: 5))
        app.buttons["Disclaimers"].tap()
        let agree = app.buttons["Agree"]
        XCTAssertTrue(agree.waitForExistence(timeout: 5))
        scrollTo(agree)
        agree.tap()
        XCTAssertTrue(agree.waitForNonExistence(timeout: 5))
        XCTAssertTrue(about.exists)
        about.buttons["Close"].tap()
        XCTAssertTrue(list.waitForExistence(timeout: 5))
    }
}
