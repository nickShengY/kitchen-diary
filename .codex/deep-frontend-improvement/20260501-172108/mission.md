Kitchen Diary deep frontend improvement mission

Goal:
- Improve the whole app experience with special focus on the recipe builder.
- Make the existing generated kitchen asset pack and motion library visible in the actual workflow.
- Keep the app honest: only claim capabilities that are wired into the product.
- Preserve the cute, lightweight, high-quality Kitchen Diary direction.

Current app:
- React + Vite web app.
- Main local command: npm run dev.
- Baseline verification before edits: npm run test:run passed 265 tests; npx tsc --noEmit passed.

Current asset inventory:
- generated/ has 608 WebP, 546 PNG, 187 GIF, 5 JSON, 2 logs, 1 txt.
- generated/kitchen_asset_pack_v1 contains modular ingredient/tool/action PNGs plus action, block, cuisine, transition, and sprite GIFs.

Required skills used:
- deep-frontend-improvement-loop
- webapp-testing
- ui-ux-pro-max
- kitchen-animation-crafter

Constraints:
- Do not revert existing dirty worktree changes.
- Use the approved generated asset pack over placeholders.
- Keep motion assets centered, cute, readable, lightweight, and in-app friendly.
