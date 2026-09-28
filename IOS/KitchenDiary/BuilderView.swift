import SwiftUI

struct BuilderView: View {
    @EnvironmentObject var store:KitchenStore
    @State private var step:RecipeStep?
    @State private var cooking=false
    @State private var saved=false
    @State private var publishing=false
    @State private var reset=false
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:24) {
                Eyebrow(title:"Made by you, one little step at a time")
                SectionTitle(title:"Your recipe studio",subtitle:"A pinch of imagination. A recipe worth keeping.")
                PaperCard {
                    TextField("Give your recipe a name",text:$store.data.draft.title).font(KitchenTheme.display(28)).accessibilityIdentifier("recipeTitle")
                    TextField("What makes it special?",text:Binding(get:{store.data.draft.description ?? ""},set:{store.data.draft.description=$0}),axis:.vertical).font(.subheadline).padding(.top,8)
                    TextField("Tags, separated by commas",text:Binding(get:{store.data.draft.tags.joined(separator:", ")},set:{store.data.draft.tags=$0.components(separatedBy:",").map {$0.trimmingCharacters(in:.whitespaces)}.filter {!$0.isEmpty}})).font(.caption).padding(.top,8)
                }
                HStack {Text("The cooking story").font(KitchenTheme.display(25));Spacer();Text("\(store.data.draft.steps.count) steps").font(.caption).foregroundStyle(.secondary)}
                if store.data.draft.steps.isEmpty {
                    VStack(spacing:16) {Image("mascot").resizable().scaledToFit().frame(height:150); Text("Every delicious thing\nstarts with a little step.").font(KitchenTheme.display(25)).multilineTextAlignment(.center);Text("Choose ingredients, pick an action, make it yours.").font(.subheadline).foregroundStyle(.secondary)}.frame(maxWidth:.infinity).padding(.vertical,20)
                }
                ForEach(Array(store.data.draft.steps.enumerated()),id:\.element.id) {index,item in
                    PaperCard {
                        HStack(alignment:.top,spacing:16) {Text(String(format:"%02d",index+1)).font(KitchenTheme.display(30)).foregroundStyle(KitchenTheme.coral);VStack(alignment:.leading,spacing:9) {Eyebrow(title:item.station);Text(store.catalog.actions.first {$0.id == item.actionId}?.name ?? item.actionId.capitalized).font(.headline);Text(item.notes ?? "").font(.subheadline).foregroundStyle(.secondary);ScrollView(.horizontal,showsIndicators:false) {HStack {ForEach(item.ingredients) {i in FoodArt(id:i.id,emoji:store.catalog.ingredient(i.id)?.emoji ?? "🥣",size:42)}}};HStack {Button("Edit") {step=item};Spacer();Button {move(index,-1)} label: {Image(systemName:"arrow.up")}.disabled(index==0).accessibilityLabel("Move step up");Button {move(index,1)} label: {Image(systemName:"arrow.down")}.disabled(index==store.data.draft.steps.count-1).accessibilityLabel("Move step down");Button(role:.destructive) {store.data.draft.steps.removeAll {$0.id==item.id}} label: {Image(systemName:"trash")}.accessibilityLabel("Delete step")}.font(.subheadline)}}
                    }
                }
                Button {step=RecipeStep()} label: {Label("Add a little step",systemImage:"plus")}.buttonStyle(KitchenButton(secondary:true)).accessibilityIdentifier("addStep")
                HStack {Button {store.saveDraft();saved=true} label: {Label("Save recipe",systemImage:"bookmark")}.buttonStyle(KitchenButton(secondary:true));Button {store.startCooking(store.data.draft);cooking=true} label: {Label("Cook",systemImage:"play.fill")}.buttonStyle(KitchenButton())}.disabled(store.data.draft.steps.isEmpty || store.data.draft.title.trimmingCharacters(in:.whitespaces).isEmpty)
                if !store.data.draft.steps.isEmpty {HStack {ShareLink(item:store.data.draft.shareText) {Label("Share",systemImage:"square.and.arrow.up")};Spacer();Button("Add to my feed") {publishing=true}}.padding(.vertical)}
                Text("Draft saved automatically on this device.").font(.caption).foregroundStyle(.secondary).frame(maxWidth:.infinity)
            }.padding(22).frame(maxWidth:800)
        }.frame(maxWidth:.infinity).kitchenBackground().navigationTitle("Create").navigationBarTitleDisplayMode(.inline)
            .toolbar {Button("New recipe") {reset=true}}
            .sheet(item:$step) {item in StepEditor(step:item) {updated in if let index=store.data.draft.steps.firstIndex(where:{$0.id==updated.id}) {store.data.draft.steps[index]=updated} else {store.data.draft.steps.append(updated)}}}
            .fullScreenCover(isPresented:$cooking) {CookingView()}
            .alert("Tucked into your cookbook",isPresented:$saved) {Button("Lovely",role:.cancel){}} message:{Text("You’ll find it in your Diary.")}
            .confirmationDialog("Add this recipe to your local feed?",isPresented:$publishing,titleVisibility:.visible) {Button("Add to my feed") {store.publishDraft();saved=true}} message:{Text("Like the React app, this feed is stored on this device. Use Share to send the recipe to someone.")}
            .confirmationDialog("Start a new recipe?",isPresented:$reset,titleVisibility:.visible) {Button("Save and start fresh") {if !store.data.draft.steps.isEmpty {store.saveDraft()};store.data.draft=Recipe(title:"My little masterpiece")}}
    }
    func move(_ index:Int,_ delta:Int) {store.data.draft.steps.swapAt(index,index+delta)}
}
struct StepEditor:View {
    @EnvironmentObject var store:KitchenStore
    @Environment(\.dismiss) var dismiss
    @State var step:RecipeStep
    var save:(RecipeStep)->Void
    @State private var query=""
    @State private var stage=0
    var availableActions:[CookingAction] {
        let properties=Set(step.ingredients.flatMap {store.catalog.ingredient($0.id)?.physicalProperties ?? []})
        return store.catalog.actions.filter {action in guard let valid=action.validProperties,!valid.isEmpty else {return true};return valid.contains {properties.contains($0)}}
    }
    var body:some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:22) {
                    HStack {ForEach(0..<3) {i in Capsule().fill(i<=stage ? KitchenTheme.coral:Color.secondary.opacity(0.15)).frame(height:5)}}
                    SectionTitle(title:["First, the ingredients","A little kitchen magic","Make it just right"][stage],subtitle:["Tap what goes into this step.","How shall we bring these together?","The little details make all the difference."][stage])
                    if stage==0 {ingredients}
                    if stage==1 {actions}
                    if stage==2 {details}

                }.padding(22).frame(maxWidth:740)
            }.frame(maxWidth:.infinity).kitchenBackground().navigationTitle("Recipe step").navigationBarTitleDisplayMode(.inline).toolbar {Button("Cancel") {dismiss()}}
            .safeAreaInset(edge:.bottom) { HStack { if stage>0 { Button("Back") {stage -= 1}.padding(.horizontal) }; Button(stage==2 ? "Save this step":"Next little step") {if stage==2 {save(step);dismiss()} else {stage += 1}}.buttonStyle(KitchenButton()).disabled(stage==0 && step.ingredients.isEmpty).accessibilityIdentifier("stepNext") }.padding(16).background(.regularMaterial) }
        }
    }
    var ingredients:some View {
        VStack(alignment:.leading,spacing:16) {
            TextField("Find an ingredient",text:$query).textFieldStyle(.roundedBorder).accessibilityIdentifier("stepIngredientSearch")
            ForEach($step.ingredients) {$item in HStack {Text(store.catalog.ingredient(item.id)?.name ?? item.id).font(.subheadline);Spacer();TextField("Amount",text:$item.amount).frame(width:65).textFieldStyle(.roundedBorder).keyboardType(.decimalPad);TextField("Unit",text:$item.unit).frame(width:60).textFieldStyle(.roundedBorder)}}
            LazyVGrid(columns:[GridItem(.adaptive(minimum:90))]) {ForEach(store.catalog.ingredients.filter {query.isEmpty || $0.name.localizedCaseInsensitiveContains(query)}) {ingredient in
                let selected=step.ingredients.contains {$0.id==ingredient.id}
                Button {if selected {step.ingredients.removeAll {$0.id==ingredient.id}} else {step.ingredients.append(StepIngredient(id:ingredient.id,amount:"1",unit:ingredient.defaultUnit))}} label: {VStack {FoodArt(id:ingredient.id,emoji:ingredient.emoji,size:58);Text(ingredient.name).font(.caption).lineLimit(2);Image(systemName:selected ? "checkmark.circle.fill":"plus.circle")}.frame(maxWidth:.infinity,minHeight:100).padding(8).background(selected ? KitchenTheme.sage.opacity(0.15):KitchenTheme.card,in:RoundedRectangle(cornerRadius:18))}.buttonStyle(.plain).accessibilityIdentifier("stepIngredient-"+ingredient.id)
            }}
        }
    }
    var actions:some View {
        LazyVGrid(columns:[GridItem(.adaptive(minimum:125))]) {ForEach(availableActions) {action in
            Button {step.actionId=action.id;if let tool=action.requiresToolId {step.toolId=tool};let type=store.catalog.tools.first {$0.id==step.toolId}?.type;step.station=type=="cook" || type=="appliance" ? "cook":type=="finish" ? "finish":"prep"} label: {VStack(spacing:10) {Text(action.icon).font(.largeTitle);Text(action.name).font(.subheadline.bold())}.frame(maxWidth:.infinity,minHeight:100).padding(10).background(step.actionId==action.id ? KitchenTheme.peach:KitchenTheme.card,in:RoundedRectangle(cornerRadius:20)).foregroundStyle(step.actionId==action.id ? .black:.primary)}.buttonStyle(.plain).accessibilityIdentifier("action-"+action.id)
        }}
    }
    var details:some View {
        VStack(alignment:.leading,spacing:18) {
            Picker("Station",selection:$step.station) {Text("Prep").tag("prep");Text("Heat").tag("cook");Text("Plate").tag("finish")}.pickerStyle(.segmented)
            Picker("Kitchen tool",selection:$step.toolId) {ForEach(store.catalog.tools) {Text($0.name).tag($0.id)}}
            settingPicker("Temperature",key:"temperature",values:store.catalog.temperatures)
            settingPicker("Duration",key:"duration",values:store.catalog.times)
            settingPicker("Water level",key:"waterLevel",values:store.catalog.waterLevels)
            settingPicker("Cut shape",key:"cutShape",values:store.catalog.cutShapes.map(\.label))
            settingPicker("Method",key:"cookMethod",values:store.catalog.cookMethods.map(\.label))
            ForEach(["speed","oil","liquid","garnish","texture"],id:\.self) {key in TextField(key.capitalized,text:setting(key)).textFieldStyle(.roundedBorder)}
            TextField("Tell the cooking story…",text:Binding(get:{step.notes ?? ""},set:{step.notes=$0}),axis:.vertical).lineLimit(3...6).padding(15).background(KitchenTheme.card,in:RoundedRectangle(cornerRadius:18)).accessibilityIdentifier("stepNotes")
        }
    }
    func setting(_ key:String)->Binding<String> {Binding(get:{step.settings?[key] ?? ""},set:{if step.settings==nil {step.settings=[:]};if $0.isEmpty {step.settings?.removeValue(forKey:key)} else {step.settings?[key]=$0}})}
    func settingPicker(_ title:String,key:String,values:[String])->some View {Picker(title,selection:setting(key)) {Text("Not set").tag("");ForEach(values,id:\.self) {Text($0).tag($0)}}}
}
