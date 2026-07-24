# Issue Ledger

Legend: blocker = prevents core use or deploy; major = materially harms strategy, UX, reliability, or trust; minor = worth fixing but not release-blocking; polish = improvement opportunity.

## Current Findings

### KD-001 - Major - E2E suite could test the wrong app on localhost:5173

Evidence:
- `npx playwright test --project=chromium --reporter=list` timed out after 4 minutes in Round 1.
- The failure log shows repeated visibility timeouts for basic Kitchen Diary headings.
- `Get-NetTCPConnection -LocalPort 5173` showed port 5173 owned by a Dart/Flutter process, not this Vite app.
- `playwright.config.ts` had `baseURL: http://localhost:5173` and `reuseExistingServer: !process.env.CI`, so local tests could reuse a stale or unrelated app.

Fix:
- Changed Playwright to use dedicated `127.0.0.1:5175` by default, overrideable with `PLAYWRIGHT_PORT`.
- Disabled existing-server reuse so the suite must launch the Kitchen Diary dev server it is about to test.

Status: fixed in code, pending Round 2 verification.

Round 2 verification:
- `npx playwright test --project=chromium --reporter=list` returned `102 passed (2.1m)` against `127.0.0.1:5175`.
- Status: verified fixed.

### KD-002 - Major - Mobile touch targets were too small for repeated core interactions

Evidence:
- Round 3 UX probe on a 375x667 viewport found many active controls below the 44px touch-target guideline.
- Examples included Explore filter at 40x40, tabs at 28px high, category chips at 28-32px high, `Make a Wish` at 32px high, `Cook This` at 40px high, and feed like/share buttons at 16x16.
- Builder category filters were 28px high, and back/share/remove controls were also below the target.

Fix:
- Added a global visible `:focus-visible` outline for controls.
- Increased Explore filter, tab, tag, wish, Cook This, like, and share controls to minimum 44px touch targets.
- Increased Builder back/share/category/detail controls to minimum 44px where practical.
- Replaced visible emoji labels in detail sections with Lucide icons to avoid encoding/display drift and keep the design system consistent.

Status: fixed in code, pending Round 3 verification.

Round 3 verification:
- `ux-probe-after-input-fix.log` reports zero small touch targets for Explore, Builder empty state, and Builder ingredient selection on 375x667.
- `npx tsc --noEmit` exit 0.
- `npm run test:run -- --reporter=verbose` returned 268 passed.
- `npm run build` exit 0.
- `npx playwright test --project=chromium --reporter=list` returned 102 passed.
- Status: verified fixed.

## Remaining Known Risks

- The app is intentionally mobile-first and remains centered in a phone-like shell on desktop. This is strategically consistent with the README's prototype positioning, but it is not a full desktop/tablet adaptive product surface.
- Live recipe/cuisine/profile flows depend on external services. The app has tested fallback behavior, but external API quality and rate limits remain outside repo control.
- Build output includes many generated assets, including some large PNG files. Runtime tests did not find broken images or request failures, and the JS bundle remains moderate, but asset governance should stay part of release review.

