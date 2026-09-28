import SwiftUI

struct CookingView: View {
    @EnvironmentObject var store:KitchenStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var bounce=false
    @State private var complete=false
    @State private var customMinutes=5
    var body:some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:25) {
                    if let session=store.data.session,let step=session.step {
                        Eyebrow(title:"Hands busy. Heart happy.")
                        HStack {Text(session.recipe.title).font(KitchenTheme.display(28));Spacer();Label("\(session.stepIndex+1) / \(session.recipe.steps.count)",systemImage:"list.bullet").font(.caption.bold())}
                        ProgressView(value:Double(session.stepIndex+1),total:Double(session.recipe.steps.count)).tint(KitchenTheme.coral)
                        ZStack {
                            RoundedRectangle(cornerRadius:36).fill(step.station=="cook" ? KitchenTheme.peach:KitchenTheme.sage.opacity(0.12))
                            ActionAnimation(action:step.actionId,reducedMotion:reduceMotion).padding(20)
                            VStack {HStack {Spacer();Text(step.station=="cook" ? "🔥":step.station=="finish" ? "✨":"🌿").font(.system(size:40)).padding(24)};Spacer();Text((store.catalog.actions.first {$0.id==step.actionId}?.verb ?? step.actionId).uppercased()).font(.caption.bold()).tracking(4).foregroundStyle(.black.opacity(0.65)).padding(24)}
                        }.frame(height:270).accessibilityHidden(true)
                        Eyebrow(title:step.station=="prep" ? "The prep station":step.station=="cook" ? "A little heat":"The finishing touch")
                        Text(step.notes?.isEmpty==false ? step.notes!:store.catalog.actions.first {$0.id==step.actionId}?.name ?? step.actionId.capitalized).font(KitchenTheme.display(30)).accessibilityIdentifier("cookingInstruction")
                        if !step.ingredients.isEmpty {PaperCard {ForEach(step.ingredients) {item in HStack {Text(store.catalog.ingredient(item.id)?.emoji ?? "•");Text(store.catalog.ingredient(item.id)?.name ?? item.id);Spacer();Text("\(item.amount) \(item.unit)").foregroundStyle(.secondary)}.font(.subheadline).padding(.vertical,4)}}}
                        if let settings=step.settings,!settings.isEmpty {Text(settings.sorted(by:{$0.key<$1.key}).map {"\($0.key.capitalized): \($0.value)"}.joined(separator:"  ·  ")).font(.subheadline).foregroundStyle(KitchenTheme.sage)}
                        timer(session)
                        Label("Follow along on your paired Apple Watch.",systemImage:"applewatch").font(.caption).foregroundStyle(.secondary)
                        HStack {Button {store.moveStep(-1)} label: {Label("Back",systemImage:"arrow.left")}.buttonStyle(KitchenButton(secondary:true)).disabled(session.stepIndex==0);Button {if session.stepIndex==session.recipe.steps.count-1 {store.completeCooking();complete=true} else {store.moveStep(1)}} label: {Label(session.stepIndex==session.recipe.steps.count-1 ? "All done!":"Next step",systemImage:session.stepIndex==session.recipe.steps.count-1 ? "checkmark":"arrow.right")}.buttonStyle(KitchenButton()).accessibilityIdentifier("nextCookingStep")}
                    } else if complete {
                        VStack(spacing:25) {Text("🎉").font(.system(size:95));Text("You made something lovely.").font(KitchenTheme.display(36)).multilineTextAlignment(.center);Text("Another happy page in your kitchen diary.").foregroundStyle(.secondary);Button("Bon appétit!") {dismiss()}.buttonStyle(KitchenButton())}.padding(.vertical,70)
                    } else {ContentUnavailableView("Your kitchen is ready",systemImage:"fork.knife",description:Text("Open a recipe to start cooking."))}
                }.padding(24).frame(maxWidth:750)
            }.frame(maxWidth:.infinity).kitchenBackground().navigationBarTitleDisplayMode(.inline).toolbar {ToolbarItem(placement:.topBarTrailing) {Button("Minimize") {dismiss()}}}
        }
        .onAppear {UIApplication.shared.isIdleTimerDisabled=true;if !reduceMotion {withAnimation(.easeInOut(duration:1.8).repeatForever(autoreverses:true)) {bounce=true}}}
        .onDisappear {UIApplication.shared.isIdleTimerDisabled=false}
    }
    @ViewBuilder func timer(_ session:CookingSession)->some View {
        PaperCard {
            TimelineView(.periodic(from:.now,by:1)) {context in
                let remaining=session.remaining(at:context.date)
                HStack {Image(systemName:"timer").foregroundStyle(KitchenTheme.coral);Text(session.timerEnd != nil || session.pausedSeconds != nil ? String(format:"%02d:%02d",remaining/60,remaining%60):"Your cooking timer").font(.system(.title2,design:.rounded,weight:.bold)).monospacedDigit().accessibilityIdentifier("timerRemaining");Spacer();if session.timerEnd != nil && remaining>0 {Button("Pause") {store.pauseTimer()}} else {Button(session.pausedSeconds != nil ? "Resume":"Start") {store.startTimer(seconds:session.pausedSeconds ?? ((session.step?.durationSeconds ?? 0)>0 ? session.step!.durationSeconds:customMinutes*60))}.accessibilityIdentifier("startTimer")}}
                if session.timerEnd != nil && remaining==0 {Text("Time’s up — check your dish.").font(.subheadline.bold()).foregroundStyle(KitchenTheme.coral)}
            }
            if session.timerEnd==nil && session.pausedSeconds==nil && session.step?.durationSeconds==0 {Stepper("\(customMinutes) minutes",value:$customMinutes,in:1...180).font(.subheadline).padding(.top,8)}
        }
    }
}
