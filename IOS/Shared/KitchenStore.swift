import Foundation
import Combine
import WatchConnectivity
import UserNotifications

struct SavedKitchen: Codable {
    var pantry = PantryState(); var draft = Recipe(title: "My little masterpiece")
    var cookbook: [Recipe] = []; var liked: [String] = []; var published: [Recipe] = []
    var cuisines: [Cuisine] = []; var session: CookingSession?; var displayName = "Little chef"
    var checkedShopping: [String] = []; var wheelHistory: [String] = []; var syncRevision = Date.distantPast
}
@MainActor final class KitchenStore: NSObject, ObservableObject {
    @Published var data: SavedKitchen { didSet { persist() } }
    @Published var storageError: String?
    @Published var watchStatus = "Your cooking guide travels with you."
    let catalog: Catalog
    private let defaults: UserDefaults
    private let key: String
    private let watchEnabled: Bool
    var onSave: (() -> Void)?
    init(catalog: Catalog = .shared, defaults: UserDefaults = .standard, key: String = "kitchen.native.v1", connectWatch: Bool = true) {
        self.catalog = catalog; self.defaults = defaults; self.key = key; self.watchEnabled = connectWatch
        if let raw = defaults.data(forKey:key), let saved = try? JSONDecoder().decode(SavedKitchen.self,from:raw) { data = saved }
        else { data = SavedKitchen() }
        super.init()
        if data.cuisines.isEmpty { data.cuisines = catalog.cuisines }
        if connectWatch && WCSession.isSupported() { WCSession.default.delegate = self; WCSession.default.activate() }
    }
    func persist() {
        do { defaults.set(try JSONEncoder().encode(data),forKey:key); onSave?() }
        catch { storageError = "Your changes could not be saved: \(error.localizedDescription)" }
    }
    func toggleIngredient(_ id: String) { toggle(id, in: &data.pantry.ingredients) }
    func toggleTool(_ id: String) { toggle(id, in: &data.pantry.cookware) }
    private func toggle(_ id: String, in list: inout [String]) { if list.contains(id) { list.removeAll { $0 == id } } else { list.append(id) } }
    func favorite(_ recipe: Recipe) {
        toggle(recipe.id.replacingOccurrences(of:"pantry-",with:""),in:&data.pantry.favorites)
        if catalog.recipe(recipe.id) == nil && !data.cookbook.contains(where: {$0.id == recipe.id}) { data.cookbook.append(recipe) }
    }
    func isFavorite(_ recipe: Recipe) -> Bool { data.pantry.favorites.contains(recipe.id.replacingOccurrences(of:"pantry-",with:"")) }
    func like(_ recipe: Recipe) { toggle(recipe.id,in:&data.liked) }
    func saveDraft() {
        let recipe = data.draft
        if let i = data.cookbook.firstIndex(where: {$0.id == recipe.id}) { data.cookbook[i] = recipe } else { data.cookbook.insert(recipe,at:0) }
    }
    func publishDraft() {
        saveDraft()
        var recipe = data.draft; recipe.authorName = data.displayName
        data.published.removeAll { $0.id == recipe.id }; data.published.insert(recipe,at:0)
    }
    var allRecipes: [Recipe] {
        var ids = Set<String>(); return (data.cookbook + data.published + catalog.convertedRecipes).filter { ids.insert($0.id).inserted }
    }
    func startCooking(_ recipe: Recipe) {
        guard !recipe.steps.isEmpty else { return }
        if catalog.recipe(recipe.id) != recipe {
            if let index = data.cookbook.firstIndex(where: { $0.id == recipe.id }) { data.cookbook[index] = recipe } else { data.cookbook.insert(recipe, at: 0) }
        }
        cancelNotification(); data.session = CookingSession(recipe:recipe); synchronize()
    }
    func moveStep(_ delta: Int) {
        guard var session = data.session else { return }
        session.stepIndex = min(max(0,session.stepIndex+delta),max(0,session.recipe.steps.count-1)); session.timerEnd = nil; session.pausedSeconds = nil; session.updatedAt = Date()
        cancelNotification(); data.session = session; synchronize()
    }
    func completeCooking() {
        guard let recipe = data.session?.recipe else { return }
        let id = recipe.id.replacingOccurrences(of:"pantry-",with:"")
        data.pantry.history.removeAll { $0 == id }; data.pantry.history.insert(id,at:0); data.pantry.history = Array(data.pantry.history.prefix(20))
        cancelNotification(); data.session = nil; synchronize()
    }
    func startTimer(seconds: Int? = nil) {
        guard var session = data.session else { return }
        let duration = seconds ?? session.pausedSeconds ?? session.step?.durationSeconds ?? 0
        guard duration > 0 else { return }
        session.timerEnd = Date().addingTimeInterval(Double(duration)); session.pausedSeconds = nil; session.updatedAt = Date(); data.session = session
        scheduleNotification(seconds:duration,title:session.recipe.title); synchronize()
    }
    func pauseTimer() {
        guard var session = data.session else { return }
        session.pausedSeconds = session.remaining(); session.timerEnd = nil; session.updatedAt = Date(); data.session = session; cancelNotification(); synchronize()
    }
    private func scheduleNotification(seconds: Int, title: String) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options:[.alert,.sound]) { granted,_ in
            guard granted else { return }
            let content = UNMutableNotificationContent(); content.title = "Time for the next little step"; content.body = title; content.sound = .default
            UNUserNotificationCenter.current().add(UNNotificationRequest(identifier:"cooking-timer",content:content,trigger:UNTimeIntervalNotificationTrigger(timeInterval:Double(max(1,seconds)),repeats:false)))
        }
    }
    private func cancelNotification() { UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers:["cooking-timer"]) }
    func synchronize(changed: Bool = true) {
        if changed { data.syncRevision = Date() }
        guard watchEnabled, WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        struct Transfer: Codable { var session: CookingSession?; var cuisines: [Cuisine]; var sentAt: Date }
        guard let payload = try? JSONEncoder().encode(Transfer(session:data.session,cuisines:data.cuisines,sentAt:data.syncRevision)) else { return }
        let message: [String:Any] = ["kitchen":payload]
        do { try WCSession.default.updateApplicationContext(message) } catch { watchStatus = "Watch sync will retry when your devices reconnect." }
        if WCSession.default.isReachable { WCSession.default.sendMessage(message,replyHandler:nil,errorHandler:nil) }
    }
    private func receive(_ message: [String:Any]) {
        struct Transfer: Codable { var session: CookingSession?; var cuisines: [Cuisine]; var sentAt: Date }
        guard let raw = message["kitchen"] as? Data, let payload = try? JSONDecoder().decode(Transfer.self,from:raw) else { return }
        let last = data.syncRevision
        guard payload.sentAt > last, payload.sentAt > (data.session?.updatedAt ?? .distantPast) else { return }
        data.syncRevision = payload.sentAt
        cancelNotification()
        if let session = payload.session, session.timerEnd != nil, session.remaining() > 0 { scheduleNotification(seconds:session.remaining(),title:session.recipe.title) }
        data.session = payload.session; data.cuisines = payload.cuisines; watchStatus = "Up to date with your cooking companion."
    }
}
extension KitchenStore: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if !session.receivedApplicationContext.isEmpty { self.receive(session.receivedApplicationContext) }
            #if os(iOS)
            self.synchronize(changed:false)
            #endif
        }
    }
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String:Any]) { Task { @MainActor in self.receive(applicationContext) } }
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String:Any]) { Task { @MainActor in self.receive(message) } }
    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    #endif
}
