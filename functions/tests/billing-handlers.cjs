const { test } = require('node:test');
const assert = require('node:assert/strict');
const Module = require('node:module');
const originalLoad = Module._load;
const state = { record: {}, uid: undefined, customer: undefined, checkoutCalls: 0 };
class HttpsError extends Error { constructor(code, message) { super(message); this.code = code; } }
class Stripe {
  billingPortal = { sessions: { create: async (input) => { state.customer = input.customer; return { url: 'https://billing.stripe.test/session' }; } } };
  checkout = { sessions: { create: async () => { state.checkoutCalls++; return { url: 'https://checkout.stripe.test/session' }; } } };
}
Module._load = function(name, ...args) {
  if (name === 'firebase-admin/app') return { initializeApp() {} };
  if (name === 'firebase-admin/auth') return { getAuth: () => ({ verifyIdToken: async () => ({ uid: 'verified-user' }) }) };
  if (name === 'firebase-admin/firestore') return { FieldValue: {}, getFirestore: () => ({ collection: () => ({ doc: (uid) => { state.uid = uid; return { get: async () => ({ data: () => state.record }) }; } }) }) };
  if (name === 'firebase-functions/params') return { defineSecret: () => ({ value: () => 'test-only' }), defineString: () => ({ value: () => 'https://kitchen.test' }) };
  if (name === 'firebase-functions/v2/https') return { HttpsError, onRequest: (_options, handler) => handler };
  if (name === 'stripe') return Stripe;
  return originalLoad.call(this, name, ...args);
};
const handlers = require(process.env.BILLING_FUNCTIONS_MODULE);
Module._load = originalLoad;
const response = () => ({ code: 200, payload: null, status(code) { this.code = code; return this; }, json(payload) { this.payload = payload; return this; }, set() {}, send() {} });
const request = (authenticated, body = {}) => ({ method: 'POST', body, get: (name) => name === 'authorization' && authenticated ? 'Bearer test-only' : undefined });
test('portal rejects unauthenticated callers before customer lookup', async () => {
  state.uid = undefined; const res = response();
  await handlers.createStripePortalSession(request(false), res);
  assert.equal(res.code, 401); assert.equal(state.uid, undefined);
});
test('portal uses only verified UID customer, ignoring browser supplied customer', async () => {
  state.record = { stripeCustomerId: 'cus_owned', provider: 'stripe' }; const res = response();
  await handlers.createStripePortalSession(request(true, { customer: 'cus_attacker' }), res);
  assert.equal(res.code, 200); assert.equal(state.uid, 'verified-user'); assert.equal(state.customer, 'cus_owned');
});
test('active plan cannot start duplicate checkout', async () => {
  state.record = { active: true }; state.checkoutCalls = 0; const res = response();
  await handlers.createStripeCheckoutSession(request(true, { plan: 'monthly' }), res);
  assert.equal(res.code, 409); assert.equal(state.checkoutCalls, 0);
});
test('Google Play entitlement cannot be managed through Stripe', async () => {
  state.record = { provider: 'google_play', stripeCustomerId: 'cus_old' }; state.customer = undefined; const res = response();
  await handlers.createStripePortalSession(request(true), res);
  assert.equal(res.code, 409); assert.equal(state.customer, undefined);
});
