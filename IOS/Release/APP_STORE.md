# App Store release package

## Release status

**Not approved for submission yet.** Simulator success and an unsigned archive do not replace a signed App Store validation or live-service testing. The merge ships source code; it does not submit the app to Apple.

The core app is free. Pro unlocks menu-photo recognition; typing dishes, wheels, pantry matching, recipes, guides and Watch features remain free. The requested price is 2.99; billing interval and base currency still need confirmation. Do not create or submit live products with guessed terms. Existing product identifiers are retained for compatibility while that decision is pending.

## Required external setup

1. Sign into Xcode with the owning Apple Developer team; register `com.kitchendiary.app` and `com.kitchendiary.app.watchkitapp`, and enable Sign in with Apple for the iOS app. No valid signing identity was available on the implementation Mac.
2. Enable Apple authentication in the existing Firebase project. Configure the Apple provider, key/team identifiers and private email relay as required by Firebase. Validate both Google and Apple sign-in, account isolation and cloud round trips on a real device. No account credentials or private signing keys belong in this repository.
3. Deploy the updated `firestore.rules` **before enabling the deletion endpoint for release**. The `accountDeletions/{uid}` marker prevents another signed-in client from recreating deleted data. Deploy the Vercel `api/delete-account.ts` endpoint with the existing Firebase Admin service-account environment configured. Test deletion with a disposable account containing nested data, and verify the identity and owned records are gone. The endpoint checks revocation, authentication within five minutes and explicit confirmation; the UID is never taken from request JSON. Apple authorization is revoked by the client before cleanup. Financial ownership/audit records and the anti-recreation marker are retained.
4. Create App Store Connect app and final Pro in-app purchase(s) with agreed currency/term. The `.storekit` file is local test data, not an App Store registration. Validate purchase, cancellation, renewal/expiry, restore on a second device, and refunds with sandbox accounts. Apple entitlements are local StoreKit verified entitlements; sharing them with web/Android requires a server entitlement integration, which is not implemented here.
5. Choose an unused increasing build number, archive with `APPLE_TEAM_ID=... BUILD_NUMBER=... IOS/Tools/archive.sh`, and use Organizer **Validate App**. Resolve signing/export/upload diagnostics before TestFlight. This script never uploads or submits automatically.
6. Complete App Store Connect privacy answers, content rights, age-rating questionnaire, export-compliance answers, contact details, availability and agreements. The manifest covers account identity, user content, purchase history and UserDefaults; verify it against the final services. No ads or tracking are implemented in the native app.
7. Test notification delivery while locked, interruption/reconnection on physical Watch, voice accessibility, and the minimum supported OS releases. Current simulator results use iOS/watchOS 27.0; deployment targets are iOS 17 and watchOS 10.

## Metadata draft

- Name: Kitchen Diary
- Subtitle: Cook, create & spin for dinner
- Primary category: Food & Drink
- Secondary category: Lifestyle
- Keywords: recipes,cooking,pantry,dinner,meal,wheel,menu,kitchen,watch,timer
- Support URL: https://kitchendiary.robopioneer.ca/support
- Privacy URL: https://kitchendiary.robopioneer.ca/privacy
- Terms: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
- Support contact: robopioneer.product@gmail.com (existing published support address)

### Description

Make something lovely with what is already in your kitchen.

Kitchen Diary brings your pantry, recipes and cooking ideas together in a warm little home. Find recipes that fit your ingredients and cookware, build your own step-by-step creations, save favourites, and keep a diary of the dishes you cook.

Can't decide on dinner? Spin a cuisine, then a dish. On Apple Watch, turn the Digital Crown for a quick choice and follow cooking steps and timers from your wrist. On iPad, enjoy roomier recipe and pantry views.

The everyday kitchen is free: recipe discovery, pantry matching, recipe creation, manual menu entry, cooking guides and the Watch wheel. Kitchen Diary Pro adds menu-photo recognition, reading text privately on your device so you can review the dishes and spin your menu choices. Purchase terms and localized prices are shown before checkout.

Core cooking features work offline. Optional sign-in syncs your pantry and recipe draft. Online recipe search requires an internet connection.

### Review notes

Guest mode provides access to core features without registration. Tap the welcome button, then use Explore, Kitchen, Create, Decide and Diary. Pro menu recognition is under Decide → Scan a menu; manual entry remains free. Restore purchases is in Diary → Kitchen Diary Pro. Privacy, support and account deletion are in Diary → Settings. Deletion requires a fresh sign-in and does not cancel store billing.

For Watch review, pair a Watch with the iPhone, start a recipe's cooking guide on the phone, then open the Watch cooking page. The wheel also works without the phone. Crown selection and randomized spins are separate choices.

Supply a working reviewer account if Apple needs to inspect cloud features. Do not claim those features were authenticated-tested until the checks above are complete.

## Screenshot specifications and sources

Use actual final-build screenshots. iPhone 6.9-inch accepts 1320 × 2868; iPad requires the 13-inch set (2064 × 2752 or 2048 × 2732). Prior iPad mini captures alone are insufficient. Watch Series 12 uses 416 × 496. Export opaque RGB PNG/JPEG images, 1–10 per device set. Never submit earlier layout-debug screenshots.

Authoritative references: [Apple review guidelines](https://developer.apple.com/app-store/review/guidelines/), [account deletion](https://developer.apple.com/support/offering-account-deletion-in-your-app/), [screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/), [Firebase Apple authentication](https://firebase.google.com/docs/auth/ios/apple).
