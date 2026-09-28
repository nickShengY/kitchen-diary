import SwiftUI
import StoreKit

@MainActor final class MembershipStore:ObservableObject {
    static let productIDs=["com.kitchendiary.premium.monthly","com.kitchendiary.premium.yearly"]
    @Published var products:[Product]=[]
    @Published var active=false
    @Published var busy=false
    @Published var message:String?
    private var updates:Task<Void,Never>?
    init() {
        updates=Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard let self else {return}
                if case .verified(let transaction)=result,Self.productIDs.contains(transaction.productID) {await transaction.finish();await self.refresh()}
            }
        }
    }
    deinit {updates?.cancel()}
    func load() async {
        busy=true;message=nil
        do {products=try await Product.products(for:Self.productIDs).sorted {$0.price < $1.price};if products.isEmpty {message="Subscriptions aren’t available from the App Store yet. Your cooking tools are still ready to use."}}
        catch {message="We couldn’t reach the App Store. Please try again later."}
        await refresh();busy=false
    }
    func refresh() async {
        var entitled=false
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction)=result,Self.productIDs.contains(transaction.productID),transaction.revocationDate==nil else {continue}
            if let expiry=transaction.expirationDate,expiry<=Date() {continue}
            entitled=true
        }
        active=entitled
    }
    func purchase(_ product:Product) async {
        busy=true;message=nil
        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction)=verification else {message="Your purchase couldn’t be verified. Please restore purchases or contact Apple support.";busy=false;return}
                await transaction.finish();await refresh();message="Pro menu recognition is ready to use."
            case .pending:message="Your purchase is awaiting approval. We’ll update your membership when it’s ready."
            case .userCancelled:break
            @unknown default:message="Your purchase hasn’t completed. Please try again."
            }
        } catch {message=error.localizedDescription}
        busy=false
    }
    func restore() async {
        busy=true
        do {try await AppStore.sync();await refresh();message=active ? "Your membership is restored.":"No active Apple subscription was found."} catch {message=error.localizedDescription}
        busy=false
    }
}
struct MembershipView:View {
    @EnvironmentObject var membership:MembershipStore
    @EnvironmentObject var account:AccountService
    @Environment(\.dismiss) var dismiss
    var body:some View {
        NavigationStack {
            ScrollView {VStack(alignment:.leading,spacing:24) {
                Text("✦").font(.system(size:60)).foregroundStyle(KitchenTheme.coral)
                Eyebrow(title:"A little menu-reading magic")
                SectionTitle(title:"Kitchen Diary Pro",subtitle:"Turn menu photos into editable dish lists with private, on-device recognition. Pantry matching, recipes, manual menu entry, cooking guides and the Watch wheel stay free.")
                if account.hasPro {Label("Your existing membership includes menu recognition",systemImage:"checkmark.seal.fill").foregroundStyle(KitchenTheme.sage)}
                if membership.active {Label("Your Apple membership is active",systemImage:"checkmark.seal.fill").foregroundStyle(KitchenTheme.sage)}
                if membership.busy {ProgressView("Checking with the App Store…")}
                ForEach(membership.products,id:\.id) {product in
                    PaperCard {Text(product.displayName).font(KitchenTheme.display(24));Text(product.description).foregroundStyle(.secondary).padding(.vertical,8);Button {Task {await membership.purchase(product)}} label: {Text("\(product.displayPrice) / \(product.id.hasSuffix("yearly") ? "year":"month")")}.buttonStyle(KitchenButton()).disabled(membership.busy || membership.active || account.hasPro)}
                }
                if let message=membership.message {Text(message).font(.subheadline).foregroundStyle(.secondary)}
                if membership.products.isEmpty {Button("Try again") {Task {await membership.load()}}.disabled(membership.busy)}
                Button("Restore purchases") {Task {await membership.restore()}}.disabled(membership.busy)
                Button("Manage Apple subscription") {Task {if let scene=UIApplication.shared.connectedScenes.compactMap({$0 as? UIWindowScene}).first {do {try await AppStore.showManageSubscriptions(in:scene)} catch {membership.message=error.localizedDescription}}}}
                Text("Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. Manage or cancel in your Apple account. An Apple purchase is restored through Apple; an existing web membership is checked separately through your Kitchen Diary account.").font(.caption).foregroundStyle(.secondary)
                Link("Privacy policy",destination:AppLinks.privacy)
                Link("Terms of use",destination:AppLinks.terms)
                Link("Contact support",destination:AppLinks.support)
            }.padding(24).frame(maxWidth:700)}.frame(maxWidth:.infinity).kitchenBackground().navigationTitle("Membership").navigationBarTitleDisplayMode(.inline).toolbar {Button("Done") {dismiss()}}
        }.task {await membership.load()}
    }
}
