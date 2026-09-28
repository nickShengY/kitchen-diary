import XCTest
final class KitchenUITests:XCTestCase {
    var app:XCUIApplication!
    override func setUpWithError() throws {continueAfterFailure=false;app=XCUIApplication();app.launchArguments=["-kitchen.onboarded","YES","-ui-testing-reset"];if name.contains("testTimerSurvives") {app.launchArguments.append("-ui-testing-watch")};app.launch()}
    func openTab(_ title:String) {
        let button=app.tabBars.buttons[title]
        if button.exists {
            for _ in 0..<3 {button.tap();if button.isSelected {return}}
        } else {
            let item=app.buttons[title]
            if item.exists {item.firstMatch.tap()} else {app.staticTexts[title].firstMatch.tap()}
        }
    }
    func screenshot(_ name:String) {let shot=XCTAttachment(screenshot:app.screenshot());shot.name=name;shot.lifetime = .keepAlways;add(shot)}
    func testExploreAndRecipeCooking() {
        XCTAssertTrue(app.staticTexts["A little inspiration"].waitForExistence(timeout:10));screenshot("01-explore")
        let search=app.textFields["recipeSearch"];search.tap();search.typeText("tomato\n")
        app.swipeUp();app.buttons.matching(NSPredicate(format:"label CONTAINS[c] %@ AND identifier != %@","Tomato","resumeCooking")).firstMatch.tap()
        XCTAssertTrue(app.buttons["startCooking"].waitForExistence(timeout:4))
        for _ in 0..<7 {if app.buttons["startCooking"].isHittable {break};app.swipeUp()}
        app.buttons["startCooking"].tap();XCTAssertTrue(app.staticTexts["cookingInstruction"].waitForExistence(timeout:4));screenshot("02-cooking")
    }
    func testPantryAndWheel() {
        openTab("Kitchen");XCTAssertTrue(app.staticTexts["What’s in your kitchen?"].waitForExistence(timeout:5));screenshot("03-pantry")
        if app.buttons["starterPantry"].exists {app.buttons["starterPantry"].tap()}
        let search=app.textFields["pantrySearch"];search.tap();search.typeText("tomato\n")
        XCTAssertTrue(app.buttons["ingredient-tomato"].waitForExistence(timeout:3));app.buttons["ingredient-tomato"].tap()
        openTab("Decide");XCTAssertTrue(app.buttons["spinWheel"].waitForExistence(timeout:5))
        for _ in 0..<4 {if app.buttons["spinWheel"].isHittable {break};app.swipeUp()}
        app.buttons["spinWheel"].tap();XCTAssertTrue(app.staticTexts["wheelResult"].waitForExistence(timeout:7));screenshot("04-wheel-result")
        app.swipeUp();app.buttons["pickDish"].tap();XCTAssertTrue(app.buttons["spinWheel"].exists)
    }
    func testCreateRecipeAndPersistence() {
        openTab("Create");XCTAssertTrue(app.buttons["addStep"].waitForExistence(timeout:5))
        let title=app.textFields["recipeTitle"];title.tap();title.press(forDuration:1.2)
        if app.menuItems["Select All"].waitForExistence(timeout:1) {app.menuItems["Select All"].tap();title.typeText("Simulator soup")} else {title.typeText(" test")}
        app.swipeUp();app.buttons["addStep"].tap()
        let search=app.textFields["stepIngredientSearch"];XCTAssertTrue(search.waitForExistence(timeout:5));search.tap();search.typeText("tomato\n")
        app.buttons["stepIngredient-tomato"].tap();app.swipeUp();app.buttons["stepNext"].tap()
        let chop=app.buttons["action-chop"];if chop.exists {chop.tap()}
        for _ in 0..<15 {if app.buttons["stepNext"].isHittable {break};app.swipeUp()};app.buttons["stepNext"].tap()
        for _ in 0..<5 {if app.textFields["stepNotes"].isHittable {break};app.swipeUp()}
        let notes=app.textViews["stepNotes"];if notes.exists {notes.tap();notes.typeText("Chop the tomatoes into little pieces.")}
        app.swipeUp();app.buttons["stepNext"].tap();screenshot("05-builder")
        app.terminate();app.launchArguments=["-kitchen.onboarded","YES"];app.launch();openTab("Create");XCTAssertTrue(app.staticTexts["1 steps"].waitForExistence(timeout:5))
        openTab("Diary");screenshot("06-diary")
    }
    func testRotationAndAccessibleTextLayout() {
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.staticTexts["A little inspiration"].waitForExistence(timeout:5))
        screenshot("07-landscape")
        XCUIDevice.shared.orientation = .portrait
        app.terminate()
        app.launchArguments=["-kitchen.onboarded","YES","-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.staticTexts["A little inspiration"].waitForExistence(timeout:5))
        screenshot("08-large-text")
    }

    func testTimerSurvivesRelaunchAndSendsGuideToWatch() {
        let springboard=XCUIApplication(bundleIdentifier:"com.apple.springboard")
        if springboard.alerts.buttons["Cancel"].exists {springboard.alerts.buttons["Cancel"].tap()}
        let search=app.textFields["recipeSearch"];XCTAssertTrue(search.waitForExistence(timeout:8));search.tap();search.typeText("tomato\n")
        app.swipeUp();app.buttons.matching(NSPredicate(format:"label CONTAINS[c] %@ AND identifier != %@","Tomato Scrambled Eggs","resumeCooking")).firstMatch.tap()
        for _ in 0..<8 {if app.buttons["startCooking"].isHittable {break};app.swipeUp()}
        app.buttons["startCooking"].tap()
        XCTAssertTrue(app.staticTexts["cookingInstruction"].waitForExistence(timeout:5))
        for _ in 0..<5 {if app.buttons["startTimer"].isHittable {break};app.swipeUp()}
        app.buttons["startTimer"].tap()
        if springboard.alerts.buttons["Allow"].waitForExistence(timeout:3) {springboard.alerts.buttons["Allow"].tap()}
        XCTAssertTrue(app.buttons["Pause"].waitForExistence(timeout:5))
        func seconds(_ value:String)->Int {let parts=value.split(separator:":").compactMap {Int($0)};return parts.count==2 ? parts[0]*60+parts[1]:-1}
        let before=seconds(app.staticTexts["timerRemaining"].label),capturedAt=Date()
        XCTAssertGreaterThan(before,0)
        app.terminate();app.launchArguments=["-kitchen.onboarded","YES"];app.launch()
        XCTAssertTrue(app.buttons["resumeCooking"].waitForExistence(timeout:6));app.buttons["resumeCooking"].tap()
        for _ in 0..<5 {if app.buttons["Pause"].isHittable {break};app.swipeUp()}
        XCTAssertTrue(app.buttons["Pause"].exists)
        let remaining=app.staticTexts["timerRemaining"].label
        let expected=max(0,before-Int(Date().timeIntervalSince(capturedAt)))
        XCTAssertEqual(Double(seconds(remaining)),Double(expected),accuracy:3,remaining)
        screenshot("09-timer-restored")
        app.buttons["Pause"].tap()
        for _ in 0..<5 {if app.buttons["nextCookingStep"].isHittable {break};app.swipeUp()}
        app.buttons["nextCookingStep"].tap()
    }

    func testFreeManualMenuAndProRecognitionPaywall() {
        openTab("Decide")
        screenshot("12-manual-menu")
        app.buttons["Scan a menu"].tap()
        XCTAssertTrue(app.buttons["unlockMenuRecognition"].waitForExistence(timeout:5))
        XCTAssertFalse(app.buttons["menuPhotoPicker"].exists)
        let dishes=app.textFields["menuDishes"].exists ? app.textFields["menuDishes"]:app.textViews["menuDishes"]
        dishes.tap();dishes.typeText("Tomato soup")
        app.swipeUp()
        app.buttons["Use these dishes"].tap()
        XCTAssertTrue(app.buttons["spinWheel"].exists)
        for _ in 0..<4 {if app.buttons["unlockMenuRecognition"].isHittable {break};app.swipeDown()}
        app.buttons["unlockMenuRecognition"].tap()
        XCTAssertTrue(app.staticTexts["Kitchen Diary Pro"].waitForExistence(timeout:5))
        screenshot("10-pro-menu-recognition")
        XCTAssertTrue(app.buttons["Restore purchases"].exists)
    }
    func testAppleSignInAndPrivacyAreDiscoverable() {
        openTab("Diary")
        XCTAssertTrue(app.buttons["appleSignIn"].waitForExistence(timeout:5))
        app.buttons["Settings"].tap()
        screenshot("11-settings")
        XCTAssertTrue(app.descendants(matching:.any)["privacyPolicy"].waitForExistence(timeout:5))
        XCTAssertTrue(app.descendants(matching:.any)["Contact support"].exists)
        screenshot("11-privacy-settings")
    }

}
