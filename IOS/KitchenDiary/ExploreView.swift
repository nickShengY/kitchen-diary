import SwiftUI

struct ExploreView: View {
    @EnvironmentObject var store: KitchenStore
    @Environment(\.dynamicTypeSize) var typeSize
    var edit: (Recipe)->Void
    @State private var query = ""
    @State private var tag = "All"
    @State private var sort = "Popular"
    @State private var remote: [Recipe] = []
    @State private var loading = false
    @State private var error: String?
    @State private var selected: Recipe?
    var recipes: [Recipe] {
        var ids = Set<String>()
        let base = (store.data.published + store.catalog.convertedRecipes + remote).filter { ids.insert($0.id).inserted }
        let result = base.filter { (query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) || $0.tags.joined(separator:" ").localizedCaseInsensitiveContains(query)) && (tag == "All" || $0.tags.contains(tag)) }
        return sort == "Latest" ? result.sorted {$0.createdAt > $1.createdAt} : result.sorted { ($0.likes ?? 0) > ($1.likes ?? 0) }
    }
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:24) {
                HStack { Eyebrow(title:"The golden hour kitchen"); Spacer(); Image(systemName:"sun.max").foregroundStyle(KitchenTheme.coral) }
                SectionTitle(title:"A little inspiration",subtitle:"For whatever you’re craving today.")
                if typeSize.isAccessibilitySize {
                    VStack(alignment:.leading,spacing:14) {
                        Image("hero").resizable().scaledToFill().frame(height:180).clipped().clipShape(RoundedRectangle(cornerRadius:24)).accessibilityHidden(true)
                        Text("Something delicious starts here.").font(.title2.bold()).padding(.horizontal,4)
                    }
                } else {
                ZStack(alignment:.bottomLeading) {
                    Image("hero").resizable().scaledToFill().frame(height:230).clipped()
                    LinearGradient(colors:[.clear,.black.opacity(0.7)],startPoint:.center,endPoint:.bottom)
                    VStack(alignment:.leading,spacing:6) { Text("THE JOY OF EVERYDAY COOKING").font(.caption2.bold()).tracking(1.6); Text("Something delicious\nstarts here.").font(KitchenTheme.display(30)) }.foregroundStyle(.white).padding(24)
                }.clipShape(RoundedRectangle(cornerRadius:28))
                }
                HStack { Image(systemName:"magnifyingglass").foregroundStyle(KitchenTheme.coral); TextField("Find your next favourite",text:$query).submitLabel(.search).onSubmit { Task { await searchOnline() } }.accessibilityIdentifier("recipeSearch"); if loading { ProgressView() } }.padding(16).background(KitchenTheme.card,in:Capsule())
                ScrollView(.horizontal,showsIndicators:false) { HStack { ForEach(["All","Quick","Dinner","Lunch","Breakfast","Healthy","Dessert"],id:\.self) { item in Chip(text:item,selected:tag == item) { tag = item } } } }
                HStack { Text("From the recipe book").font(KitchenTheme.display(24)); Spacer(); Picker("Sort recipes",selection:$sort) { Text("Popular").tag("Popular"); Text("Latest").tag("Latest") }.pickerStyle(.menu) }
                if let error { Text(error).font(.caption).foregroundStyle(.secondary) }
                if recipes.isEmpty { ContentUnavailableView.search(text:query); Button("Search the wider recipe catalog") { Task {await searchOnline()} }.buttonStyle(KitchenButton()) }
                LazyVGrid(columns:[GridItem(.adaptive(minimum:280),spacing:20)],spacing:20) {
                    ForEach(recipes) { recipe in RecipeCard(recipe:recipe) {selected=recipe} }
                }
            }.padding(22).frame(maxWidth:1100)
        }.frame(maxWidth:.infinity).kitchenBackground().navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement:.principal) { Label("Kitchen Diary",systemImage:"fork.knife").font(.system(.headline,design:.rounded)) } }
            .sheet(item:$selected) { recipe in RecipeDetailView(recipe:recipe,edit:edit) }
            .refreshable { await searchOnline() }
    }
    func searchOnline() async {
        loading = true; error = nil
        do { remote = try await MealService.search(query) } catch { self.error = "The online kitchen is taking a breather. Your saved recipes are still here." }
        loading = false
    }
}
struct RecipeCard: View {
    @EnvironmentObject var store: KitchenStore
    var recipe: Recipe; var open: ()->Void
    var body:some View {
        VStack(alignment:.leading,spacing:14) {
            Button(action:open) { VStack(alignment:.leading,spacing:14) { RecipeArtwork(recipe:recipe); HStack { Text(recipe.tags.prefix(2).joined(separator:" · ").uppercased()).font(.caption2.bold()).tracking(1).foregroundStyle(KitchenTheme.sage); Spacer(); Label("\(recipe.steps.count)",systemImage:"list.bullet").font(.caption).foregroundStyle(.secondary) }; Text(recipe.title).font(KitchenTheme.display(23)).foregroundStyle(.primary).multilineTextAlignment(.leading); Text(recipe.description ?? "").font(.subheadline).foregroundStyle(.secondary).lineLimit(2) } }.buttonStyle(.plain)
            HStack { Text(recipe.authorAvatar); Text(recipe.authorName).font(.caption).foregroundStyle(.secondary); Spacer(); Button { store.like(recipe) } label: { Image(systemName:store.data.liked.contains(recipe.id) ? "heart.fill" : "heart").foregroundStyle(KitchenTheme.coral).symbolEffect(.bounce,value:store.data.liked.contains(recipe.id)).frame(width:44,height:44) }.accessibilityLabel("Like \(recipe.title)"); Button {store.favorite(recipe)} label: {Image(systemName:store.isFavorite(recipe) ? "bookmark.fill":"bookmark").frame(width:44,height:44)}.accessibilityLabel("Save \(recipe.title)") }.buttonStyle(.borderless).frame(minHeight:30)
        }.padding(15).background(KitchenTheme.card,in:RoundedRectangle(cornerRadius:28))
    }
}
struct RecipeDetailView: View {
    @EnvironmentObject var store: KitchenStore
    @Environment(\.dismiss) var dismiss
    var recipe: Recipe; var edit: (Recipe)->Void
    @State private var cooking = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:22) {
                    RecipeArtwork(recipe:recipe,height:240)
                    SectionTitle(title:recipe.title,subtitle:recipe.description ?? "")
                    HStack { Label("\(recipe.steps.count) steps",systemImage:"list.bullet"); Spacer(); Button {store.favorite(recipe)} label: {Label(store.isFavorite(recipe) ? "Saved":"Save",systemImage:store.isFavorite(recipe) ? "bookmark.fill":"bookmark")} }.font(.subheadline)
                    if recipe.steps.isEmpty { Text("This recipe has no cooking steps yet. Add them in Create before cooking.").foregroundStyle(.secondary) }
                    ForEach(Array(recipe.steps.enumerated()),id:\.element.id) { index,step in
                        PaperCard { HStack(alignment:.top,spacing:16) { Text(String(format:"%02d",index+1)).font(KitchenTheme.display(26)).foregroundStyle(KitchenTheme.coral); VStack(alignment:.leading,spacing:8) { Text(step.notes?.isEmpty == false ? step.notes! : step.actionId.capitalized).font(.body); Text(step.ingredients.map { "\($0.amount) \($0.unit) \(store.catalog.ingredient($0.id)?.name ?? $0.id)" }.joined(separator:" · ")).font(.caption).foregroundStyle(.secondary); if let settings = step.settings { Text(settings.sorted(by:{$0.key<$1.key}).map {"\($0.key.capitalized): \($0.value)"}.joined(separator:" · ")).font(.caption).foregroundStyle(KitchenTheme.sage) } } } }
                    }
                    Button {store.startCooking(recipe); cooking=true} label: {Label("Let’s cook this",systemImage:"play.fill")}.buttonStyle(KitchenButton()).disabled(recipe.steps.isEmpty).accessibilityIdentifier("startCooking")
                    Button("Make it my own") {edit(recipe);dismiss()}.buttonStyle(KitchenButton(secondary:true))
                    ShareLink(item:recipe.shareText) {Label("Share recipe",systemImage:"square.and.arrow.up")}.frame(maxWidth:.infinity).padding()
                }.padding(22).frame(maxWidth:740)
            }.frame(maxWidth:.infinity).kitchenBackground().toolbar { ToolbarItem(placement:.confirmationAction) {Button("Done") {dismiss()}} }
        }.fullScreenCover(isPresented:$cooking) {CookingView()}
    }
}
struct MealService {
    struct Response: Decodable { var meals: [[String:String?]]? }
    static func search(_ query: String) async throws -> [Recipe] {
        var components=URLComponents(string:"https://www.themealdb.com/api/json/v1/1/search.php")!
        components.queryItems=[URLQueryItem(name:"s",value:query)]
        var request=URLRequest(url:components.url!); request.timeoutInterval=10
        let (data,response)=try await URLSession.shared.data(for:request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {throw URLError(.badServerResponse)}
        let payload=try JSONDecoder().decode(Response.self,from:data)
        return (payload.meals ?? []).map { meal in
            func value(_ key:String)->String { (meal[key] ?? nil) ?? "" }
            let instructions=value("strInstructions").components(separatedBy:.newlines).filter {!$0.trimmingCharacters(in:.whitespaces).isEmpty}
            var ingredients:[StepIngredient]=[]
            for i in 1...20 where !value("strIngredient\(i)").isEmpty { ingredients.append(StepIngredient(id:value("strIngredient\(i)"),amount:value("strMeasure\(i)"),unit:"")) }
            let steps=instructions.enumerated().map { index,line in RecipeStep(station:"cook",ingredients:index == 0 ? ingredients:[],toolId:"",actionId:"cook",notes:line) }
            return Recipe(id:"mealdb-"+value("idMeal"),title:value("strMeal"),description:String(value("strInstructions").prefix(150)),authorId:"mealdb",authorName:value("strArea")+" Kitchen",authorAvatar:"🍽️",steps:steps,tags:[value("strArea"),value("strCategory")].filter {!$0.isEmpty},imageUrl:value("strMealThumb"))
        }
    }
}
