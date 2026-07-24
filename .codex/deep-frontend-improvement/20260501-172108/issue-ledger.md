# Issue Ledger

## Fixed

1. Builder nav trap
   - Severity: major
   - Problem: the bottom navigation was visible but non-clickable in Builder, leaving users without a clear way out when Builder was opened from the nav.
   - Fix: kept the bottom navigation interactive in Builder list view.
   - Proof: browser rounds 1-3 all navigate Builder -> Decider -> Profile -> Home.

2. Editor bottom-control obstruction
   - Severity: major
   - Problem: after making the nav usable, the nav could sit above the full-screen step editor and block "Add Step to Recipe" on mobile.
   - Fix: raised the editor layer to `z-[60]` so editor controls sit above the nav while the modal is open.
   - Proof: browser rounds 1-3 all save prep and cook steps successfully.

3. Asset library hidden from authoring flow
   - Severity: major
   - Problem: the app had a rich generated asset library, but the builder mostly behaved like a text/chip editor.
   - Fix: added asset coverage messaging, searchable ingredient filters, generated ingredient/tool/action imagery, and action/transition motion previews.
   - Proof: RecipeBuilder tests cover asset rendering, search, and motion preview; browser rounds capture prep and cook motion screenshots.

4. Product claims were generic and stale
   - Severity: minor
   - Problem: README still described a generic AI Studio app instead of the actual wired Kitchen Diary capabilities.
   - Fix: rewrote README around real local commands, external services, and implemented features.
   - Proof: README now distinguishes wired features from optional Gemini/live-service behavior.

5. Decorative blob animation remained in app shell/theme
   - Severity: polish
   - Problem: the app had background blob decoration and a blob animation token that did not help the workflow.
   - Fix: removed app-shell blob elements and replaced liked-heart blob animation with a normal pulse.
   - Proof: targeted source scan no longer finds active blob usage in the app shell or community interaction.

## Remaining Risks

1. The generated asset repository is intentionally large.
   - Status: accepted for this pass.
   - Note: production build passes, and the Flux import was tightened to raw WebP masters only, but `generated/kitchen_asset_pack_v1` still contributes many PNG/GIF assets because the app now genuinely exposes the animation library.

2. Some external-service flows depend on network and optional credentials.
   - Status: documented.
   - Note: TheMealDB is live-backed; Gemini scan/search fallback requires `VITE_GEMINI_API_KEY`.

