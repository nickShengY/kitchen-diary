import XCTest
final class WatchUITests:XCTestCase {
    func allowTimerNotificationsIfRequested(_ app:XCUIApplication) {
        for surface in [app,XCUIApplication(bundleIdentifier:"com.apple.Carousel")] {
            let allow=surface.buttons["Allow"]
            if allow.exists {
                for _ in 0..<3 {if allow.isHittable {break};surface.swipeUp()}
                allow.tap()
                return
            }
        }
    }

    func testCrownWheelAndCookingGuide() {
        let app=XCUIApplication();app.launch();allowTimerNotificationsIfRequested(app)
        XCTAssertTrue(app.buttons["watchSpin"].waitForExistence(timeout:12))
        let beforeCrown=app.staticTexts["watchWheelResult"].label
        XCUIDevice.shared.rotateDigitalCrown(delta:0.4)
        let changed=expectation(for:NSPredicate(format:"label != %@",beforeCrown),evaluatedWith:app.staticTexts["watchWheelResult"])
        wait(for:[changed],timeout:5)
        app.buttons["watchSpin"].tap()
        XCTAssertTrue(app.buttons["watchPickDish"].waitForExistence(timeout:6))
        let wheel=XCTAttachment(screenshot:app.screenshot());wheel.name="Watch-crown-wheel";wheel.lifetime = .keepAlways;add(wheel)
        app.buttons["watchPickDish"].tap()
        app.swipeUp()
        if app.buttons["watchDemoCooking"].waitForExistence(timeout:5) {app.buttons["watchDemoCooking"].tap()}
        XCTAssertTrue(app.staticTexts["watchInstruction"].waitForExistence(timeout:8))
        let guide=XCTAttachment(screenshot:app.screenshot());guide.name="Watch-cooking-guide";guide.lifetime = .keepAlways;add(guide)
    }
    func testPairedPhoneCookingHandoff() {
        let app=XCUIApplication();app.launchArguments=["-watch-handoff-test"];app.launch();allowTimerNotificationsIfRequested(app)
        XCTAssertTrue(app.staticTexts["watchInstruction"].waitForExistence(timeout:20), "Start the phone guide using kitchendiary://cook/pantry-tomato-scrambled-eggs before this paired test.")
        XCTAssertTrue(app.staticTexts["Tomato Scrambled Eggs"].exists)
        let before=app.staticTexts["watchInstruction"].label
        for _ in 0..<5 {if app.buttons["watchNextStep"].isHittable {break};app.swipeUp()}
        app.buttons["watchNextStep"].tap()
        XCTAssertNotEqual(app.staticTexts["watchInstruction"].label,before)
        let guide=XCTAttachment(screenshot:app.screenshot());guide.name="Watch-paired-cooking";guide.lifetime = .keepAlways;add(guide)
    }

}
