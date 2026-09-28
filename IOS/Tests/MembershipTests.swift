import XCTest
import StoreKitTest
@testable import KitchenDiary

final class MembershipTests:XCTestCase {
    @MainActor func testLocalStoreKitPurchaseAndExpiry() async throws {
        let url=Bundle(for:Self.self).url(forResource:"KitchenDiary",withExtension:"storekit")!
        let session=try SKTestSession(contentsOf:url)
        session.resetToDefaultState();session.disableDialogs=true;session.clearTransactions()
        defer {session.clearTransactions()}
        let membership=MembershipStore()
        // A freshly booted simulator applies StoreKitTest configuration asynchronously.
        // Wait for the local products before testing any purchase behavior.
        for _ in 0..<10 {
            await membership.load()
            if membership.products.count == MembershipStore.productIDs.count { break }
            try await Task.sleep(for:.milliseconds(250))
        }
        XCTAssertEqual(Set(membership.products.map(\.id)),Set(MembershipStore.productIDs),membership.message ?? "No StoreKit message")
        let monthly=try XCTUnwrap(membership.products.first {$0.id.hasSuffix("monthly")})
        await membership.purchase(monthly)
        XCTAssertTrue(membership.active)
        for transaction in session.allTransactions() { try session.disableAutoRenewForTransaction(identifier:transaction.identifier) }
        try session.expireSubscription(productIdentifier:monthly.id)
        for _ in 0..<30 {
            await membership.refresh()
            if !membership.active { break }
            try await Task.sleep(for:.milliseconds(100))
        }
        XCTAssertFalse(membership.active)
    }
}
