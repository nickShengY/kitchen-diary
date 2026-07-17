import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { defineSecret, defineString } from "firebase-functions/params";
import { HttpsError, onRequest } from "firebase-functions/v2/https";
import type { Request } from "firebase-functions/v2/https";
import type { Response } from "firebase-functions/v1";
import Stripe from "stripe";

initializeApp();

const allowedOrigin = defineString("ALLOWED_ORIGIN");
const monthlyPriceId = defineString("STRIPE_MONTHLY_PRICE_ID");
const annualPriceId = defineString("STRIPE_ANNUAL_PRICE_ID");
const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");
const stripeWebhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");

type Plan = "monthly" | "annual";
type CheckoutRequest = { plan?: Plan; successUrl?: string; cancelUrl?: string };

function cors(req: Request, res: Response): boolean {
  const origin = req.get("origin");
  const configuredOrigin = allowedOrigin.value();
  if (origin && origin !== configuredOrigin) {
    res.status(403).json({ error: "Origin is not allowed." });
    return false;
  }
  if (origin) res.set("Access-Control-Allow-Origin", configuredOrigin);
  res.set("Vary", "Origin");
  res.set("Access-Control-Allow-Headers", "Authorization, Content-Type");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  return true;
}

async function verifiedUid(req: Request): Promise<string> {
  const authorization = req.get("authorization");
  const match = authorization?.match(/^Bearer (.+)$/i);
  if (!match) throw new HttpsError("unauthenticated", "A Firebase ID token is required.");
  const decoded = await getAuth().verifyIdToken(match[1]);
  return decoded.uid;
}

function appUrl(value: string | undefined, fallback: string): string {
  const candidate = value ?? fallback;
  const allowed = allowedOrigin.value();
  if (!candidate.startsWith(`${allowed}/`) && candidate !== allowed) {
    throw new HttpsError("invalid-argument", "Redirect URLs must use the configured app origin.");
  }
  return candidate;
}

export const createStripeCheckoutSession = onRequest(
  { region: "northamerica-northeast1", secrets: [stripeSecretKey] },
  async (req, res) => {
    if (!cors(req, res)) return;
    if (req.method === "OPTIONS") return void res.status(204).send("");
    if (req.method !== "POST") return void res.status(405).json({ error: "POST required." });
    try {
      const uid = await verifiedUid(req);
      const body = (req.body ?? {}) as CheckoutRequest;
      if (body.plan !== "monthly" && body.plan !== "annual") {
        throw new HttpsError("invalid-argument", "Choose monthly or annual.");
      }
      const price = body.plan === "monthly" ? monthlyPriceId.value() : annualPriceId.value();
      const stripe = new Stripe(stripeSecretKey.value());
      const session = await stripe.checkout.sessions.create({
        mode: "subscription",
        line_items: [{ price, quantity: 1 }],
        client_reference_id: uid,
        metadata: { firebaseUid: uid, plan: body.plan },
        subscription_data: { metadata: { firebaseUid: uid, plan: body.plan } },
        success_url: appUrl(body.successUrl, `${allowedOrigin.value()}/billing/success`) + "?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: appUrl(body.cancelUrl, `${allowedOrigin.value()}/billing/cancel`),
      });
      res.status(200).json({ id: session.id, url: session.url });
    } catch (error) {
      const status = error instanceof HttpsError && error.code === "unauthenticated" ? 401 : 400;
      console.error("Checkout session creation failed", error);
      res.status(status).json({ error: "Unable to start checkout." });
    }
  },
);

export const stripeWebhook = onRequest(
  { region: "northamerica-northeast1", secrets: [stripeSecretKey, stripeWebhookSecret] },
  async (req, res) => {
    if (req.method !== "POST") return void res.status(405).send("POST required");
    const signature = req.get("stripe-signature");
    if (!signature) return void res.status(400).send("Missing Stripe signature");
    let event: Stripe.Event;
    try {
      event = new Stripe(stripeSecretKey.value()).webhooks.constructEvent(
        req.rawBody,
        signature,
        stripeWebhookSecret.value(),
      );
    } catch (error) {
      console.error("Invalid Stripe webhook signature", error);
      return void res.status(400).send("Invalid signature");
    }
    try {
      if (event.type.startsWith("customer.subscription.")) {
        const subscription = event.data.object as Stripe.Subscription;
        const uid = subscription.metadata.firebaseUid;
        if (!uid) throw new Error("Subscription has no Firebase UID metadata.");
        await getFirestore().collection("subscriptionEntitlements").doc(uid).set({
          status: subscription.status,
          active: ["active", "trialing"].includes(subscription.status),
          stripeCustomerId: String(subscription.customer),
          stripeSubscriptionId: subscription.id,
          priceId: subscription.items.data[0]?.price.id ?? null,
          currentPeriodEnd: subscription.current_period_end
            ? new Date(subscription.current_period_end * 1000)
            : null,
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
      }
      res.status(200).json({ received: true });
    } catch (error) {
      console.error("Stripe webhook processing failed", error);
      res.status(500).send("Webhook processing failed");
    }
  },
);
