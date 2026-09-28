import SwiftUI
import PhotosUI
import Vision

struct DeciderView:View {
    @EnvironmentObject var store:KitchenStore
    @EnvironmentObject var membership:MembershipStore
    @EnvironmentObject var account:AccountService
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var cuisine:Cuisine?
    @State private var result:String?
    @State private var rotation=0.0
    @State private var spinning=false
    @State private var editing=false
    @State private var mode="Wheel"
    @State private var photo:PhotosPickerItem?
    @State private var scanning=false
    @State private var scanText=""
    @State private var scanItems:[String]=[]
    @State private var scanError:String?
    @State private var showingRecipe:Recipe?
    @State private var searching=false
    @State private var showPro=false
    var canScan:Bool {membership.active || account.hasPro}
    var labels:[String] {mode=="Menu" ? scanItems:cuisine?.dishes ?? store.data.cuisines.map(\.name)}
    var body:some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(alignment:.leading,spacing:24) {
                Eyebrow(title:"Less deciding. More delicious.")
                SectionTitle(title:"Let a little luck cook.",subtitle:"Sometimes the best plan is a happy surprise.")
                Picker("Decider mode",selection:$mode) {Text("Spin the wheel").tag("Wheel");Text("Scan a menu").tag("Menu")}.pickerStyle(.segmented).disabled(spinning).onChange(of:mode) {_,_ in reset()}
                if mode=="Menu" {scanner}
                HStack {Text(cuisine.map {"\($0.emoji) \($0.name)"} ?? (mode=="Menu" ? "Your menu picks":"A world of flavour")).font(KitchenTheme.display(24));Spacer();if cuisine != nil {Button("All cuisines") {cuisine=nil;reset()}.disabled(spinning)} else if mode=="Wheel" {Button {editing=true} label: {Image(systemName:"slider.horizontal.3")}.accessibilityLabel("Customize wheel").disabled(spinning)}}
                if labels.isEmpty {ContentUnavailableView("A wheel needs a few ideas",systemImage:"sparkles",description:Text("Add dishes to start your delicious little lottery."))}
                else {
                    FoodWheel(labels:labels,rotation:rotation).padding(14).frame(maxWidth:430).frame(maxWidth:.infinity).shadow(color:KitchenTheme.coral.opacity(0.13),radius:25,y:15)
                    Button {spin()} label: {Label(spinning ? "A little suspense…":cuisine==nil && mode=="Wheel" ? "Spin a cuisine":"Pick my dish",systemImage:"sparkles")}.buttonStyle(KitchenButton()).disabled(spinning).accessibilityIdentifier("spinWheel")
                }
                if let result {
                    PaperCard(color:KitchenTheme.sage.opacity(0.10)) {
                        Eyebrow(title:"The universe says…")
                        Text(result).font(KitchenTheme.display(32)).padding(.vertical,8).accessibilityIdentifier("wheelResult")
                        if mode=="Wheel",cuisine==nil {Button("Now pick a dish →") {cuisine=store.data.cuisines.first {$0.name==result};reset()}.font(.headline).accessibilityIdentifier("pickDish")}
                        else {Button {Task {await findRecipe(result)}} label: {HStack {Text("Find a recipe");if searching {ProgressView()} else {Image(systemName:"arrow.up.right")}}}.disabled(searching)}
                    }.transition(.scale(scale:0.95).combined(with:.opacity)).id("wheelResultCard")
                }
                if let scanError {Text(scanError).font(.subheadline).foregroundStyle(.secondary)}
                Label("A quick twist of the crown works on Apple Watch.",systemImage:"applewatch").font(.caption).foregroundStyle(.secondary)
                if !store.data.wheelHistory.isEmpty {Text("Little lucky picks").font(KitchenTheme.display(23));Text(store.data.wheelHistory.prefix(6).joined(separator:"  ·  ")).font(.subheadline).foregroundStyle(.secondary)}
            }.padding(24).frame(maxWidth:700)
        }.onChange(of:result) {_,value in if value != nil {withAnimation(reduceMotion ? nil:.easeOut) {proxy.scrollTo("wheelResultCard",anchor:.bottom)}}}
        }.frame(maxWidth:.infinity).kitchenBackground().navigationTitle("The dinner decider").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented:$showPro) {MembershipView()}
            .task {await membership.refresh()}
            .sheet(isPresented:$editing) {WheelEditor()}
            .sheet(item:$showingRecipe) {RecipeDetailView(recipe:$0,edit:{store.data.draft=$0})}
            .onChange(of:photo) {_,item in Task {await scan(item)}}
    }
    var scanner:some View {
        PaperCard {
            Text("A menu, a little magic.").font(KitchenTheme.display(24))
            Text("Choose a photo. Text is read privately on your device. Review the dish names before spinning.").font(.subheadline).foregroundStyle(.secondary).padding(.vertical,8)
            if canScan {PhotosPicker(selection:$photo,matching:.images) {Label(scanning ? "Reading your menu…":"Choose menu photo",systemImage:"camera.viewfinder")}.disabled(scanning).accessibilityIdentifier("menuPhotoPicker")} else {Button {showPro=true} label: {Label("Unlock menu recognition with Pro",systemImage:"sparkles")}.accessibilityIdentifier("unlockMenuRecognition");Text("Typing your dishes below is always free.").font(.caption).foregroundStyle(.secondary)}
            TextField("Or type dishes, one per line",text:$scanText,axis:.vertical).accessibilityIdentifier("menuDishes").lineLimit(3...8).textFieldStyle(.roundedBorder).padding(.vertical,10)
            Button("Use these dishes") {scanItems=Array(NSOrderedSet(array:scanText.components(separatedBy:.newlines).map {$0.trimmingCharacters(in:.whitespaces)}.filter {!$0.isEmpty && $0.count<120}).array as? [String] ?? []).prefix(20).map {$0};reset()}.disabled(scanText.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
        }
    }
    func reset() {result=nil;rotation=0;scanError=nil}
    func spin() {
        guard !spinning,!labels.isEmpty else {return}
        let snapshot=labels,index=Int.random(in:0..<labels.count)
        spinning=true;result=nil
        UIImpactFeedbackGenerator(style:.medium).impactOccurred()
        withAnimation(reduceMotion ? .easeOut(duration:0.2):.timingCurve(0.12,0.75,0.15,1,duration:3.4)) {rotation=WheelMath.targetRotation(current:rotation,index:index,count:snapshot.count)}
        Task {try? await Task.sleep(for:.seconds(reduceMotion ? 0.25:3.5));withAnimation {result=snapshot[index];spinning=false};store.data.wheelHistory.insert(snapshot[index],at:0);store.data.wheelHistory=Array(store.data.wheelHistory.prefix(20));UINotificationFeedbackGenerator().notificationOccurred(.success)}
    }
    func scan(_ item:PhotosPickerItem?) async {
        guard let item else {return}
        await membership.refresh()
        if !membership.active {await account.refreshEntitlement()}
        guard canScan else {photo=nil;showPro=true;return}
        scanning=true;scanError=nil
        do {
            guard let data=try await item.loadTransferable(type:Data.self) else {throw URLError(.cannotDecodeContentData)}
            let lines=try await Task.detached(priority:.userInitiated) {
                try MenuRecognition.lines(from:data)
            }.value
            scanText=lines.joined(separator:"\n");if lines.isEmpty {scanError="No text found. Try a clearer photo or enter the dishes below."}
        } catch {scanError="That photo couldn’t be read. Try another image or type your choices."}
        scanning=false
    }
    func findRecipe(_ title:String) async {
        searching=true
        if let local=store.allRecipes.first(where:{$0.title.localizedCaseInsensitiveContains(title) || title.localizedCaseInsensitiveContains($0.title)}) {showingRecipe=local}
        else if !MealService.isAvailable {scanError="No matching recipe in your cookbook yet. Create your own version in the recipe builder."}
        else {do {if let recipe=try await MealService.search(title).first {showingRecipe=recipe} else {scanError="No exact recipe found. Try another spin or create your own version."}} catch {scanError="The online recipe book is unavailable. Try again when connected."}}
        searching=false
    }
}
struct WheelEditor:View {
    @EnvironmentObject var store:KitchenStore
    @Environment(\.dismiss) var dismiss
    @State private var name=""
    var body:some View {
        NavigationStack {List {
            Section("Your cuisines") {ForEach($store.data.cuisines) {$cuisine in NavigationLink(cuisine.emoji+" "+cuisine.name) {CuisineEditor(cuisine:$cuisine)}}.onDelete {store.data.cuisines.remove(atOffsets:$0)}}
            Section("Add a cuisine") {TextField("Name",text:$name);Button("Add cuisine") {store.data.cuisines.append(Cuisine(id:UUID().uuidString,name:name.trimmingCharacters(in:.whitespaces),emoji:"🍽️",dishes:[]));name=""}.disabled(name.trimmingCharacters(in:.whitespaces).isEmpty)}
            Button("Restore original cuisines") {store.data.cuisines=store.catalog.cuisines}
        }.navigationTitle("Your wheel, your rules").toolbar {Button("Done") {store.synchronize();dismiss()}}}
    }
}
struct CuisineEditor:View {
    @Binding var cuisine:Cuisine
    @State private var dish=""
    var body:some View {List {TextField("Cuisine name",text:$cuisine.name);Section("Dishes") {ForEach(Array(cuisine.dishes.enumerated()),id:\.offset) {_,name in Text(name)}.onDelete {cuisine.dishes.remove(atOffsets:$0)};TextField("New dish",text:$dish);Button("Add dish") {let value=dish.trimmingCharacters(in:.whitespaces);if !cuisine.dishes.contains(value) {cuisine.dishes.append(value)};dish=""}.disabled(dish.trimmingCharacters(in:.whitespaces).isEmpty)}}.navigationTitle(cuisine.name)}
}


enum MenuRecognition {
    static func lines(from data:Data) throws -> [String] {
        let request=VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection=true
        try VNImageRequestHandler(data:data).perform([request])
        return (request.results ?? []).compactMap {$0.topCandidates(1).first?.string}
    }
}
