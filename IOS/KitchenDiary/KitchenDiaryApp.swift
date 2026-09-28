import SwiftUI
import GoogleSignIn

@main struct KitchenDiaryApp: App {
    @StateObject private var membership = MembershipStore()
    @StateObject private var account = AccountService()
    @StateObject private var store: KitchenStore
    init() {
        AccountService.configure()
        if ProcessInfo.processInfo.arguments.contains("-ui-testing-reset") { UserDefaults.standard.removeObject(forKey:"kitchen.native.v1") }
        #if DEBUG
        let arguments=ProcessInfo.processInfo.arguments
        let watchEnabled = !arguments.contains("-ui-testing-reset") || arguments.contains("-ui-testing-watch")
        _store = StateObject(wrappedValue:KitchenStore(connectWatch:watchEnabled))
        #else
        _store = StateObject(wrappedValue:KitchenStore())
        #endif
    }
    var body: some Scene { WindowGroup { RootView().environmentObject(store).environmentObject(account).environmentObject(membership).tint(KitchenTheme.coral) } }
}
enum KitchenTab: String, CaseIterable, Identifiable {
    case explore = "Explore", pantry = "Kitchen", create = "Create", wheel = "Decide", profile = "Diary"
    var id: String { rawValue }
    var symbol: String { switch self { case .explore:"sparkles"; case .pantry:"carrot"; case .create:"plus.circle.fill"; case .wheel:"circle.hexagongrid.fill"; case .profile:"book.closed" } }
}
struct RootView: View {
    @EnvironmentObject var store: KitchenStore
    @EnvironmentObject var account: AccountService
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var membership:MembershipStore
    @Environment(\.horizontalSizeClass) var sizeClass
    @AppStorage("kitchen.onboarded") var onboarded = false
    @State private var tab: KitchenTab = .explore
    @State private var showCooking = false
    var body: some View {
        Group {
            if !onboarded { WelcomeView { withAnimation { onboarded = true } } }
            else if sizeClass == .regular {
                NavigationSplitView {
                    List(KitchenTab.allCases,selection:Binding<KitchenTab?>(get:{tab},set:{if let value=$0 {tab=value}})) { item in Label(item.rawValue,systemImage:item.symbol).lineLimit(1).minimumScaleFactor(0.7).tag(item).padding(.vertical,10) }
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1).navigationTitle("Kitchen Diary").tint(KitchenTheme.coral).scrollContentBackground(.hidden).kitchenBackground()
                } detail: { NavigationStack { screen(tab) } }
            } else {
                TabView(selection:$tab) {
                    ForEach(KitchenTab.allCases) { item in NavigationStack { screen(item) }.tabItem { Label(item.rawValue,systemImage:item.symbol) }.tag(item) }
                }
            }
        }
        .safeAreaInset(edge:.bottom) {
            if let session = store.data.session, onboarded {
                Button { showCooking = true } label: {
                    HStack { Image(systemName:"flame.fill").foregroundStyle(KitchenTheme.coral); VStack(alignment:.leading) { Text(session.recipe.title).font(.subheadline.bold()); Text("Step \(session.stepIndex+1) · Continue cooking").font(.caption).foregroundStyle(.secondary) }; Spacer(); Image(systemName:"arrow.up.right") }.padding(14).background(.regularMaterial,in:RoundedRectangle(cornerRadius:18)).padding(.horizontal)
                }.buttonStyle(.plain).accessibilityIdentifier("resumeCooking")
            }
        }
        .fullScreenCover(isPresented:$showCooking) { CookingView().environmentObject(store) }
        .task { await membership.refresh(); await account.restore(store:store) }
        .onChange(of:scenePhase) {_,phase in if phase == .active {Task {await membership.refresh();await account.refreshEntitlement()}}}
        .onOpenURL { url in
            if url.scheme == "kitchendiary", url.host == "cook", let recipe = store.catalog.recipe(url.lastPathComponent) {
                onboarded = true; store.startCooking(recipe); showCooking = true
            } else { _ = GIDSignIn.sharedInstance.handle(url) }
        }
        .alert("Storage needs attention",isPresented:Binding(get:{store.storageError != nil},set:{if !$0 {store.storageError=nil}})) { Button("OK") {store.storageError=nil} } message: { Text(store.storageError ?? "") }
    }
    @ViewBuilder func screen(_ tab: KitchenTab) -> some View {
        switch tab {
        case .explore: ExploreView { recipe in store.data.draft = recipe; self.tab = .create }
        case .pantry: PantryView { recipe in store.data.draft = recipe; self.tab = .create }
        case .create: BuilderView()
        case .wheel: DeciderView()
        case .profile: DiaryView { recipe in store.data.draft = recipe; self.tab = .create }
        }
    }
}
struct WelcomeView: View {
    var enter: ()->Void
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:24) {
                HStack { Label("Kitchen Diary",systemImage:"sun.max.fill").font(.headline); Spacer(); Text("MADE WITH JOY").font(.caption2.bold()).tracking(2) }.padding(.top,20)
                Image("hero").resizable().scaledToFill().frame(height:320).clipped().clipShape(RoundedRectangle(cornerRadius:36))
                Eyebrow(title:"A little inspiration. A lot of love.")
                Text("Good food.\nLittle moments.\nYour kitchen.").font(KitchenTheme.display(46))
                Text("Turn what’s in your fridge into something lovely. Find your next favourite, spin away indecision, and cook one happy step at a time.").font(.body).foregroundStyle(.secondary)
                Button("Let’s make something") { enter() }.buttonStyle(KitchenButton()).accessibilityIdentifier("getStarted")
                Label("Your kitchen works offline, too.",systemImage:"heart").font(.caption).foregroundStyle(.secondary).frame(maxWidth:.infinity)
            }.padding(24).frame(maxWidth:620)
        }.frame(maxWidth:.infinity).kitchenBackground()
    }
}
