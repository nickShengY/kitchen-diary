import { OAuth2Client } from 'google-auth-library';
import { KITCHEN_DIARY_ANDROID_PACKAGE, refreshGooglePlayPurchase } from '../../server/google-play.js';
import type { ApiRequest, ApiResponse } from '../analyze-menu.js';

const audience = 'https://kitchendiary.robopioneer.ca/api/google-play/notifications';
const pushIdentity = 'kitchendiary-play-notifications@kitchen-diary-19971117.iam.gserviceaccount.com';
const oidc = new OAuth2Client();

const verifyPush = async (token: string): Promise<void> => {
  const ticket = await oidc.verifyIdToken({ idToken: token, audience });
  const claims = ticket.getPayload();
  if (claims?.email !== pushIdentity || claims.email_verified !== true) {
    throw new Error('Unexpected push identity');
  }
};

type Notification = {
  packageName?: string;
  testNotification?: unknown;
  subscriptionNotification?: { purchaseToken?: string };
  voidedPurchaseNotification?: { purchaseToken?: string };
};

export const createGooglePlayNotificationHandler = (dependencies: {
  verifyPush?: typeof verifyPush;
  refresh?: typeof refreshGooglePlayPurchase;
} = {}) => async (req: ApiRequest, res: ApiResponse): Promise<void> => {
  res.setHeader('Cache-Control', 'no-store');
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    res.status(405).end();
    return;
  }
  const authorization = req.headers?.authorization;
  const token = typeof authorization === 'string' ? /^Bearer\s+(.+)$/i.exec(authorization)?.[1] : undefined;
  try {
    if (!token) throw new Error('Missing push identity');
    await (dependencies.verifyPush ?? verifyPush)(token);
  } catch {
    res.status(401).end();
    return;
  }
  let notification: Notification;
  try {
    const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    if (typeof body?.message?.data !== 'string') throw new Error('Missing message');
    notification = JSON.parse(Buffer.from(body.message.data, 'base64').toString('utf8'));
    if (notification.packageName !== KITCHEN_DIARY_ANDROID_PACKAGE) throw new Error('Wrong app');
  } catch {
    res.status(400).end();
    return;
  }
  if (notification.testNotification) {
    res.status(204).end();
    return;
  }
  const purchaseToken = notification.subscriptionNotification?.purchaseToken
    ?? notification.voidedPurchaseNotification?.purchaseToken;
  if (typeof purchaseToken !== 'string' || !purchaseToken) {
    res.status(400).end();
    return;
  }
  try {
    await (dependencies.refresh ?? refreshGooglePlayPurchase)(purchaseToken);
    res.status(204).end();
  } catch {
    // A non-success response lets Pub/Sub retry a transient Play/Firestore error.
    // Never log the request: its purchase token is a credential.
    res.status(503).end();
  }
};

export default createGooglePlayNotificationHandler();
