import { getApps, initializeApp, cert } from 'firebase-admin/app';
import { getAuth, type Auth } from 'firebase-admin/auth';
import {
  normalizeGooglePlayVerificationInput,
  verifyAndPersistGooglePlayPurchase,
  type GooglePlayVerificationInput,
  type GooglePlayVerificationResult,
} from '../../server/google-play.js';
import { MenuAnalysisError } from '../../server/menu-analysis.js';
import type { ApiRequest, ApiResponse } from '../analyze-menu.js';

type HandlerDependencies = {
  verifyToken?: (token: string) => Promise<string>;
  verifyPurchase?: (input: GooglePlayVerificationInput) => Promise<GooglePlayVerificationResult>;
};

type ServiceAccount = {
  project_id?: unknown;
  client_email?: unknown;
  private_key?: unknown;
};

const PROJECT_ID = 'kitchen-diary-19971117';

const header = (req: ApiRequest, name: string): string => {
  const value = req.headers?.[name] ?? req.headers?.[name.toLowerCase()];
  return Array.isArray(value) ? value[0] ?? '' : value ?? '';
};

const send = (res: ApiResponse, status: number, payload: unknown): void => {
  void res.status(status).json(payload);
};

const adminAuth = (): Auth => {
  const existing = getApps()[0];
  if (existing) return getAuth(existing);
  const projectId = process.env.KITCHEN_DIARY_FIREBASE_PROJECT_ID?.trim() || PROJECT_ID;
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim();
  let credential: ReturnType<typeof cert> | undefined;
  if (raw) {
    try {
      const values = JSON.parse(raw) as ServiceAccount;
      const credentialProjectId = typeof values.project_id === 'string' ? values.project_id : '';
      const clientEmail = typeof values.client_email === 'string' ? values.client_email : '';
      const privateKey = typeof values.private_key === 'string'
        ? values.private_key.replace(/\\n/g, '\n')
        : '';
      if (credentialProjectId === projectId && clientEmail && privateKey) {
        credential = cert({ projectId, clientEmail, privateKey });
      }
    } catch {
      // Firebase certificate verification remains the safe fallback for auth.
    }
  }
  return getAuth(initializeApp({ projectId, ...(credential ? { credential } : {}) }));
};

const verifyFirebaseIdToken = async (token: string): Promise<string> => {
  try {
    const decoded = await adminAuth().verifyIdToken(token, true);
    if (!decoded.uid) throw new Error('Missing Firebase UID');
    return decoded.uid;
  } catch {
    throw new MenuAnalysisError('unauthorized', 401, 'A valid Firebase ID token is required.');
  }
};

const parseBody = (body: unknown): unknown => {
  if (typeof body === 'string') {
    try {
      return JSON.parse(body) as unknown;
    } catch {
      return null;
    }
  }
  return body;
};

export const createGooglePlayVerifyHandler = (
  dependencies: HandlerDependencies = {},
) => {
  const verifyToken = dependencies.verifyToken ?? verifyFirebaseIdToken;
  const verifyPurchase = dependencies.verifyPurchase ?? verifyAndPersistGooglePlayPurchase;

  return async (req: ApiRequest, res: ApiResponse): Promise<void> => {
    res.setHeader('Cache-Control', 'no-store');
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    const configuredOrigin = process.env.KITCHEN_DIARY_WEB_ORIGIN?.trim();
    if (configuredOrigin) {
      res.setHeader('Access-Control-Allow-Origin', configuredOrigin);
      res.setHeader('Vary', 'Origin');
      res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
      res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    }
    if (req.method === 'OPTIONS') {
      void res.status(204).end();
      return;
    }
    if (req.method !== 'POST') {
      res.setHeader('Allow', 'POST, OPTIONS');
      send(res, 405, { error: 'POST required.', code: 'invalid_request' });
      return;
    }

    const match = /^Bearer\s+(.+)$/i.exec(header(req, 'authorization'));
    if (!match) {
      send(res, 401, { error: 'A Firebase ID token is required.', code: 'unauthorized' });
      return;
    }

    let userId: string;
    try {
      userId = await verifyToken(match[1]);
    } catch {
      send(res, 401, { error: 'A valid Firebase ID token is required.', code: 'unauthorized' });
      return;
    }

    try {
      const input = normalizeGooglePlayVerificationInput(parseBody(req.body));
      const result = await verifyPurchase({ ...input, userId });
      send(res, 200, result);
    } catch (error) {
      const safe = error instanceof MenuAnalysisError
        ? error
        : new MenuAnalysisError(
            'provider_request_failed',
            502,
            'Google Play verification is temporarily unavailable.',
          );
      send(res, safe.status, { error: safe.message, code: safe.code });
    }
  };
};

export default createGooglePlayVerifyHandler();
