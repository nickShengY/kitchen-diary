# Kitchen Diary · Native Swift

A SwiftUI iPhone/iPad app and a standalone-capable watchOS companion. The React and Flutter apps remain intact.

## Open and run

Open `KitchenDiary.xcodeproj` in Xcode. Select the **KitchenDiary** scheme and an iPhone or iPad simulator. Select **KitchenDiaryWatch** for the Watch app. Pair a Watch simulator with your iPhone simulator when testing handoff. The project uses Swift Package Manager for the official Firebase and Google Sign-In SDKs; the resolved versions are checked in.

Deployment targets: iOS/iPadOS 17 and watchOS 10. Testing on newer simulators does not establish coverage of every older OS or physical device.

Device builds need your Apple Development team and provisioning. Simulator signing is disabled only for simulator SDKs. The existing Firebase registration uses `com.kitchendiary.app`; the companion uses `com.kitchendiary.app.watchkitapp`. Because the native app and Flutter app share the iOS bundle identifier, installing one replaces the other on a given device. Their local storage formats remain separate.

## What is included

| React feature | Native implementation |
| --- | --- |
| Landing / onboarding | Warm illustrated welcome, guest access, persistent onboarding state |
| Community | Offline recipe catalog, search, online MealDB search, tags, popular/latest order, likes, bookmarks, local recipe feed, native share sheet |
| Pantry | Complete ingredient and cookware catalogs, Flexible/Exact/Survival matching, ranked recipes, balanced 1–5 dish menus, reroll and pin, shopping checklist/share |
| Recipe builder | Persistent draft, ingredient quantities/units, compatible actions, tools/stations, all step settings, notes, reorder/edit/delete, cookbook saving, local feed sharing |
| Recipe player | Native cooking guide, original action animations, ingredient quantities, step settings, previous/next, completion history |
| Wheel | Two-stage cuisine/dish wheel, customization, history, recipe lookup, haptics, accurate pointer/result agreement |
| Menu photo | Pro: Photos picker and Apple Vision OCR on device; review/edit extracted dish names before spinning. Manual entry is free and works offline |
| Profile | Saved recipes, history, cookbook, local shared feed, name/settings, Apple/Google sign-in/out, in-app account deletion, account-scoped pantry/draft sync, existing membership status |
| Billing | StoreKit 2 product loading, verified purchase handling, transaction updates, restore, expiry/revocation handling, Apple subscription management; local StoreKit test catalog |
| iPad | Sidebar navigation, adaptive grids, centered readable editors, portrait/landscape support |
| Watch | Standalone wheel, Digital Crown selection, random spin, cuisine/dish stages, persistent cooking steps/timers, bidirectional WatchConnectivity context/messages |

`Community` sharing follows the React implementation's **local-device feed** behavior. Native sharing sends a recipe through the system share sheet. It does not pretend to publish a public server post.

## Data and assets

The bundled catalog comes from executing the actual TypeScript exports, not a parallel handwritten recipe list: **204 ingredients, 50 tools, 45 actions, 59 pantry recipes, 31 cuisines**. The exporter also runs the React matching/menu functions to produce 36 golden test fixtures. The app includes 196 original ingredient illustrations plus the hero/mascot and 42 original action animations. Actions without an authored animation use the mascot fallback.

From the repository root, using Node with the existing dependencies installed:

```sh
node IOS/Tools/export-catalog.mjs
python3 IOS/Tools/export-assets.py
python3 IOS/Tools/export-motion.py
```

The image exporters require Pillow. Generated catalog and assets are committed, so these tools are only necessary when source content changes.

If adding or removing Swift files, regenerate the project with the Ruby `xcodeproj` gem (1.28.1):

```sh
ruby IOS/Tools/create-project.rb
```

Local data is stored in a versioned Codable snapshot. Signing in separates local account kitchens and syncs the existing Firestore paths `users/{uid}/pantry/state` and `users/{uid}/recipeDrafts/current`. Favorites/history inside pantry are compatible with the React schema. Cookbook/feed/likes remain local, as in the corresponding React stores. Browser localStorage cannot be read directly by the native sandbox.

Cooking timers persist a wall-clock deadline, request notification permission only when a timer is started, and schedule a local notification. Foreground displays remain accurate after backgrounding/relaunch. Watch snapshots have persisted revisions so stale queued state cannot resurrect an older guide. Watch haptics and connectivity still warrant physical-device testing.

## Subscriptions and service verification

The core app is free; Pro unlocks menu-photo recognition. The requested price is 2.99, with currency and term pending confirmation. The local `.storekit` catalog is **test data**, with a draft 2.99 monthly test product. It is used by `MembershipTests` and makes no real charges. Real products must be created in App Store Connect with the IDs in `MembershipStore.productIDs` (or those IDs must be changed to your actual product IDs). Prices displayed in production come from StoreKit, not the sample catalog. When products are unavailable, the app explains that and keeps cooking features usable.

Apple entitlements are verified through StoreKit. Existing Firebase membership is read from the existing server-owned entitlement document. This change does not deploy an App Store Server Notifications bridge to share Apple purchases with the web/Android entitlement system. Never grant server membership from an unverified client flag.

The existing Firebase configuration and Sign in with Apple entitlement are included, but Apple provider configuration, real Apple/Google sign-in, two-account cloud round trips, production entitlements, and real App Store sandbox purchases need an authenticated validation session. No production purchases or backend writes were made by the automated local tests.

Public App Store builds require a TheMealDB supporter key for wider online search. Pass `MEALDB_API_KEY` when archiving; Release never falls back to the development key `1`. Without a production key, local recipe search and the bundled catalog still work.

## Test commands

Use a destination returned by `xcrun simctl list devices available`:

```sh
xcodebuild -project IOS/KitchenDiary.xcodeproj -scheme KitchenDiary \
  -destination 'platform=iOS Simulator,id=YOUR_IPHONE_OR_IPAD_ID' \
  -derivedDataPath IOS/.build -parallel-testing-enabled NO -collect-test-diagnostics never test

xcodebuild -project IOS/KitchenDiary.xcodeproj -scheme KitchenDiaryWatch \
  -destination 'platform=watchOS Simulator,id=YOUR_WATCH_ID' \
  -derivedDataPath IOS/.build -parallel-testing-enabled NO -collect-test-diagnostics never test
```

Before the full Watch suite, open Tomato Scrambled Eggs on the paired iPhone and tap **Let’s cook this**. The handoff test intentionally verifies that phone recipe, rather than substituting a sample. The crown/standalone guide test can run separately with `-only-testing:KitchenDiaryWatchUITests/WatchUITests/testCrownWheelAndCookingGuide`. A `kitchendiary://cook/<recipe-id>` link can also open a guide; accept the system open-app confirmation if prompted.

See `Release/APP_STORE.md` for the release checklist, metadata draft, signing instructions and backend deployment requirements. `Tools/release-audit.py` audits source and optionally an archive without pretending unsigned builds can ship.

See `VALIDATION.md` for actual results and remaining validation boundaries. Test runs attach screenshots to their `.xcresult` bundles. `-ui-testing-reset` resets only the native app snapshot for deterministic UI tests; normal launches preserve data.
