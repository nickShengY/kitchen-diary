# Kitchen Diary / CookToon

Kitchen Diary is a cute, mobile-first recipe builder and cooking community prototype. It lets users browse live recipe inspiration, build step-by-step recipes with ingredients, tools, actions, heat, liquids, timing, cut shapes, and finishing details, and preview generated cooking artwork and motion assets while authoring.

## What Is Actually Wired

- Community feed: loads public recipe data from TheMealDB and supports local filtering, likes, and search.
- Recipe builder: supports prep, cook, and finishing stations with compatible tool/action filtering.
- Ingredient library: includes a broad built-in catalog across produce, proteins, seafood, dairy, grains, legumes, herbs, spices, liquids, and condiments.
- Visual assets: uses the generated `generated/kitchen_asset_pack_v1` PNG/GIF pack and the Flux WebP masters in `generated/kitchen_asset_pack_flux2_v1`.
- Motion previews: shows action or ingredient-transition GIFs in the recipe builder when a step has an action.
- Decider: spins through a built-in cuisine catalog and merges live cuisine data when available. Menu-image AI is intentionally disabled until it has a secure, rate-limited server endpoint.
- Profile: uses Google-only Firebase Authentication when configured.

## External Services

- TheMealDB is used for live community recipes and cuisine data.
- Firebase Authentication provides Google-only sign-in. Configure the public `VITE_FIREBASE_*` values described in `docs/cost-optimized-production.md`.
- Stripe Checkout is available only after deploying the Firebase Function and setting public `VITE_STRIPE_CHECKOUT_ENDPOINT`; secrets stay in Firebase Secrets.
- Browser-side Gemini is deliberately disabled. When live public recipe services fail, the core builder and built-in cuisine library remain usable.

## Run Locally

```powershell
npm install
npm run dev
```

Then open the Vite URL shown in the terminal, usually `http://localhost:5173`.

## Verification

```powershell
npx tsc --noEmit
npm run test:run
npm run build
npx playwright test --project=chromium --reporter=list
```
