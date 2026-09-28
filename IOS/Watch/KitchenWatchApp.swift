import SwiftUI
import WatchKit

@main struct KitchenWatchApp:App {
    @StateObject private var store=KitchenStore()
    var body:some Scene {WindowGroup {WatchHome().environmentObject(store).tint(.orange)}}
}
struct WatchHome:View {
    @EnvironmentObject var store:KitchenStore
    @State private var page = ProcessInfo.processInfo.arguments.contains("-watch-handoff-test") ? 1 : 0
    var body:some View {TabView(selection:$page) {WatchWheel().tag(0);WatchCook().tag(1)}.tabViewStyle(.verticalPage)}
}
struct WatchWheel:View {
    @EnvironmentObject var store:KitchenStore
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var crown=0.0
    @State private var rotation=0.0
    @State private var cuisine:Cuisine?
    @State private var result:String?
    @State private var spinning=false
    @State private var focused=false
    var labels:[String] {cuisine?.dishes ?? store.data.cuisines.map(\.name)}
    var body:some View {
        GeometryReader { geometry in
            VStack(spacing:5) {
                HStack(spacing:4) {
                    if cuisine != nil { Button { cuisine=nil;crown=0;rotation=0;result=nil } label: { Image(systemName:"chevron.left") }.buttonStyle(.plain).disabled(spinning).accessibilityLabel("All cuisines") }
                    Text(cuisine?.name ?? "A little dinner luck").font(.system(.headline,design:.rounded)).lineLimit(1).minimumScaleFactor(0.7)
                }
                FoodWheel(labels:labels.count>12 ? labels.map {_ in ""}:labels,rotation:rotation+crown)
                    .frame(width:min(110,geometry.size.height*0.48),height:min(110,geometry.size.height*0.48))
                    .focusable(!spinning).digitalCrownRotation($crown,from:0,through:3600,by:8,sensitivity:.medium,isContinuous:true,isHapticFeedbackEnabled:true)
                    .accessibilityHint("Turn the Digital Crown to choose. Tap Spin for a surprise.")
                    .onChange(of:crown) {_,value in if !spinning,let index=WheelMath.winner(rotation:rotation+value,count:labels.count),labels.indices.contains(index) {result=labels[index]} }
                Text(result ?? "Twist the crown. Find your flavour.").font(.system(.caption,design:.rounded,weight:.semibold)).multilineTextAlignment(.center).lineLimit(2).frame(height:30).foregroundStyle(result == nil ? .white.opacity(0.6):.orange).accessibilityIdentifier("watchWheelResult")
                HStack(spacing:7) {
                    Button {spin()} label: {Text(spinning ? "Picking…":"Spin").font(.caption.bold()).frame(maxWidth:.infinity,minHeight:35).background(.orange,in:Capsule()).foregroundStyle(.black)}.buttonStyle(.plain).disabled(spinning || labels.isEmpty).accessibilityIdentifier("watchSpin")
                    if let result,cuisine==nil,let picked=store.data.cuisines.first(where:{$0.name==result}) {
                        Button {cuisine=picked;crown=0;rotation=0;self.result=nil} label: {Text("Pick a dish").font(.caption.bold()).lineLimit(1).minimumScaleFactor(0.75).frame(maxWidth:.infinity,minHeight:35).background(.white.opacity(0.15),in:Capsule())}.buttonStyle(.plain).disabled(spinning).accessibilityIdentifier("watchPickDish")
                    }
                }
            }.frame(maxWidth:.infinity,maxHeight:.infinity)
        }.containerBackground(Color(red:0.12,green:0.08,blue:0.065).gradient,for:.tabView)
    }
    func spin() {
        guard !spinning,!labels.isEmpty else {return};spinning=true;result=nil
        let items=labels,index=Int.random(in:0..<labels.count),start=rotation+crown
        rotation=start;crown=0
        WKInterfaceDevice.current().play(.click)
        withAnimation(.easeOut(duration:reduceMotion ? 0.2:2)) {rotation=WheelMath.targetRotation(current:start,index:index,count:items.count,turns:3)}
        Task {try? await Task.sleep(for:.seconds(reduceMotion ? 0.25:2.1));result=items[index];spinning=false;WKInterfaceDevice.current().play(.success)}
    }
}
struct WatchCook:View {
    @EnvironmentObject var store:KitchenStore
    var body:some View {
        ScrollView {
            if let session=store.data.session,let step=session.step {
                VStack(alignment:.leading,spacing:12) {
                    Text(session.recipe.title).font(.headline).foregroundStyle(.orange)
                    ProgressView(value:Double(session.stepIndex+1),total:Double(session.recipe.steps.count))
                    Text("STEP \(session.stepIndex+1) OF \(session.recipe.steps.count) · \(step.station.uppercased())").font(.caption2).foregroundStyle(.secondary)
                    Text(step.notes?.isEmpty==false ? step.notes!:step.actionId.capitalized).font(.system(.body,design:.rounded)).accessibilityIdentifier("watchInstruction")
                    ForEach(step.ingredients) {item in Text("\(item.amount) \(item.unit) \(store.catalog.ingredient(item.id)?.name ?? item.id)").font(.caption2).foregroundStyle(.secondary)}
                    if let settings=step.settings {ForEach(settings.keys.sorted(),id:\.self) {key in Text("\(key.capitalized): \(settings[key] ?? "")").font(.caption2)}}
                    TimelineView(.periodic(from:.now,by:1)) {context in let remaining=session.remaining(at:context.date)
                        if session.timerEnd != nil || session.pausedSeconds != nil {Text(String(format:"%02d:%02d",remaining/60,remaining%60)).font(.system(.title,design:.rounded,weight:.bold)).monospacedDigit()}
                        if session.timerEnd != nil && remaining>0 {Button("Pause timer") {store.pauseTimer()}} else {Button(session.pausedSeconds != nil ? "Resume timer":"Start timer") {store.startTimer(seconds:session.pausedSeconds ?? (step.durationSeconds>0 ? step.durationSeconds:300))}}
                    }
                    Button(session.stepIndex==session.recipe.steps.count-1 ? "Finish cooking":"Next step") {WKInterfaceDevice.current().play(.click);if session.stepIndex==session.recipe.steps.count-1 {store.completeCooking()} else {store.moveStep(1)}}.buttonStyle(.borderedProminent).accessibilityIdentifier("watchNextStep")
                    if session.stepIndex>0 {Button("Previous step") {store.moveStep(-1)}}
                }
            } else {
                VStack(spacing:14) {Text("🥣").font(.system(size:50));Text("Your wrist-side sous-chef").font(.system(.title3,design:.rounded,weight:.bold)).multilineTextAlignment(.center);Text("Start a recipe on your iPhone. Your steps and timer will appear here.").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center);Button("Try a cooking guide") {if let recipe=store.catalog.convertedRecipes.first {store.startCooking(recipe)}}.accessibilityIdentifier("watchDemoCooking")}
            }
        }.containerBackground(Color(red:0.12,green:0.08,blue:0.065).gradient,for:.tabView)
    }
}
