import XCTest

/// Screenshot gate for Issue #1 (7/7 visual acceptance).
/// Captures the five main pages in light, dark and extra-large text.
/// The simulator has no HealthKit data, so every page shows its honest
/// empty state ("—" / "暂无记录"); no sample data is ever manufactured.
/// Screenshots are XCTAttachments (lifetime .keepAlways) so they land in
/// the .xcresult bundle; CI exports them as plain PNGs.
final class ScreenshotsTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testLightScreenshots() {
        launch(light: true, largeText: false)
        capturePages(prefix: "light")
    }

    func testDarkScreenshots() {
        launch(light: false, largeText: false)
        capturePages(prefix: "dark")
    }

    func testLargeTextScreenshots() {
        launch(light: true, largeText: true)
        capturePages(prefix: "large-text")
    }

    private func launch(light: Bool, largeText: Bool) {
        XCUIDevice.shared.appearance = light ? .light : .dark
        app = XCUIApplication()
        if largeText {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName",
                                    "UICTContentSizeCategoryAccessibilityExtraLarge"]
        }
        app.launch()
        // Onboarding appears only on a fresh install; later tests in the
        // same run have already completed it, so the tap is conditional.
        if app.buttons["跳过"].waitForExistence(timeout: 5) {
            app.buttons["跳过"].tap()
        }
        XCTAssertTrue(app.buttons["今日"].waitForExistence(timeout: 10))
    }

    private func capturePages(prefix: String) {
        capture("today", prefix: prefix)
        tapTab("睡眠"); capture("sleep", prefix: prefix)
        tapTab("心脏"); capture("heart", prefix: prefix)
        tapTab("健康库"); capture("records", prefix: prefix)
        tapTab("报告"); capture("report", prefix: prefix)
        tapTab("今日")
    }

    private func tapTab(_ label: String) {
        let tab = app.buttons[label]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "tab \(label) missing")
        tab.tap()
        Thread.sleep(forTimeInterval: 1)
    }

    private func capture(_ page: String, prefix: String) {
        Thread.sleep(forTimeInterval: 1)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "\(prefix)-\(page)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
