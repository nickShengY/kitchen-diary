import XCTest
import UIKit
@testable import KitchenDiary

final class KitchenCoreTests:XCTestCase {
    struct Fixture:Decodable {var pantry:[String];var mode:MatchMode;var cookware:[String];var hour:Int;var seed:Int;var dishCount:Int;var ranking:[Rank];var menu:[String]}
    struct Rank:Decodable {var id:String;var score:Double}
    func testFullReactCatalog() {
        let c=Catalog.shared
        XCTAssertEqual(c.ingredients.count,204);XCTAssertEqual(c.tools.count,50);XCTAssertEqual(c.actions.count,45);XCTAssertEqual(c.recipes.count,59);XCTAssertEqual(c.cuisines.count,31)
        XCTAssertEqual(Set(c.ingredients.map(\.id)).count,c.ingredients.count)
        XCTAssertEqual(c.convertedRecipes.count,c.recipes.count)
        for recipe in c.convertedRecipes {XCTAssertFalse(recipe.steps.isEmpty);for step in recipe.steps {XCTAssertTrue(c.actions.contains {$0.id==step.actionId});XCTAssertTrue(c.tools.contains {$0.id==step.toolId});for i in step.ingredients {XCTAssertNotNil(c.ingredient(i.id))}}}
    }
    func testReactRankingAndBalancedMenuParity() throws {
        let url=Bundle(for:Self.self).url(forResource:"parity-fixtures",withExtension:"json")!
        let fixtures=try JSONDecoder().decode([Fixture].self,from:Data(contentsOf:url))
        XCTAssertEqual(fixtures.count,36)
        for f in fixtures {
            let state=PantryState(ingredients:f.pantry,cookware:f.cookware,mode:f.mode,dishCount:f.dishCount)
            let actual=PantryMatcher.matches(state,catalog:.shared,hour:f.hour)
            XCTAssertEqual(actual.map(\.id),f.ranking.map(\.id),"mode \(f.mode), hour \(f.hour)")
            XCTAssertEqual(actual.map(\.score),f.ranking.map(\.score))
            XCTAssertEqual(PantryMatcher.menu(state,catalog:.shared,seed:f.seed,hour:f.hour).map(\.id),f.menu)
        }
    }
    func testCookwareFilterAndSurvival() {
        let c=Catalog.shared
        let state=PantryState(ingredients:c.ingredients.map(\.id),cookware:["knife"],mode:.survival)
        for match in PantryMatcher.matches(state,catalog:c) {XCTAssertTrue(match.ready);XCTAssertLessThanOrEqual(match.recipe.minutes,30);XCTAssertEqual(match.recipe.difficulty,1);XCTAssertTrue(match.missingTools.isEmpty)}
    }
    func testMenuLocksAndUniqueShopping() {
        let state=PantryState(ingredients:["tomato","egg","rice"],dishCount:3),c=Catalog.shared
        let menu=PantryMatcher.menu(state,catalog:c)
        XCTAssertFalse(menu.isEmpty)
        let locked=menu[0].id
        let rolled=PantryMatcher.menu(state,catalog:c,locked:[locked],seed:9)
        XCTAssertTrue(rolled.contains {$0.id==locked});XCTAssertEqual(Set(rolled.map(\.id)).count,rolled.count)
    }
    func testWheelPointerMatchesEveryWinner() {
        for count in [1,2,5,12,31] {for index in 0..<count {for rotation in [0.0,27.0,850.0,10000.0] {let target=WheelMath.targetRotation(current:rotation,index:index,count:count);XCTAssertEqual(WheelMath.winner(rotation:target,count:count),index)}}}
        XCTAssertNil(WheelMath.winner(rotation:0,count:0))
    }
    func testTimerUsesWallClock() {
        var s=CookingSession(recipe:Recipe(title:"Test"));s.timerEnd=Date(timeIntervalSince1970:1060)
        XCTAssertEqual(s.remaining(at:Date(timeIntervalSince1970:1000)),60);XCTAssertEqual(s.remaining(at:Date(timeIntervalSince1970:1070)),0)
        s.timerEnd=nil;s.pausedSeconds=42;XCTAssertEqual(s.remaining(),42)
    }
    func testDurationParsing() {
        var s=RecipeStep();s.settings=["duration":"15 min"];XCTAssertEqual(s.durationSeconds,900)
        s.settings=["duration":"30 sec"];XCTAssertEqual(s.durationSeconds,30)
        s.settings=["duration":"1 hour"];XCTAssertEqual(s.durationSeconds,3600)
        s.settings=["duration":"Until golden"];XCTAssertEqual(s.durationSeconds,0)
    }
    @MainActor func testPersistenceAndCookingHistory() throws {
        let suite="kitchen-tests-"+UUID().uuidString,defaults=UserDefaults(suiteName:suite)!
        defer {defaults.removePersistentDomain(forName:suite)}
        let store=KitchenStore(defaults:defaults,connectWatch:false)
        store.toggleIngredient("tomato");store.toggleTool("wok");store.data.draft=Recipe(title:"Test",steps:[RecipeStep(notes:"Chop")]);store.saveDraft()
        let second=KitchenStore(defaults:defaults,connectWatch:false)
        XCTAssertTrue(second.data.pantry.ingredients.contains("tomato"));XCTAssertEqual(second.data.cookbook.first?.title,"Test")
        second.startCooking(second.data.draft);second.moveStep(100);XCTAssertEqual(second.data.session?.stepIndex,0)
        second.completeCooking();XCTAssertNil(second.data.session);XCTAssertEqual(second.data.pantry.history.count,1)
    }
    @MainActor func testCloudNormalization() {let value=AccountService.pantry(["dishCount":99,"history":Array(repeating:"x",count:30),"mode":"bad"]);XCTAssertEqual(value.dishCount,5);XCTAssertEqual(value.history.count,20);XCTAssertEqual(value.mode,.flexible)}
    @MainActor func testRealOnDeviceMenuOCR() throws {
        let image=UIGraphicsImageRenderer(size:CGSize(width:900,height:500)).image {context in
            UIColor.white.setFill();context.fill(CGRect(x:0,y:0,width:900,height:500))
            ("Tomato soup\nGarden salad\nRoast chicken" as NSString).draw(at:CGPoint(x:50,y:60),withAttributes:[.font:UIFont.systemFont(ofSize:42),.foregroundColor:UIColor.black])
        }
        let lines=try MenuRecognition.lines(from:try XCTUnwrap(image.pngData()))
        for dish in ["Tomato soup","Garden salad","Roast chicken"] {XCTAssertTrue(lines.contains {$0.localizedCaseInsensitiveContains(dish)},lines.joined(separator:" | "))}
    }

    @MainActor func testAppleNonceIsUniqueAndHasKnownSHA256() throws {
        XCTAssertEqual(AppleAuthorization.digest("abc"),"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        let nonces=try (0..<100).map {_ in try AppleAuthorization.randomNonce()}
        XCTAssertEqual(Set(nonces).count,100)
        XCTAssertTrue(nonces.allSatisfy {$0.count==64})
    }

    func testProductionRecipeSearchRejectsDevelopmentKeyAndBuildPlaceholders() {
        XCTAssertNil(MealService.productionKey(nil));XCTAssertNil(MealService.productionKey("1"))
        XCTAssertNil(MealService.productionKey("$(MEALDB_API_KEY)"));XCTAssertNil(MealService.productionKey("../other"))
        XCTAssertEqual(MealService.productionKey(" 12345 "),"12345")
    }

}
