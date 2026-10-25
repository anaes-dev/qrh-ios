//
//  StoreScreenshots.swift
//  qrhUITests
//
//  App Store screenshots. Only runs when asked. Each screen is set up, then
//  "<name>.ready" is written to the given folder and the test waits for
//  "<name>.png": the simulator's own screenshot, taken from the Mac (XCTest's
//  are wrongly rotated on an iPad in landscape). tools/store-screenshots.sh
//  runs it for a device, in light then dark mode.
//

import XCTest

final class StoreScreenshots: XCTestCase {

    var app: XCUIApplication!
    var folder: URL!
    var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    override func setUpWithError() throws {
        let environment = ProcessInfo.processInfo.environment
        guard let path = environment["QRH_STORE_DIR"] else {
            throw XCTSkip("No screenshot folder given")
        }
        folder = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        continueAfterFailure = false
        XCUIDevice.shared.orientation = isPad ? .landscapeLeft : .portrait
        app = XCUIApplication()
    }

    override func tearDown() {
        app?.terminate()
    }

//    Runs only in the appearance being taken

    func only(_ appearance: String) throws {
        let current = ProcessInfo.processInfo.environment["QRH_STORE_APPEARANCE"]
        try XCTSkipIf(current != appearance, "Taken in \(appearance) mode")
    }

    func launch(path: String? = nil, boxesOpen: Bool = true) {
        app.launchArguments = ["-hasAcceptedDisclaimer", "YES", "-acceptedDisclaimerBuild", "999999",
                               "-expandingDisabled", boxesOpen ? "YES" : "NO",
                               "-uiTestAppearance", ProcessInfo.processInfo.environment["QRH_STORE_APPEARANCE"] ?? ""]
        if let path {
            app.launchArguments += ["-uiTestPath", path]
        }
        app.launch()
//        The launch reminder fades after 5 s
        sleep(7)
    }

    func save(_ name: String) throws {
        let base = "\(isPad ? "iPad" : "iPhone")-\(name)"
        let png = folder.appendingPathComponent("\(base).png")
        try? FileManager.default.removeItem(at: png)
        try Data().write(to: folder.appendingPathComponent("\(base).ready"))
        var waited = 0
        while waited < 60 && !FileManager.default.fileExists(atPath: png.path) {
            sleep(1)
            waited += 1
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: png.path), "No screenshot taken")
    }

//    Drags the element up to just below the bar, slowly so it stays there

    func bringToTop(_ element: XCUIElement, margin: CGFloat = 0.13) {
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        let window = app.windows.firstMatch
        for _ in 0..<6 where element.frame.minY > window.frame.height * 0.85 {
            app.swipeUp()
        }
        let from = element.frame.minY / window.frame.height
        guard from > margin + 0.02 else { return }
        let x = element.frame.midX / window.frame.width
        window.coordinate(withNormalizedOffset: CGVector(dx: x, dy: from))
            .press(forDuration: 0.1,
                   thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: x, dy: margin)),
                   withVelocity: .slow, thenHoldForDuration: 0.5)
        sleep(1)
    }

    func label(_ text: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", text)).firstMatch
    }


//    1. The guideline list (iPad: beside Key basic plan)

    func test1List() throws {
        try only("light")
        launch(path: isPad ? "1-1" : nil)
        try save("1-list")
    }

//    2. Full-text search with highlighted matches

    func test2Search() throws {
        try only("light")
        launch(path: isPad ? "3-10" : nil)
        let search = app.searchFields["Search guidelines"]
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap()
        search.typeText("adrenaline\n")
        sleep(2)
        try save("2-search")
    }

//    3. Bradycardia in dark mode: on iPhone, Box A collapsed and Box B
//    opened, to show the expanding boxes (iPad's are always open)

    func test3Bradycardia() throws {
        try only("dark")
        launch(path: "2-6", boxesOpen: isPad)
        if !isPad {
            let box = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Box B: DRUGS FOR BRADYCARDIA'")).firstMatch
            XCTAssertTrue(box.waitForExistence(timeout: 10))
            box.tap()
            sleep(1)
        }
        try save("3-bradycardia")
    }

//    4. A fork: 3-10's two branches, each with its condition

    func test4Branches() throws {
        try only("light")
//        iPhone: boxes collapsed, so both branches fit
        launch(path: "3-10", boxesOpen: isPad)
        bringToTop(label("If circulatory arrest:"), margin: 0.25)
        try save("4-branches")
    }

//    5. Sepsis, in dark mode

    func test5Sepsis() throws {
        try only("dark")
        launch(path: "3-14")
        try save("5-sepsis")
    }

//    6. The large card view

    func test6Cards() throws {
        try only("light")
        launch(path: "2-6")
        app.buttons["Full screen cards"].firstMatch.tap()
        let first = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Card 1 of '")).firstMatch
        XCTAssertTrue(first.waitForExistence(timeout: 10))
        app.swipeLeft()
        sleep(2)
        try save("6-cards")
    }
}
