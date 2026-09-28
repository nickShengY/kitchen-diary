import SwiftUI
import AuthenticationServices

struct DiaryView:View {
    @EnvironmentObject var store:KitchenStore
    @EnvironmentObject var account:AccountService
    var edit:(Recipe)->Void
    @State private var panel="Saved"
    @State private var selected:Recipe?
    @State private var settings=false
    @State private var membershipSheet=false
    @State private var deletingAccount=false
    var recipes:[Recipe] {
        switch panel {
        case "Cookbook":return store.data.cookbook
        case "History":return store.data.pantry.history.compactMap {id in store.allRecipes.first {$0.id==id || $0.id=="pantry-"+id}}
        case "Shared":return store.data.published
        default:return store.allRecipes.filter {store.isFavorite($0)}
        }
    }
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:24) {
                Eyebrow(title:"Small recipes. Lovely memories.")
                HStack(spacing:18) {Image("mascot").resizable().scaledToFit().frame(width:100,height:100).background(KitchenTheme.peach,in:Circle());VStack(alignment:.leading,spacing:8) {Text("Hello, \(account.name ?? store.data.displayName).").font(KitchenTheme.display(31));Text(account.name == nil ? "Your happy place for all things homemade.":"Your kitchen, across your devices.").font(.subheadline).foregroundStyle(.secondary)}}
                HStack {stat(store.data.pantry.history.count,"Cooked");stat(store.data.pantry.favorites.count,"Saved");stat(store.data.cookbook.count,"Recipes")}.padding(22).background(KitchenTheme.card,in:RoundedRectangle(cornerRadius:25))
                if account.name==nil {PaperCard {Text("Keep your kitchen close.").font(KitchenTheme.display(24));Text("Sign in to keep your pantry and recipe draft in sync across devices.").font(.subheadline).foregroundStyle(.secondary).padding(.vertical,8);Button {Task {await account.signIn(store:store,withApple:true)}} label: {Label("Continue with Apple",systemImage:"apple.logo")}.buttonStyle(.plain).font(.headline).frame(maxWidth:.infinity,minHeight:50).background(.black,in:RoundedRectangle(cornerRadius:12)).foregroundStyle(.white).disabled(account.busy).accessibilityIdentifier("appleSignIn");Button {Task {await account.signIn(store:store)}} label: {Label("Continue with Google",systemImage:"person.crop.circle.badge.checkmark")}.buttonStyle(KitchenButton()).disabled(account.busy)}}
                else {HStack {Label(account.syncStatus,systemImage:"icloud").font(.caption);Spacer();Button("Sync now") {Task {await account.sync(store:store)}}.disabled(account.busy)}}
                if let error=account.error {Text(error).font(.subheadline).foregroundStyle(KitchenTheme.coral)}
                if account.busy {ProgressView("Tending to your kitchen…")}
                ScrollView(.horizontal,showsIndicators:false) {HStack {ForEach(["Saved","Cookbook","History","Shared"],id:\.self) {item in Chip(text:item,selected:panel==item) {panel=item}}}}
                if recipes.isEmpty {ContentUnavailableView(panel=="History" ? "Your story starts at the stove":"A lovely place for your favourites",systemImage:panel=="History" ? "clock":"book.closed",description:Text(panel=="History" ? "Finish a cooking guide to add a memory.":"Save a recipe or create one of your own."))}
                LazyVGrid(columns:[GridItem(.adaptive(minimum:280))],spacing:20) {ForEach(recipes) {recipe in RecipeCard(recipe:recipe) {selected=recipe}.contextMenu {if store.data.cookbook.contains(where:{$0.id==recipe.id}) {Button("Delete from cookbook",role:.destructive) {store.data.cookbook.removeAll {$0.id==recipe.id}}};if panel=="Shared" {Button("Remove from feed",role:.destructive) {store.data.published.removeAll {$0.id==recipe.id}}}}}}
                PaperCard {Label("Your tiny kitchen companion",systemImage:"applewatch").font(.headline);Text("Spin with the Digital Crown, keep your next cooking step close, and check your timer without touching your phone.").font(.subheadline).foregroundStyle(.secondary).padding(.top,8);Text(store.watchStatus).font(.caption).foregroundStyle(KitchenTheme.sage).padding(.top,8)}
                Button("Kitchen Diary Pro") {membershipSheet=true}.buttonStyle(KitchenButton(secondary:true))
                if account.name != nil {Button("Sign out") {account.signOut(store:store)}}
            }.padding(22).frame(maxWidth:950)
        }.frame(maxWidth:.infinity).kitchenBackground().navigationTitle("My diary").navigationBarTitleDisplayMode(.inline).toolbar {Button {settings=true} label: {Image(systemName:"gearshape")}.accessibilityLabel("Settings")}
            .sheet(isPresented:$membershipSheet) {MembershipView()}
            .sheet(item:$selected) {RecipeDetailView(recipe:$0,edit:edit)}
            .sheet(isPresented:$settings) {NavigationStack {Form {Section("A little about you") {TextField("Your name",text:$store.data.displayName)};Section("Privacy & support") {Link("Privacy policy",destination:AppLinks.privacy).accessibilityIdentifier("privacyPolicy");Link("Terms of use",destination:AppLinks.terms);Link("Contact support",destination:AppLinks.support);Text("Pantry, drafts, saved recipes and cooking history are stored on this device. Signing in syncs pantry and drafts to your existing Firebase account. Menu text recognition stays on your device.")};Section("Subscription") {Text(account.entitlement);if account.name != nil {Button("Refresh membership") {Task {await account.refreshEntitlement()}}};Text("Apple subscriptions are managed separately from existing web memberships. Open Premium from your Diary to see available plans.").font(.caption)};if account.name != nil {Section("Account") {Button("Delete account",role:.destructive) {deletingAccount=true}.disabled(account.busy).accessibilityIdentifier("deleteAccount");Text("Permanently remove your Kitchen Diary account and its cloud data. Apple subscriptions continue until you cancel them in your Apple account.").font(.caption)}};Section("Kitchen Diary") {Text("Native SwiftUI · iPhone, iPad & Apple Watch");Text("Version \(Bundle.main.object(forInfoDictionaryKey:"CFBundleShortVersionString") as? String ?? "1.0")")}}.confirmationDialog("Delete your Kitchen Diary account?",isPresented:$deletingAccount,titleVisibility:.visible) {Button("Delete account and data",role:.destructive) {Task {await account.deleteAccount(store:store)}}} message: {Text("This permanently removes your account and cloud data across Kitchen Diary apps. You’ll sign in again to confirm. Cancel your Apple subscription separately; deleting an account does not cancel billing.")} .navigationTitle("Make yourself at home").toolbar {Button("Done") {settings=false}}}}
            .task {await account.restore(store:store)}
    }
    func stat(_ count:Int,_ label:String)->some View {VStack(spacing:6) {Text("\(count)").font(KitchenTheme.display(29));Text(label.uppercased()).font(.caption2.bold()).tracking(1).foregroundStyle(.secondary)}.frame(maxWidth:.infinity)}
}
