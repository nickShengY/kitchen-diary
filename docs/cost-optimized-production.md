# Cost-optimized production setup

KitchenDiary should use Firebase Authentication and Firestore as its only identity/data backend, Firebase Functions for the small trusted payment boundary, and Stripe Checkout for web subscriptions. Do not deploy Neon, RevenueCat, or a browser/mobile Stripe secret.

## Firebase: Google-only authentication and Firestore

1. Create a Firebase project and register the web, Android, and iOS apps.
2. In **Authentication -> Sign-in method**, enable **Google** only. Disable Email/Password and every provider that is not deliberately supported. Configure the OAuth consent screen and authorized domains.
3. Create Firestore in production mode. Make the client read only its own entitlement and never write it; Firebase Admin in Functions bypasses these rules:

```rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /subscriptionEntitlements/{uid} {
      allow read: if request.auth != null && request.auth.uid == uid;
      allow write: if false;
    }
    // Add least-privilege rules for the app's other collections separately.
  }
}
```

4. Enable Firebase App Check for web, Android, and iOS, then enforce it only after monitoring legitimate traffic. App Check complements—never replaces—Firebase Auth and Firestore rules.
5. In Google Cloud Billing, create budget alerts for low thresholds. Alerts notify; they do **not** cap charges. Review Functions, Firestore and network usage regularly.

Firebase Authentication's free/tier behavior, Firestore quota and Functions deployment requirements can change. Check the current Firebase pricing page before launch. Deploying Cloud Functions normally requires the Blaze billing plan; set budget alerts first and keep the function footprint small.

## Stripe Checkout Function

The isolated server code is in `functions/`. It accepts only a Firebase ID token, creates a subscription checkout session for a server-configured monthly or annual Stripe Price ID, and writes entitlements only from a Stripe-signed webhook. The web client must obtain the Firebase user's ID token and send it as `Authorization: Bearer <token>` to `createStripeCheckoutSession`.

Install and validate locally:

```powershell
cd functions
npm install
npm run typecheck
npm run build
```

Install the Firebase CLI, authenticate, and select your project without committing a project id:

```powershell
npm install -g firebase-tools
firebase login
firebase use --add
firebase functions:secrets:set STRIPE_SECRET_KEY
firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
firebase deploy --only functions
```

At deployment, Firebase prompts for these non-secret parameters. Supply the exact public web origin (no trailing slash) and Stripe Price IDs:

- `ALLOWED_ORIGIN` — e.g. `https://app.example.com`
- `STRIPE_MONTHLY_PRICE_ID`
- `STRIPE_ANNUAL_PRICE_ID`

Never use `VITE_` variables for these values or put `STRIPE_SECRET_KEY`/`STRIPE_WEBHOOK_SECRET` in source control. `.env.example` is documentation only.

In Stripe Dashboard, create recurring Prices, then add an endpoint for the deployed `stripeWebhook` URL. Subscribe it at minimum to `customer.subscription.created`, `customer.subscription.updated`, and `customer.subscription.deleted`; copy its signing secret into `STRIPE_WEBHOOK_SECRET`. Test with Stripe test-mode cards and the Stripe CLI before switching live mode.

The endpoint only permits redirect URLs on `ALLOWED_ORIGIN`; use `/billing/success` and `/billing/cancel` routes (or pass same-origin equivalents). It intentionally does not expose a billing portal or accept arbitrary Stripe Price IDs.

Set `VITE_STRIPE_CHECKOUT_ENDPOINT` in the web deployment environment to the deployed `createStripeCheckoutSession` URL. It is safe to expose this URL: the endpoint requires the currently signed-in user's Firebase ID token and retains every Stripe secret server-side.

## Platform policy and cost guardrails

- Stripe Checkout is appropriate for web purchases and physical goods/services. For iOS/Android apps that unlock digital features or subscriptions, Apple and Google Play commonly require their own in-app billing. Confirm the current store policies before shipping a Stripe-only mobile purchase flow.
- Google-only login may require offering Sign in with Apple on iOS unless a current App Store Review Guidelines exception applies.
- Prefer static assets and cached content over per-request AI. If Gemini returns, keep its key server-side, rate-limit requests, impose per-user quotas, and set provider budget alerts.
- Start with Firestore's free allowance, but design queries to avoid unbounded listeners/reads. Avoid duplicate data stores; migrate existing Neon-backed data before decommissioning Neon.
- Use Stripe test mode during development. Stripe has no standard monthly platform fee, but live payments incur per-transaction fees; check current Canada pricing and any international/dispute fees before setting prices.
