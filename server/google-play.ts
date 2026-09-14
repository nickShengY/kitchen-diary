import { createHash, createSign } from 'node:crypto';
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { MenuAnalysisError } from './menu-analysis.js';

export const KITCHEN_DIARY_ANDROID_PACKAGE = 'com.kitchendiary.app';
export const KITCHEN_DIARY_PLAY_PRODUCT_IDS = [
  'kitchendiary_premium_monthly',
  'kitchendiary_premium_yearly',
] as const;

export type GooglePlayVerificationInput = {
  userId: string;
  productId: string;
  purchaseToken: string;
};

export type GooglePlayVerificationResult = {
  active: boolean;
  currentPeriodEnd: string | null;
  productId: string;
  provider: 'google_play';
};

type GooglePlayServiceAccount = {
  client_email?: unknown;
  private_key?: unknown;
};

type GooglePlayLineItem = {
  productId?: unknown;
  expiryTime?: unknown;
};

type GooglePlaySubscription = {
  externalAccountIdentifiers?: { obfuscatedExternalAccountId?: unknown };
  subscriptionState?: unknown;
  lineItems?: unknown;
  latestOrderId?: unknown;
};

const PROJECT_ID = 'kitchen-diary-19971117';
const PLAY_SCOPE = 'https://www.googleapis.com/auth/androidpublisher';
const TOKEN_URL = 'https://oauth2.googleapis.com/token';
const PUBLISHER_URL = 'https://androidpublisher.googleapis.com/androidpublisher/v3';
const ACTIVE_STATES = new Set([
  'SUBSCRIPTION_STATE_ACTIVE',
  'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
  'SUBSCRIPTION_STATE_CANCELED',
]);

const safeString = (value: unknown): string =>
  typeof value === 'string' ? value.trim() : '';

const encodeBase64Url = (value: string): string =>
  Buffer.from(value)
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/g, '');

export const normalizeGooglePlayVerificationInput = (
  value: unknown,
): GooglePlayVerificationInput => {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new MenuAnalysisError(
      'invalid_request',
      400,
      'A Google Play product ID and purchase token are required.',
    );
  }

  const body = value as Record<string, unknown>;
  const productId = safeString(body.productId);
  const purchaseToken = safeString(body.purchaseToken);
  const configuredIds = safeString(process.env.KITCHEN_DIARY_GOOGLE_PLAY_PRODUCT_IDS)
    .split(',')
    .map((id) => id.trim())
    .filter(Boolean);
  const allowedIds = configuredIds.length > 0
    ? configuredIds
    : [...KITCHEN_DIARY_PLAY_PRODUCT_IDS];

  if (!allowedIds.includes(productId)) {
    throw new MenuAnalysisError(
      'invalid_request',
      400,
      'That Google Play plan is not configured for KitchenDiary.',
    );
  }
  if (!purchaseToken || purchaseToken.length > 4096 || /[\u0000-\u001f\u007f]/.test(purchaseToken)) {
    throw new MenuAnalysisError(
      'invalid_request',
      400,
      'A valid Google Play purchase token is required.',
    );
  }

  return { userId: '', productId, purchaseToken };
};

const parseServiceAccount = (): { clientEmail: string; privateKey: string } => {
  const raw = process.env.KITCHEN_DIARY_GOOGLE_PLAY_SERVICE_ACCOUNT_JSON?.trim();
  if (!raw) {
    throw new MenuAnalysisError(
      'provider_unconfigured',
      503,
      'Google Play verification is not configured.',
    );
  }
  try {
    const parsed = JSON.parse(raw) as GooglePlayServiceAccount;
    const clientEmail = safeString(parsed.client_email);
    const privateKey = safeString(parsed.private_key).replace(/\\n/g, '\n');
    if (!clientEmail || !privateKey) throw new Error('Incomplete service account');
    return { clientEmail, privateKey };
  } catch {
    throw new MenuAnalysisError(
      'provider_unconfigured',
      503,
      'Google Play verification is not configured.',
    );
  }
};

const getAccessToken = async (): Promise<string> => {
  const { clientEmail, privateKey } = parseServiceAccount();
  const now = Math.floor(Date.now() / 1000);
  const header = encodeBase64Url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const payload = encodeBase64Url(JSON.stringify({
    iss: clientEmail,
    scope: PLAY_SCOPE,
    aud: TOKEN_URL,
    iat: now,
    exp: now + 3600,
  }));
  const unsigned = `${header}.${payload}`;
  const signer = createSign('RSA-SHA256');
  signer.update(unsigned);
  signer.end();
  const signature = signer.sign(privateKey, 'base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/g, '');

  const response = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: `${unsigned}.${signature}`,
    }),
    signal: AbortSignal.timeout(10_000),
  });
  if (!response.ok) {
    throw new MenuAnalysisError(
      'provider_request_failed',
      502,
      'Google Play verification is temporarily unavailable.',
    );
  }
  const body = await response.json() as { access_token?: unknown };
  const token = safeString(body.access_token);
  if (!token) {
    throw new MenuAnalysisError(
      'provider_request_failed',
      502,
      'Google Play verification is temporarily unavailable.',
    );
  }
  return token;
};

const readSubscription = async (
  productId: string,
  purchaseToken: string,
  userId: string,
): Promise<{ expiry: Date | null; active: boolean; orderId: string | null; accountBound: boolean }> => {
  const accessToken = await getAccessToken();
  const packageName = safeString(process.env.KITCHEN_DIARY_ANDROID_PACKAGE)
    || KITCHEN_DIARY_ANDROID_PACKAGE;
  const url = `${PUBLISHER_URL}/applications/${encodeURIComponent(packageName)}`
    + `/purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`;
  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
    signal: AbortSignal.timeout(10_000),
  });
  if (!response.ok) {
    // Do not distinguish invalid tokens from provider failures to clients.
    throw new MenuAnalysisError(
      response.status === 404 ? 'invalid_request' : 'provider_request_failed',
      response.status === 404 ? 400 : 502,
      response.status === 404
        ? 'The Google Play purchase could not be verified.'
        : 'Google Play verification is temporarily unavailable.',
    );
  }
  const body = await response.json() as GooglePlaySubscription;
  const accountBound = validateGooglePlayAccountBinding(userId, body.externalAccountIdentifiers?.obfuscatedExternalAccountId);
  const lineItems = Array.isArray(body.lineItems)
    ? body.lineItems as GooglePlayLineItem[]
    : [];
  const matchingItem = lineItems.find((item) => safeString(item.productId) === productId);
  if (!matchingItem) {
    throw new MenuAnalysisError(
      'invalid_request',
      400,
      'The Google Play purchase does not match this plan.',
    );
  }
  const expiryText = safeString(matchingItem.expiryTime);
  const expiry = expiryText ? new Date(expiryText) : null;
  const validExpiry = expiry && !Number.isNaN(expiry.getTime()) ? expiry : null;
  const state = safeString(body.subscriptionState);
  const active = ACTIVE_STATES.has(state)
    && validExpiry !== null
    && validExpiry.getTime() > Date.now();
  return {
    expiry: validExpiry,
    active,
    accountBound,
    orderId: safeString(body.latestOrderId) || null,
  };
};

const firebaseFirestore = (): Firestore => {
  const existing = getApps()[0];
  if (existing) return getFirestore(existing);
  const projectId = safeString(process.env.KITCHEN_DIARY_FIREBASE_PROJECT_ID)
    || PROJECT_ID;
  const raw = safeString(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
  if (!raw) {
    throw new MenuAnalysisError(
      'provider_unconfigured',
      503,
      'KitchenDiary entitlement storage is not configured.',
    );
  }
  try {
    const parsed = JSON.parse(raw) as Record<string, unknown>;
    const credentialProjectId = safeString(parsed.project_id);
    const clientEmail = safeString(parsed.client_email);
    const privateKey = safeString(parsed.private_key).replace(/\\n/g, '\n');
    if (credentialProjectId !== projectId || !clientEmail || !privateKey) {
      throw new Error('Wrong Firebase project');
    }
    return getFirestore(initializeApp({
      credential: cert({ projectId, clientEmail, privateKey }),
      projectId,
    }));
  } catch (error) {
    if (error instanceof MenuAnalysisError) throw error;
    throw new MenuAnalysisError(
      'provider_unconfigured',
      503,
      'KitchenDiary entitlement storage is not configured.',
    );
  }
};

export const verifyAndPersistGooglePlayPurchase = async (
  input: GooglePlayVerificationInput,
  dependencies: { db?: Firestore; readSubscription?: typeof readSubscription; onlyIfCurrentPurchase?: boolean } = {},
): Promise<GooglePlayVerificationResult> => {
  if (!input.userId.trim()) throw new MenuAnalysisError('invalid_request', 401, 'A verified account is required.');
  const subscription = await (dependencies.readSubscription ?? readSubscription)(input.productId, input.purchaseToken, input.userId);
  const db = dependencies.db ?? firebaseFirestore();
  const purchaseTokenHash = createHash('sha256')
    .update(input.purchaseToken)
    .digest('hex');
  const entitlement = db.collection('subscriptionEntitlements').doc(input.userId);
  const claim = db.collection('googlePlayPurchaseClaims').doc(purchaseTokenHash);
  await db.runTransaction(async (transaction) => {
    if (dependencies.onlyIfCurrentPurchase) {
      const current = await transaction.get(entitlement);
      // An old plan's delayed notification must not replace a newer purchase.
      if (current.data()?.purchaseTokenHash !== purchaseTokenHash) return;
    }
    const claimed = await transaction.get(claim);
    // Retain ownership established before the dedicated claim collection existed.
    const existing = await transaction.get(db.collection('subscriptionEntitlements')
      .where('purchaseTokenHash', '==', purchaseTokenHash));
    if ((claimed.exists && claimed.data()?.userId !== input.userId)
      || existing.docs.some((owner) => owner.id !== input.userId)) {
      throw new MenuAnalysisError(
        'invalid_request',
        409,
        'This Google Play purchase is already linked to another account.',
      );
    }

    // A provider receipt without an account identifier is NOT proof of who paid.
    // Legacy restore requires a pre-existing server-owned binding, atomically read
    // above. Unclaimed legacy tokens need independently verified support migration;
    // possession of a token or a client-supplied UID is never migration evidence.
    const independentlyOwned = (claimed.exists && claimed.data()?.userId === input.userId)
      || existing.docs.some((owner) => owner.id === input.userId);
    if (!subscription.accountBound && !independentlyOwned) {
      throw new MenuAnalysisError('invalid_request', 403,
        'This legacy purchase has no verified account binding. Contact support to establish ownership.');
    }

    transaction.set(claim, { userId: input.userId }, { merge: true });
    transaction.set(entitlement, {
      active: subscription.active,
      currentPeriodEnd: subscription.expiry ? Timestamp.fromDate(subscription.expiry) : null,
      googlePlayProductId: input.productId,
      googlePlayOrderId: subscription.orderId,
      provider: 'google_play',
      purchaseTokenHash,
      updatedAt: Timestamp.now(),
    }, { merge: true });
  });

  return {
    active: subscription.active,
    currentPeriodEnd: subscription.expiry?.toISOString() ?? null,
    productId: input.productId,
    provider: 'google_play',
  };
};

/** Notifications carry the token; retain only its hash in our database. */
export const refreshGooglePlayPurchase = async (purchaseToken: string): Promise<void> => {
  const db = firebaseFirestore();
  const hash = createHash('sha256').update(purchaseToken).digest('hex');
  const owners = await db.collection('subscriptionEntitlements')
    .where('purchaseTokenHash', '==', hash).limit(1).get();
  const owner = owners.docs[0];
  // First-purchase notifications can arrive before the app registers ownership.
  // The authenticated purchase endpoint will verify and persist that purchase.
  if (!owner) return;
  const productId = safeString(owner.data().googlePlayProductId);
  if (!productId) return;
  await verifyAndPersistGooglePlayPurchase({ userId: owner.id, productId, purchaseToken }, {
    db, onlyIfCurrentPurchase: true,
  });
};

/** Matches the Android client's UTF-8 FNV-1a identifier, not a client claim. */
export const googlePlayAccountId = (uid: string): string => {
  let hash = 2166136261;
  for (const byte of Buffer.from(uid, 'utf8')) hash = Math.imul(hash ^ byte, 16777619) >>> 0;
  return hash.toString(16).padStart(8, '0');
};

export const validateGooglePlayAccountBinding = (uid: string, binding: unknown): boolean => {
  // False requires independent legacy ownership inside the storage transaction.
  if (binding == null || binding === '') return false;
  if (typeof binding !== 'string' || binding !== googlePlayAccountId(uid)) {
    throw new MenuAnalysisError('invalid_request', 403, 'This Google Play purchase belongs to another account.');
  }
  return true;
};
