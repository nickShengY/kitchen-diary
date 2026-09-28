import Foundation

struct Ingredient: Codable, Identifiable, Hashable {
    var id: String; var name: String; var emoji: String; var category: String; var defaultUnit: String; var physicalProperties: [String]
}
struct KitchenTool: Codable, Identifiable { var id: String; var name: String; var type: String }
struct CookingAction: Codable, Identifiable {
    var id: String; var name: String; var verb: String; var icon: String; var requiresToolId: String?; var requiresHeat: Bool?; var validProperties: [String]?
}
struct Cuisine: Codable, Identifiable, Hashable { var id: String; var name: String; var emoji: String; var dishes: [String] }
struct StepIngredient: Codable, Identifiable, Hashable { var id: String; var amount: String; var unit: String }
struct RecipeStep: Codable, Identifiable, Hashable {
    var id = UUID().uuidString
    var station = "prep"
    var ingredients: [StepIngredient] = []
    var toolId = "knife"
    var actionId = "chop"
    var settings: [String: String]? = [:]
    var notes: String? = ""
    var durationSeconds: Int {
        guard let value = settings?["duration"]?.lowercased() else { return 0 }
        let numbers = value.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        guard let n = numbers.first else { return 0 }
        return n * (value.contains("hour") || value.contains("hr") ? 3600 : value.contains("sec") ? 1 : 60)
    }
}
struct Recipe: Codable, Identifiable, Hashable {
    var id = UUID().uuidString; var title: String; var description: String? = ""
    var authorId = "local-chef"; var authorName = "You"; var authorAvatar = "🧑‍🍳"
    var steps: [RecipeStep] = []; var likes: Int? = 0; var tags: [String] = []; var createdAt: Double = Date().timeIntervalSince1970 * 1000; var imageUrl: String?
    var shareText: String {
        let instructions = steps.enumerated().map { index, step in
            let ingredients = step.ingredients.map { "\($0.amount) \($0.unit) \($0.id.replacingOccurrences(of: "_", with: " "))" }.joined(separator: ", ")
            let settings = (step.settings ?? [:]).sorted { $0.key < $1.key }.map { "\($0.key.capitalized): \($0.value)" }.joined(separator: " · ")
            return ["\(index + 1). \(step.notes?.isEmpty == false ? step.notes! : step.actionId.capitalized)", ingredients, settings].filter { !$0.isEmpty }.joined(separator: "\n")
        }
        return ([title, description ?? ""] + instructions).joined(separator: "\n\n")
    }
}
struct PantryRecipe: Codable, Identifiable {
    var id: String; var title: String; var emoji: String; var blurb: String; var cuisine: String; var course: String
    var tags: [String]; var minutes: Int; var servings: Int; var difficulty: Int; var core: [String]; var extras: [String]?; var tools: [String]
}
struct ChipOption: Codable, Identifiable { var id: String; var label: String; var emoji: String; var description: String }
struct Catalog: Codable {
    var ingredients: [Ingredient]; var tools: [KitchenTool]; var actions: [CookingAction]; var cuisines: [Cuisine]; var recipes: [PantryRecipe]; var convertedRecipes: [Recipe]
    var staples: [String]; var assumedTools: [String]; var cookware: [String]
    var temperatures: [String]; var times: [String]; var waterLevels: [String]; var cutShapes: [ChipOption]; var cookMethods: [ChipOption]; var details: [ChipOption]
    static let shared: Catalog = {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json"), let data = try? Data(contentsOf: url), let result = try? JSONDecoder().decode(Catalog.self, from: data) else { fatalError("The bundled kitchen catalog is missing or invalid. Run Tools/export-catalog.mjs.") }
        return result
    }()
    func recipe(_ id: String) -> Recipe? { convertedRecipes.first { $0.id == id || $0.id == "pantry-" + id } }
    func ingredient(_ id: String) -> Ingredient? { ingredients.first { $0.id == id } }
}
enum MatchMode: String, Codable, CaseIterable { case flexible, exact, survival }
struct PantryState: Codable {
    var ingredients: [String] = []; var cookware: [String] = []; var mode: MatchMode = .flexible
    var favorites: [String] = []; var history: [String] = []; var dishCount = 3
}
struct RecipeMatch: Identifiable {
    var recipe: PantryRecipe; var score: Double; var missingCore: [String]; var missingExtras: [String]; var missingTools: [String]; var coverage: Double
    var id: String { recipe.id }
    var ready: Bool { missingCore.isEmpty && missingTools.isEmpty }
    var reason: String { !missingTools.isEmpty ? "Needs cookware" : missingCore.isEmpty ? "All the essentials are in your kitchen" : missingCore.count == 1 ? "One ingredient away" : "\(missingCore.count) ingredients away" }
}
enum PantryMatcher {
    static func matches(_ state: PantryState, catalog: Catalog, hour: Int = Calendar.current.component(.hour, from: Date())) -> [RecipeMatch] {
        let pantry = Set(state.ingredients), tools = Set(state.cookware), staples = Set(catalog.staples), assumed = Set(catalog.assumedTools)
        let slot = hour < 10 ? ["Breakfast"] : hour < 15 ? ["Lunch", "Quick"] : hour < 21 ? ["Dinner"] : ["Quick", "Dessert"]
        return catalog.recipes.compactMap { r -> RecipeMatch? in
            let missing = r.core.filter { !pantry.contains($0) && !staples.contains($0) }
            let extras = r.extras ?? [], missingExtras = extras.filter { !pantry.contains($0) && !staples.contains($0) }
            let missingTools = tools.isEmpty ? [] : r.tools.filter { !tools.contains($0) && !assumed.contains($0) }
            guard missingTools.isEmpty else { return nil }
            if state.mode != .flexible && !missing.isEmpty { return nil }
            if state.mode == .survival && (r.difficulty != 1 || r.minutes > 30) { return nil }
            if state.mode == .flexible && !pantry.isEmpty && missing.count == r.core.count { return nil }
            let coverage = r.core.isEmpty ? 1 : Double(r.core.count - missing.count) / Double(r.core.count)
            let extraRatio = extras.isEmpty ? 1 : Double(extras.count - missingExtras.count) / Double(extras.count)
            let relevant = r.tags.contains { slot.contains($0) }
            var score: Double
            if pantry.isEmpty {
                score = 40 + (relevant ? 25 : 0) + (r.minutes <= 20 ? 12 : r.minutes >= 75 ? -10 : 0) + Double((4-r.difficulty)*5)
            } else {
                score = coverage*100 + extraRatio*18 - Double(missing.count)*9 - Double(missingExtras.count)*1.5
                score += missing.isEmpty ? 12 : 0
                score += r.minutes <= 20 ? 6 : r.minutes >= 75 ? -4 : 0
                score += relevant ? 10 : 0
            }
            if state.favorites.contains(r.id) { score += 14 }
            if let index = state.history.firstIndex(of: r.id) { score -= Double(18-min(index,5)*3) }
            let hash = r.id.utf16.reduce(0) { ($0*31+Int($1))%1000 }
            score += Double(hash)/1000*4
            return RecipeMatch(recipe:r, score:(score*10).rounded()/10, missingCore:missing, missingExtras:missingExtras, missingTools:missingTools, coverage:coverage)
        }.sorted { $0.score == $1.score ? $0.recipe.title.localizedCompare($1.recipe.title) == .orderedAscending : $0.score > $1.score }
    }
    static func menu(_ state: PantryState, catalog: Catalog, locked: [String] = [], seed: Int = 0, hour: Int = Calendar.current.component(.hour, from: Date())) -> [RecipeMatch] {
        let ranked = matches(state,catalog:catalog,hour:hour)
        var chosen = locked.compactMap { id in ranked.first { $0.id == id } }
        let proteins: Set<String> = ["chicken","chicken_breast","chicken_thigh","beef","ground_beef","beef_slices","steak","pork","pork_belly","bacon","sausage","lamb","fish","white_fish","salmon","shrimp","tofu","egg","chickpeas","lentils","kidney_beans"]
        func protein(_ r: RecipeMatch) -> String { r.recipe.core.first { proteins.contains($0) } ?? "none" }
        let shape = ["main","side","soup","side","dessert","main","snack"]
        let target = max(min(max(state.dishCount,1),5),chosen.count)
        var index = 0
        while chosen.count < target {
            let course = shape[index % shape.count]; index += 1
            let pool = ranked.filter { m in !chosen.contains { $0.id == m.id } }
            func pick(_ filter: (RecipeMatch)->Bool) -> RecipeMatch? {
                let head = Array(pool.filter(filter).prefix(5)); return head.isEmpty ? nil : head[(abs(seed)+chosen.count*7)%head.count]
            }
            let usedProteins = Set(chosen.map(protein))
            if let next = pick({ $0.recipe.course == course && !usedProteins.contains(protein($0)) }) ?? pick({ $0.recipe.course == course }) ?? (index > shape.count ? pick({ _ in true }) : nil) { chosen.append(next) }
            else if index > shape.count*2 { break }
        }
        return Array(chosen.prefix(target))
    }
}
struct CookingSession: Codable, Equatable {
    var id = UUID().uuidString; var recipe: Recipe; var stepIndex = 0; var timerEnd: Date?; var pausedSeconds: Int?; var updatedAt = Date()
    var step: RecipeStep? { recipe.steps.indices.contains(stepIndex) ? recipe.steps[stepIndex] : nil }
    func remaining(at date: Date = Date()) -> Int { timerEnd.map { max(0,Int(ceil($0.timeIntervalSince(date)))) } ?? pausedSeconds ?? 0 }
}
