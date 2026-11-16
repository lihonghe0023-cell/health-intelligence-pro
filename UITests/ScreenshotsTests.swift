import XCTest

/// Screenshot gate for Issue #1 (7/7 visual acceptance).
/// Seven pages x three display modes = 21 screenshots:
/// welcome, today, settings, sleep, heart, records, report
/// each in light, dark and extra-large text.
/// The simulator has no HealthKit data, so every page shows its honest
/// empty state ("—" / "暂无记录"); no sample data is ever manufactured.
/// Screenshots are XCTAttachments (lifetime .keepAlways) so they land in
/// the .xcresult bundle; CI exports them as plain PNGs.
/// The test also taps through the real navigation (skip onboarding, open
/// Settings, open a metric detail page and go back) so a dead button or
/// a broken push fails the run instead of silently screenshotting.
final class ScreenshotsTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testLightScreenshots() {
        launch(light: true, largeText: false)
        captureAllPages(prefix: "light")
    }

    func testDarkScreenshots() {
        launch(light: false, largeText: false)
        captureAllPages(prefix: "dark")
    }

    func testLargeTextScreenshots() {
        launch(light: true, largeText: true)
        captureAllPages(prefix: "large-text")
    }

    private func launch(light: Bool, largeText: Bool) {
        XCUIDevice.shared.appearance = light ? .light : .dark
        app = XCUIApplication()
        // Reset onboarding so every mode starts at the welcome screen.
        app.launchArguments += ["-resetOnboardingForScreenshots"]
        if largeText {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName",
                                    "UICTContentSizeCategoryAccessibilityExtraLarge"]
        }
        app.launch()
    }

    private func captureAllPages(prefix: String) {
        // 1/7 welcome (first-launch screen).
        XCTAssertTrue(app.staticTexts["读懂健康，从真实数据开始"].waitForExistence(timeout: 10))
        capture("welcome", prefix: prefix)
        app.buttons["跳过"].tap()

        // 2/7 today.
        XCTAssertTrue(app.staticTexts["读懂身体的每一天"].waitForExistence(timeout: 10))
        capture("today", prefix: prefix)

        // 3/7 settings (gear on Today, dismissed with 完成).
        app.buttons["设置与隐私"].tap()
        XCTAssertTrue(app.staticTexts["设置与隐私"].waitForExistence(timeout: 10))
        capture("settings", prefix: prefix)
        app.buttons["完成"].tap()
        XCTAssertTrue(app.staticTexts["读懂身体的每一天"].waitForExistence(timeout: 10))

        // 4/7 sleep.
        tapTab("睡眠")
        XCTAssertTrue(app.staticTexts["睡眠，是身体的修复时间"].waitForExistence(timeout: 10))
        capture("sleep", prefix: prefix)

        // 5/7 heart.
        tapTab("心脏")
        XCTAssertTrue(app.staticTexts["心脏健康"].waitForExistence(timeout: 10))
        capture("heart", prefix: prefix)

        // 6/7 records. The page is a List: rows below the fold (such as
        // "暂无笔记" at the bottom) are not in the accessibility tree
        // until scrolled to, so assert on the top of the page instead —
        // the navigation title and the first section's button.
        tapTab("健康库")
        XCTAssertTrue(app.staticTexts["健康数据库"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["录入血压、血糖或体重"].waitForExistence(timeout: 10))
        capture("records", prefix: prefix)

        // 7/7 report.
        tapTab("报告")
        XCTAssertTrue(app.staticTexts["把每一次记录，变成更清晰的理解"].waitForExistence(timeout: 10))
        capture("report", prefix: prefix)

        // Button-tap evidence: back on Today, open a metric detail page
        // and return. No extra screenshot; the assertions are the proof.
        tapTab("今日")
        let tile = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "静息心率")).firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 10), "resting heart rate tile missing")
        tile.tap()
        XCTAssertTrue(app.staticTexts["历史趋势"].waitForExistence(timeout: 10))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["读懂身体的每一天"].waitForExistence(timeout: 10))
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
