import Foundation
import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import AuthenticationServices

@MainActor final class AccountService:ObservableObject {
    @Published var name:String?
    @Published var busy=false
    @Published var error:String?
    @Published var syncStatus="Saved on this device"
    @Published var entitlement="Sign in to check your existing membership."
    private var pending:Task<Void,Never>?
    private var activeUID:String?
    private let appleAuthorization = AppleAuthorization()
    @Published var hasPro = false
    static func configure() {if FirebaseApp.app()==nil {FirebaseApp.configure()}}
    private func googleCredential() async throws -> AuthCredential {
        guard let clientID=FirebaseApp.app()?.options.clientID,
              let scene=UIApplication.shared.connectedScenes.compactMap({$0 as? UIWindowScene}).first,
              let root=scene.windows.first(where:{$0.isKeyWindow})?.rootViewController else {throw AccountError.configuration}
        GIDSignIn.sharedInstance.configuration=GIDConfiguration(clientID:clientID)
        var presenter=root;while let next=presenter.presentedViewController {presenter=next}
        let result=try await GIDSignIn.sharedInstance.signIn(withPresenting:presenter)
        guard let token=result.user.idToken?.tokenString else {throw AccountError.configuration}
        return GoogleAuthProvider.credential(withIDToken:token,accessToken:result.user.accessToken.tokenString)
    }
    func signIn(store:KitchenStore, withApple:Bool = false) async {
        guard !busy else {return}
        busy=true;error=nil
        do {
            let credential:AuthCredential
            if withApple {credential=try await appleAuthorization.authorize().credential}
            else {credential=try await googleCredential()}
            _=try await Auth.auth().signIn(with:credential)
            await restore(store:store)
        } catch {
            if (error as? ASAuthorizationError)?.code != .canceled {self.error=error.localizedDescription}
        }
        busy=false
    }
    func deleteAccount(store:KitchenStore) async {
        guard !busy,let user=Auth.auth().currentUser else {return}
        busy=true;error=nil;pending?.cancel();store.onSave=nil
        if let pending {await pending.value}
        let uid=user.uid
        do {
            if user.providerData.contains(where:{$0.providerID=="apple.com"}) {
                let result=try await appleAuthorization.authorize()
                _=try await user.reauthenticate(with:result.credential)
                try await Auth.auth().revokeToken(withAuthorizationCode:result.authorizationCode)
            } else {
                _=try await user.reauthenticate(with:googleCredential())
            }
            guard Auth.auth().currentUser?.uid==uid else {throw AccountError.accountChanged}
            var request=URLRequest(url:AppLinks.deleteAccount)
            request.httpMethod="POST";request.timeoutInterval=120
            request.setValue("Bearer \(try await user.getIDToken(forcingRefresh:true))",forHTTPHeaderField:"Authorization")
            request.setValue("application/json",forHTTPHeaderField:"Content-Type")
            request.httpBody=try JSONSerialization.data(withJSONObject:["confirmation":"DELETE"])
            let (body,response)=try await URLSession.shared.data(for:request)
            guard (response as? HTTPURLResponse)?.statusCode==200,
                  (try? JSONSerialization.jsonObject(with:body) as? [String:Bool])?["deleted"] == true else {throw AccountError.deletionUnavailable}
            // Do not use signOut(store:), which would save the deleted account again.
            try? Auth.auth().signOut();GIDSignIn.sharedInstance.signOut()
            activeUID=nil;name=nil;hasPro=false
            UserDefaults.standard.removeObject(forKey:"kitchen.account."+uid)
            UserDefaults.standard.removeObject(forKey:"kitchen.native.owner")
            store.data=SavedKitchen();store.data.cuisines=store.catalog.cuisines;store.synchronize()
            syncStatus="Account deleted";entitlement="Sign in to check your existing membership."
        } catch {
            activeUID=nil
            self.error="Account deletion did not finish. Please retry after signing in again. Your Apple subscription must be cancelled separately."
        }
        busy=false
    }
    func restore(store:KitchenStore) async {
        guard let user=Auth.auth().currentUser else {return}
        name=user.displayName ?? "Little chef"
        guard activeUID != user.uid else {return}
        busy=true;error=nil;store.onSave=nil
        let uid=user.uid
        // Each account owns a separate local kitchen. A guest kitchen is only adopted on first sign-in.
        let defaults=UserDefaults.standard,previous=defaults.string(forKey:"kitchen.native.owner")
        if previous != uid {
            if let encoded=try? JSONEncoder().encode(store.data) {defaults.set(encoded,forKey:"kitchen.account."+(previous ?? "guest"))}
            if let raw=defaults.data(forKey:"kitchen.account."+uid),let saved=try? JSONDecoder().decode(SavedKitchen.self,from:raw) {store.data=saved}
            else if previous != nil {store.data=SavedKitchen();store.data.cuisines=store.catalog.cuisines}
            defaults.set(uid,forKey:"kitchen.native.owner")
        }
        do {
            let db=Firestore.firestore()
            let pantry=try await db.document("users/\(uid)/pantry/state").getDocument()
            let draft=try await db.document("users/\(uid)/recipeDrafts/current").getDocument()
            guard Auth.auth().currentUser?.uid==uid else {throw AccountError.accountChanged}
            if let value=pantry.data() {store.data.pantry=Self.pantry(value)}
            if let value=draft.data(),let title=value["title"] as? String,let steps=value["steps"] as? [[String:Any]] {
                let raw=try JSONSerialization.data(withJSONObject:steps)
                store.data.draft=Recipe(title:title,steps:try JSONDecoder().decode([RecipeStep].self,from:raw))
            }
            activeUID=uid
            store.onSave={ [weak self,weak store] in
                guard let self,let store else {return}
                self.pending?.cancel()
                self.pending=Task {try? await Task.sleep(for:.milliseconds(800));guard !Task.isCancelled else {return};await self.sync(store:store)}
            }
            await sync(store:store);await refreshEntitlement()
        } catch {self.error="Cloud sync couldn’t finish. Your local kitchen is safe. \(error.localizedDescription)";syncStatus="Sync needs a retry"}
        busy=false
    }
    func sync(store:KitchenStore) async {
        guard let uid=Auth.auth().currentUser?.uid,uid==activeUID else {await restore(store:store);return}
        let snapshot=store.data
        do {
            let db=Firestore.firestore(),batch=db.batch()
            var pantry=try Self.object(snapshot.pantry);pantry["updatedAt"]=FieldValue.serverTimestamp()
            let draft:[String:Any]=["title":snapshot.draft.title,"steps":try snapshot.draft.steps.map {try Self.object($0)},"updatedAt":FieldValue.serverTimestamp()]
            batch.setData(pantry,forDocument:db.document("users/\(uid)/pantry/state"))
            batch.setData(draft,forDocument:db.document("users/\(uid)/recipeDrafts/current"))
            try await batch.commit()
            guard !Task.isCancelled, Auth.auth().currentUser?.uid==uid else {return}
            syncStatus="Pantry & draft synced";error=nil
        } catch {self.error="Sync is waiting for a connection. Your changes are saved here.";syncStatus="Saved locally · retry sync"}
    }
    func refreshEntitlement() async {
        guard let uid=Auth.auth().currentUser?.uid else {return}
        do {
            let value=try await Firestore.firestore().document("subscriptionEntitlements/\(uid)").getDocument().data()
            let active=value?["active"] as? Bool ?? false
            let expiry=(value?["currentPeriodEnd"] as? Timestamp)?.dateValue()
            hasPro=active && (expiry==nil || expiry!>Date())
            entitlement=hasPro ? "Kitchen Diary Premium · active":"Free kitchen · all local cooking tools available"
        } catch {hasPro=false;entitlement="Membership status is unavailable. Please try again."}
    }
    func signOut(store:KitchenStore) {
        pending?.cancel();store.onSave=nil
        if let uid=activeUID,let raw=try? JSONEncoder().encode(store.data) {UserDefaults.standard.set(raw,forKey:"kitchen.account."+uid)}
        do {try Auth.auth().signOut();GIDSignIn.sharedInstance.signOut();activeUID=nil;name=nil;hasPro=false;UserDefaults.standard.removeObject(forKey:"kitchen.native.owner")
            if let raw=UserDefaults.standard.data(forKey:"kitchen.account.guest"),let guest=try? JSONDecoder().decode(SavedKitchen.self,from:raw) {store.data=guest} else {store.data=SavedKitchen();store.data.cuisines=store.catalog.cuisines}
            store.synchronize()
        } catch {self.error=error.localizedDescription}
    }
    static func object<T:Encodable>(_ value:T)throws->[String:Any] {try JSONSerialization.jsonObject(with:JSONEncoder().encode(value)) as? [String:Any] ?? [:]}
    static func pantry(_ value:[String:Any])->PantryState {
        PantryState(ingredients:value["ingredients"] as? [String] ?? [],cookware:value["cookware"] as? [String] ?? [],mode:MatchMode(rawValue:value["mode"] as? String ?? "") ?? .flexible,favorites:value["favorites"] as? [String] ?? [],history:Array((value["history"] as? [String] ?? []).prefix(20)),dishCount:min(5,max(1,value["dishCount"] as? Int ?? 3)))
    }
    enum AccountError:LocalizedError {case configuration,accountChanged,deletionUnavailable;var errorDescription:String? {switch self {case .configuration:"Sign-in could not start. Please check the app configuration and try again.";case .deletionUnavailable:"Account deletion is temporarily unavailable. Please retry.";case .accountChanged:"The signed-in account changed. Please retry."}}}
}
