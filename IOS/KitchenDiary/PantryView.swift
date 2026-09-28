import SwiftUI

struct PantryView: View {
    @EnvironmentObject var store: KitchenStore
    var edit: (Recipe)->Void
    @State private var query=""
    @State private var category="vegetable"
    @State private var section="Ingredients"
    @State private var seed=0
    @State private var locked:[String]=[]
    @State private var shopping=false
    @State private var selected:Recipe?
    var menu:[RecipeMatch] {PantryMatcher.menu(store.data.pantry,catalog:store.catalog,locked:locked,seed:seed)}
    var matches:[RecipeMatch] {PantryMatcher.matches(store.data.pantry,catalog:store.catalog)}
    var shoppingIDs:[String] {Array(Set(menu.flatMap(\.missingCore))).sorted()}
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:24) {
                Eyebrow(title:"A little less waste. A little more magic.")
                SectionTitle(title:"What’s in your kitchen?",subtitle:"Good things start with what you already have.")
                PaperCard(color:KitchenTheme.sage.opacity(0.10)) {
                    HStack { VStack(alignment:.leading,spacing:8) { Text("Your little pantry").font(KitchenTheme.display(24)); Text("\(store.data.pantry.ingredients.count) ingredients · \(store.data.pantry.cookware.count) tools").font(.subheadline).foregroundStyle(.secondary) }; Spacer(); Image("mascot").resizable().scaledToFit().frame(width:85,height:85).accessibilityHidden(true) }
                    if store.data.pantry.ingredients.isEmpty { Button("Start with the everyday essentials") {store.data.pantry.ingredients=["egg","onion","garlic","tomato","potato","carrot","rice","pasta","chicken","soy_sauce","butter","milk"]}.font(.subheadline.bold()).padding(.top,10).accessibilityIdentifier("starterPantry") }
                }
                Picker("Kitchen shelves",selection:$section) {Text("Ingredients").tag("Ingredients");Text("Cookware").tag("Cookware")}.pickerStyle(.segmented)
                HStack {Image(systemName:"magnifyingglass");TextField("Search your shelves",text:$query).accessibilityIdentifier("pantrySearch")}.padding(15).background(KitchenTheme.card,in:RoundedRectangle(cornerRadius:18))
                if section == "Ingredients" {
                    ScrollView(.horizontal,showsIndicators:false) {HStack {ForEach(["all","vegetable","meat","seafood","dairy","grain","legume","fruit","herb","spice","condiment","liquid"],id:\.self) {item in Chip(text:item.capitalized,selected:category == item) {category=item}}}}
                    LazyVGrid(columns:[GridItem(.adaptive(minimum:95),spacing:10)],spacing:10) {
                        ForEach(store.catalog.ingredients.filter { (category == "all" || $0.category == category || !query.isEmpty) && (query.isEmpty || $0.name.localizedCaseInsensitiveContains(query)) }) { ingredient in
                            let selected=store.data.pantry.ingredients.contains(ingredient.id)
                            Button {store.toggleIngredient(ingredient.id)} label: {
                                VStack(spacing:6) {FoodArt(id:ingredient.id,emoji:ingredient.emoji,size:60); Text(ingredient.name).font(.system(.caption,design:.rounded,weight:.semibold)).multilineTextAlignment(.center).lineLimit(2); Image(systemName:selected ? "checkmark.circle.fill":"plus.circle").foregroundStyle(selected ? KitchenTheme.sage:.secondary)}.frame(maxWidth:.infinity,minHeight:115).padding(8).background(selected ? KitchenTheme.sage.opacity(0.12):KitchenTheme.card,in:RoundedRectangle(cornerRadius:20)).overlay(RoundedRectangle(cornerRadius:20).stroke(selected ? KitchenTheme.sage:.clear,lineWidth:1.5))
                            }.buttonStyle(.plain).accessibilityLabel("\(ingredient.name), \(selected ? "in pantry":"add to pantry")").accessibilityIdentifier("ingredient-"+ingredient.id)
                        }
                    }
                } else {
                    LazyVGrid(columns:[GridItem(.adaptive(minimum:135))]) {ForEach(store.catalog.tools.filter {query.isEmpty || $0.name.localizedCaseInsensitiveContains(query)}) {tool in
                        Chip(text:(store.data.pantry.cookware.contains(tool.id) ? "✓ ":"+ ")+tool.name,selected:store.data.pantry.cookware.contains(tool.id)) {store.toggleTool(tool.id)}
                    }}
                }
                Divider().padding(.vertical,10)
                SectionTitle(title:"Tonight, sorted.",subtitle:"A happy little menu, made around your kitchen.")
                Picker("Matching mode",selection:$store.data.pantry.mode) {ForEach(MatchMode.allCases,id:\.self) {Text($0.rawValue.capitalized).tag($0)}}.pickerStyle(.segmented)
                Text(store.data.pantry.mode == .flexible ? "A short shopping list is fine." : store.data.pantry.mode == .exact ? "Every essential is already here." : "No shopping. Easy cooking. Under 30 minutes.").font(.caption).foregroundStyle(.secondary)
                Stepper("\(store.data.pantry.dishCount) dishes for the table",value:$store.data.pantry.dishCount,in:1...5)
                HStack {Button {withAnimation(.spring) {seed += 1}} label: {Label("Roll my menu",systemImage:"dice.fill")}.buttonStyle(KitchenButton()).accessibilityIdentifier("rollMenu"); Button {shopping=true} label: {Image(systemName:"basket").padding(17).background(KitchenTheme.card,in:RoundedRectangle(cornerRadius:18))}.accessibilityLabel("Shopping list")}
                if menu.isEmpty {ContentUnavailableView("A little more in the pantry?",systemImage:"carrot",description:Text("Add ingredients or try Flexible to find something delicious."))}
                ForEach(menu) {match in
                    PaperCard {HStack(alignment:.top) {Text(match.recipe.emoji).font(.largeTitle); VStack(alignment:.leading,spacing:6) {Button {selected=store.catalog.recipe(match.id)} label: {Text(match.recipe.title).font(KitchenTheme.display(22)).foregroundStyle(.primary).multilineTextAlignment(.leading)}.buttonStyle(.plain);Text("\(match.recipe.minutes) min · \(match.recipe.course.capitalized)").font(.caption).foregroundStyle(.secondary);Text(match.reason).font(.caption).foregroundStyle(KitchenTheme.sage)};Spacer(); Button {if locked.contains(match.id) {locked.removeAll {$0 == match.id}} else {locked.append(match.id)}} label: {Image(systemName:locked.contains(match.id) ? "pin.fill":"pin")}.accessibilityLabel("\(locked.contains(match.id) ? "Unpin":"Pin") \(match.recipe.title)")}}
                }
                Text("\(matches.count) recipes fit your kitchen").font(.subheadline).foregroundStyle(.secondary)
                ForEach(matches.prefix(12)) { match in Button {selected=store.catalog.recipe(match.id)} label: {HStack {Text(match.recipe.emoji); Text(match.recipe.title); Spacer(); Text("\(Int(match.coverage*100))%").foregroundStyle(KitchenTheme.sage)}}.buttonStyle(.plain).padding(.vertical,8) }
            }.padding(22).frame(maxWidth:960)
        }.frame(maxWidth:.infinity).kitchenBackground().navigationTitle("My kitchen").navigationBarTitleDisplayMode(.inline)
            .sheet(item:$selected) {RecipeDetailView(recipe:$0,edit:edit)}
            .sheet(isPresented:$shopping) {NavigationStack {List {if shoppingIDs.isEmpty {Label("You have everything for this menu!",systemImage:"checkmark.seal")};ForEach(shoppingIDs,id:\.self) {id in Button {if store.data.checkedShopping.contains(id) {store.data.checkedShopping.removeAll {$0 == id}} else {store.data.checkedShopping.append(id)}} label: {Label(store.catalog.ingredient(id)?.name ?? id,systemImage:store.data.checkedShopping.contains(id) ? "checkmark.circle.fill":"circle").strikethrough(store.data.checkedShopping.contains(id))}};ShareLink(item:shoppingIDs.map {store.catalog.ingredient($0)?.name ?? $0}.joined(separator:"\n")) {Label("Share shopping list",systemImage:"square.and.arrow.up")}}.navigationTitle("A little shopping list").toolbar {Button("Done") {shopping=false}}}}
    }
}
