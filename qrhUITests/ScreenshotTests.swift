//
//  ScreenshotTests.swift
//  qrhUITests
//
//  Screens for checking by eye: branch rails (3-7, 3-10) and 4-1's oxygen
//  table, in the normal view and card view. Only runs when asked, saving
//  PNGs to the given folder; set the simulator's appearance first for dark
//  mode:
//
//    TEST_RUNNER_QRH_SCREENSHOT_DIR=/path/to/folder \
//    TEST_RUNNER_QRH_SCREENSHOT_TEXT_SIZE=UICTContentSizeCategoryAccessibilityXXXL \
//    xcodebuild test -project qrh.xcodeproj -scheme qrh \
//      -destination 'platform=iOS Simulator,name=iPhone 17' \
//      -only-testing:qrhUITests/ScreenshotTests
//

import XCTest

final class ScreenshotTests: XCTestCase {

    var app: XCUIApplication!
    var folder: URL!
    var suffix = ""

    override func setUpWithError() throws {
        let environment = ProcessInfo.processInfo.environment
        guard let path = environment["QRH_SCREENSHOT_DIR"] else {
            throw XCTSkip("No screenshot folder given")
        }
        folder = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        continueAfterFailure = true
        app = XCUIApplication()
        var arguments = ["-hasAcceptedDisclaimer", "YES", "-acceptedDisclaimerBuild", "999999",
                         "-expandingDisabled", "NO"]
        if let size = environment["QRH_SCREENSHOT_TEXT_SIZE"] {
            arguments += ["-UIPreferredContentSizeCategoryName", size]
            suffix += "-" + size.replacingOccurrences(of: "UICTContentSizeCategory", with: "")
        }
        suffix += environment["QRH_SCREENSHOT_SUFFIX"].map { "-" + $0 } ?? ""
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .landscapeLeft
        }
        app.launchArguments = arguments
    }

//    app is nil if setUp stopped early (no screenshot folder given)
    override func tearDown() {
        app?.terminate()
    }

    func save(_ name: String) throws {
        let device = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        let url = folder.appendingPathComponent("\(device)-\(name)\(suffix).png")
        try app.screenshot().pngRepresentation.write(to: url)
    }

    func open(_ code: String, title: String) {
        app.launchArguments += ["-uiTestPath", code]
        app.launch()
        XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 20))
    }

//    Swipes up until the element is on screen, at most 12 times
    func show(_ element: XCUIElement, velocity: XCUIGestureVelocity = .default) {
        var swipes = 0
        while swipes < 12 && !(element.exists && element.isHittable) {
            app.swipeUp(velocity: velocity)
            swipes += 1
        }
    }

    func testRails() throws {
        for (code, title, condition) in [("3-7", "Patient fire", "If AIRWAY fire:"),
                                         ("3-10", "Local anaesthetic toxicity", "If circulatory arrest:")] {
            open(code, title: title)
            let heading = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", condition)).firstMatch
//            Small steps, so the fork's first heading stops near the top
            show(heading, velocity: .slow)
            try save("rails-\(code)")
            app.terminate()
            app.launchArguments.removeLast(2)
        }
    }

    func testOxygenTable() throws {
        open("4-1", title: "Mains oxygen failure")
        let box = app.buttons.matching(NSPredicate(format: "label CONTAINS 'OXYGEN CYLINDER'")).firstMatch
        let row = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Size C:'")).firstMatch
        if UIDevice.current.userInterfaceIdiom == .phone {
            show(box)
            box.tap()
        }
        show(row)
        XCTAssertTrue(row.exists)
        XCTAssertEqual(row.label, "Size C: 25% full (34 bar), 43 litres; 50% full (69 bar), 85 litres; 100% full (137 bar), 170 litres")
        try save("table")

//        Card view, at the box's card
        app.navigationBars["Mains oxygen failure"].buttons["Full screen cards"].tap()
//        Box B is the seventh card (after the intro, steps 1-4 and Box A)
        let page = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Card 7 of '")).firstMatch
        var swipes = 0
        while swipes < 10 && !page.exists {
            app.swipeLeft()
            _ = page.waitForExistence(timeout: 4)
            swipes += 1
        }
        XCTAssertTrue(page.exists)
        sleep(1)
        try save("table-cards")
    }

    func testSearchHighlightsCells() throws {
        app.launch()
        let search = app.searchFields["Search guidelines"]
        XCTAssertTrue(search.waitForExistence(timeout: 15))
        for query in ["cylinder", "1360"] {
            search.tap()
            search.typeText(query)
            let result = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Mains oxygen failure'")).firstMatch
            XCTAssertTrue(result.waitForExistence(timeout: 10))
            try save("search-\(query)")
            result.tap()
            XCTAssertTrue(app.navigationBars["Mains oxygen failure"].waitForExistence(timeout: 10))
            sleep(1)
            try save("search-\(query)-guideline")
            if UIDevice.current.userInterfaceIdiom == .phone {
                app.navigationBars["Mains oxygen failure"].buttons.element(boundBy: 0).tap()
            }
            search.tap()
            search.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: query.count))
        }
    }
}
