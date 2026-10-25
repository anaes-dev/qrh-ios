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
    func launch(accepted: Bool? = true, reset: Bool = false, expandingDisabled: Bool = false) {
        var arguments = [String]()
        if reset { arguments.append("-resetDisclaimer") }
        if let accepted {
//            A build far ahead of the app's, so the update disclaimer doesn't show
            arguments += ["-hasAcceptedDisclaimer", accepted ? "YES" : "NO", "-acceptedDisclaimerBuild", "999999"]
        }
//        Boxes collapse on iPhone unless a test says otherwise
        arguments += ["-expandingDisabled", expandingDisabled ? "YES" : "NO"]
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

//    The list is the only collection view (on iPad, the sidebar's)
    func open(_ title: String) {
        let row = row(title)
        scrollTo(row, in: app.collectionViews.firstMatch)
        row.tap()
        XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 20), "\(title) didn't open")
    }

//    A guideline's row in the list (its label starts with the code), not a
//    breadcrumb with the same title
    func sidebarRow(_ code: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", code + ", ")).firstMatch
    }

    func link(_ code: String) -> XCUIElement {
        app.links.matching(NSPredicate(format: "label CONTAINS %@", "→" + code)).firstMatch
    }

//    Swipes up until the element is on screen, at most 10 times. (Not a
//    for-where loop: that goes on checking after the element is found, and
//    each check is a slow snapshot of the screen.)
    func scrollTo(_ element: XCUIElement, in container: XCUIElement? = nil) {
        var swipes = 0
        while swipes < 10 && !(element.exists && element.isHittable) {
            (container ?? app).swipeUp()
            swipes += 1
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

//    A match in the second branch of a fork scrolls to that branch's
//    condition, not the top of the fork
    func testSearchOpensAtMatchInBranch() {
        launch()
        XCTAssertTrue(list.waitForExistence(timeout: 15))
        let search = app.searchFields["Search guidelines"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("no circulatory arrest")
//        Other guidelines mention these words too, so the result can be below
//        the keyboard
        XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 10))
        let result = row("Local anaesthetic toxicity")
        scrollTo(result)
        result.tap()
        XCTAssertTrue(app.navigationBars["Local anaesthetic toxicity"].waitForExistence(timeout: 10))
        let condition = app.descendants(matching: .any).matching(NSPredicate(format: "label == 'If no circulatory arrest:'")).firstMatch
        XCTAssertTrue(condition.waitForExistence(timeout: 5))
        XCTAssertTrue(condition.isHittable, "Didn't scroll to the branch")
    }

//    Rotating keeps the place in a guideline rather than going back to the
//    top. iPhone only: the place is kept to the card at the top, and on an
//    iPad even 2-1 only just overflows the screen in portrait, so its top
//    card is still step 1, with START above it.
    func testRotationKeepsPlace() throws {
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom == .pad, "Pages barely scroll on iPad")
        launch()
        XCTAssertTrue(list.waitForExistence(timeout: 15))
        open("Cardiac arrest")
        let start = app.descendants(matching: .any).matching(NSPredicate(format: "label == 'START'")).firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        var swipes = 0
        while swipes < 5 && start.isHittable {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertFalse(start.isHittable, "Didn't scroll down")
//        Well clear of it: rotating changes the bar's height and the text's
//        wrapping, which could bring back a START only just out of view
        app.swipeUp()
        app.swipeUp()

        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        XCTAssertTrue(app.navigationBars["Cardiac arrest"].waitForExistence(timeout: 5))
        XCTAssertFalse(start.isHittable, "Went back to the top on rotating")
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.navigationBars["Cardiac arrest"].waitForExistence(timeout: 5))
        XCTAssertFalse(start.isHittable, "Went back to the top on rotating back")
    }

//    Back from a result keeps the search; then one tap clears it, closes the keyboard and shows the whole list
//    from the top
    func testLeavingSearchTakesOneStep() {
//        iPad: landscape, so the sidebar stays beside the open guideline
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .landscapeLeft
        }
        launch()
        XCTAssertTrue(list.waitForExistence(timeout: 15))
        let search = app.searchFields["Search guidelines"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
//        A query restored from an earlier run
        let clear = search.buttons["Clear text"]
        if clear.exists {
            clear.tap()
            search.tap()
        }
//        Matches most of the handbook, so the results scroll
        search.typeText("oxygen")
        let result = row("Mains oxygen failure")
        XCTAssertTrue(result.waitForExistence(timeout: 10))
        result.tap()
        let guideline = app.navigationBars["Mains oxygen failure"]
        XCTAssertTrue(guideline.waitForExistence(timeout: 10))

        if UIDevice.current.userInterfaceIdiom == .phone {
            guideline.buttons.element(boundBy: 0).tap()
            XCTAssertTrue(list.waitForExistence(timeout: 5))
        }
        XCTAssertEqual(search.value as? String, "oxygen")
        XCTAssertTrue(result.exists, "Results weren't kept")

//        Scrolled down the results, so the full list must scroll back up
        let top = row("Instructions for use")
        let results = app.collectionViews.firstMatch
        results.swipeUp()
        results.swipeUp()
        XCTAssertFalse(result.isHittable, "Results didn't scroll")

//        iPhone: the bar's Close (Cancel before iOS 26). iPad: the sidebar has
//        none, and the field's clear button leaves the search. (Escape on an
//        iPad keyboard does the same, but the simulator types it into the
//        field without a hardware keyboard, so it's checked by hand.)
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCTAssertEqual(app.keyboards.count, 0, "Keyboard covers the guideline")
            search.buttons["Clear text"].tap()
        } else {
            let cancel = list.buttons.matching(NSPredicate(format: "label IN {'Close', 'Cancel'}")).firstMatch
            XCTAssertTrue(cancel.waitForExistence(timeout: 5), "Search wasn't still active")
            cancel.tap()
        }
        XCTAssertTrue(top.waitForExistence(timeout: 5))
        XCTAssertTrue(top.isHittable, "List isn't at the top")
        XCTAssertTrue(row("Hypertension").exists)
        XCTAssertEqual(app.keyboards.count, 0, "Keyboard still open")
        XCTAssertNotEqual(search.value as? String, "oxygen")
//        iPad: the open guideline stays open
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCTAssertTrue(guideline.exists)
        }
    }

//    iPad: the sidebar highlights the guideline on screen as links and
//    breadcrumbs change it
    func testSidebarFollowsLinksAndBreadcrumbs() throws {
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom != .pad, "No sidebar on iPhone")
        XCUIDevice.shared.orientation = .landscapeLeft
        launch()
        XCTAssertTrue(list.waitForExistence(timeout: 15))
        open("Hypertension")
        XCTAssertTrue(sidebarRow("2-5").isSelected)

        let link = link("1-1")
        XCTAssertTrue(link.waitForExistence(timeout: 5))
        link.tap()
        XCTAssertTrue(app.navigationBars["Key basic plan"].waitForExistence(timeout: 10))
        XCTAssertTrue(sidebarRow("1-1").isSelected)
        XCTAssertFalse(sidebarRow("2-5").isSelected)

        app.buttons["Breadcrumb-0"].tap()
        XCTAssertTrue(app.navigationBars["Hypertension"].waitForExistence(timeout: 5))
        XCTAssertTrue(sidebarRow("2-5").isSelected)
        XCTAssertFalse(sidebarRow("1-1").isSelected)
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

//    "Go back to START of key basic plan →1-1", in 1-1: back to the top of
//    the page, not a second copy of it. (Box A sits just above START, so
//    the scroll itself is small.)
    func testLinkToSameGuidelineGoesToItsStart() {
        launch(expandingDisabled: true)
        XCTAssertTrue(list.waitForExistence(timeout: 15))
        open("Key basic plan")
        let link = link("1-1")
        scrollTo(link)
        link.tap()
        let start = app.descendants(matching: .any).matching(NSPredicate(format: "label == 'START'")).firstMatch
        wait(for: [expectation(for: NSPredicate(format: "isHittable == true"), evaluatedWith: start)], timeout: 5)
        XCTAssertTrue(app.navigationBars["Key basic plan"].exists)
//        Still one guideline deep: the breadcrumb only shows from two
        XCTAssertFalse(app.buttons["Breadcrumb-Home"].exists)
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
//        to Hypertension's normal view, not the deck. (On iPad Box A is also
//        open in the guideline behind the deck.)
        let link = app.otherElements["CardDeck"].links.matching(NSPredicate(format: "label CONTAINS '→1-1'")).firstMatch
        XCTAssertTrue(link.waitForExistence(timeout: 5))
        link.tap()
        let keyBasicPlan = app.navigationBars["Key basic plan"]
        XCTAssertTrue(keyBasicPlan.waitForExistence(timeout: 10))
//        iPad has no back button beside the sidebar and breadcrumb
        if UIDevice.current.userInterfaceIdiom == .pad {
            app.buttons["Breadcrumb-0"].tap()
        } else {
            keyBasicPlan.buttons["Hypertension"].tap()
        }
        XCTAssertTrue(app.navigationBars["Hypertension"].waitForExistence(timeout: 5))
        XCTAssertFalse(second.exists)
    }

//    As on Android, 0-3's first box (orange) starts open; the rest don't
    func testInstructionsOpenWithFirstBoxExpanded() throws {
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom == .pad, "Boxes are always open on iPad")
        launch()
        XCTAssertTrue(list.waitForExistence(timeout: 15))
        open("Instructions for use")
        let orange = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Orange = critical changes'")).firstMatch
        let blue = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Blue = drug doses'")).firstMatch
        scrollTo(blue)
        XCTAssertEqual(orange.value as? String, "Expanded")
        XCTAssertEqual(blue.value as? String, "Collapsed")
    }

//    The About setting opens every box (set by launch argument here, so it
//    doesn't persist into other tests)
    func testExpandingDisabledOpensEveryBox() {
        launch(expandingDisabled: true)
        XCTAssertTrue(list.waitForExistence(timeout: 15))
        app.buttons["About"].tap()
        let toggle = app.switches["Disable expanding boxes"]
        scrollTo(toggle)
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        XCTAssertEqual(toggle.value as? String, "1")
        app.buttons["Close"].firstMatch.tap()

        open("Hypertension")
//        Box A's link shows without tapping the box
        XCTAssertTrue(link("1-1").waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Box A: CRITICAL CHANGES'")).firstMatch.exists)
    }

//    Steps in a branch say which, after their number
    func testBranchesReadTheirConditions() {
        app.launchArguments = ["-hasAcceptedDisclaimer", "YES", "-acceptedDisclaimerBuild", "999999",
                               "-uiTestPath", "3-10"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Local anaesthetic toxicity"].waitForExistence(timeout: 20))
        let any = app.descendants(matching: .any)
        for condition in ["If circulatory arrest:", "If no circulatory arrest:"] {
            let heading = any.matching(NSPredicate(format: "label == %@", condition)).firstMatch
            scrollTo(heading)
            XCTAssertTrue(heading.exists, condition)
        }
        for step in ["Step 6, if circulatory arrest", "Step 6, if no circulatory arrest"] {
            let badge = any.matching(NSPredicate(format: "label == %@", step)).firstMatch
            scrollTo(badge)
            XCTAssertTrue(badge.exists, step)
        }
//        Steps outside the fork are read as before
        let seven = any.matching(NSPredicate(format: "label == 'Step 7'")).firstMatch
        scrollTo(seven)
        XCTAssertTrue(seven.exists)
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
