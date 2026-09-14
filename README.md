# Kitchen Diary

Kitchen Diary is a cute, mobile-first recipe builder and cooking community prototype. It lets users browse live recipe inspiration, tell the app what is in their kitchen and get back dishes they can actually make, build step-by-step recipes with ingredients, tools, actions, heat, liquids, timing, cut shapes, and finishing details, and preview generated cooking artwork and motion assets while authoring.

## What Is Actually Wired

- Kitchen (pantry matcher): pick the ingredients and cookware you have and get ranked dishes from a built-in corpus of 59 recipes in `data/pantryRecipes.ts`. Three strictness modes (Flexible / Exact / Survival), a "Tonight's Menu" roll that balances courses and pins dishes you like, a shopping list of what is still missing, and one-tap hand-off into the recipe builder with real steps, tools, and settings. Selections, favorites, and cook history persist in `localStorage`.
- Community feed: loads public recipe data from TheMealDB and supports local filtering, likes, and search.
- Recipe builder: supports prep, cook, and finishing stations with compatible tool/action filtering.
- Ingredient library: includes a broad built-in catalog across produce, proteins, seafood, dairy, grains, legumes, herbs, spices, liquids, and condiments.
- Visual assets: uses the generated `generated/kitchen_asset_pack_v1` PNG/GIF pack and the Flux WebP masters in `generated/kitchen_asset_pack_flux2_v1`.
- Motion previews: shows action or ingredient-transition GIFs in the recipe builder when a step has an action.
- Decider: spins through a built-in cuisine catalog and merges live cuisine data when available. Menu-image AI is intentionally disabled until it has a secure, rate-limited server endpoint.
- Profile: shows Saved / History / Cookbook for this device — saved dishes and cook history come from the Kitchen tab, the cookbook from recipes shared to the community. These stay reachable without an account because they are device-local; Google-only Firebase Authentication layers the account card and settings on top when configured.

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
