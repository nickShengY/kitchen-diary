import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth, type Auth } from 'firebase-admin/auth';
import {
  chefChatWithProvider,
  normalizeChefChatInput,
  type ChefChatInput,
  type ChefChatResult,
} from '../server/chef-chat.js';
import { MenuAnalysisError } from '../server/menu-analysis.js';
import type { ApiRequest, ApiResponse } from './analyze-menu.js';

type HandlerDependencies = {
  verifyToken?: (token: string) => Promise<string>;
  chat?: (input: ChefChatInput & { userId: string }) => Promise<ChefChatResult>;
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
      // Fall back to Firebase's project-ID-only certificate verification.
    }
  }

  return getAuth(initializeApp({ projectId, ...(credential ? { credential } : {}) }));
};

const verifyFirebaseIdToken = async (token: string): Promise<string> => {
  try {
    const decoded = await adminAuth().verifyIdToken(token);
    if (!decoded.uid) throw new Error('Missing Firebase UID');
    return decoded.uid;
  } catch {
    throw new MenuAnalysisError('unauthorized', 401, 'A valid Firebase ID token is required.');
  }
};

const parseBody = (body: unknown): ChefChatInput => {
  if (typeof body === 'string') {
    try {
      return normalizeChefChatInput(JSON.parse(body) as ChefChatInput);
    } catch (error) {
      if (error instanceof MenuAnalysisError) throw error;
    }
  } else if (body && typeof body === 'object' && !Array.isArray(body)) {
    return normalizeChefChatInput(body as ChefChatInput);
  }
  throw new MenuAnalysisError('invalid_request', 400, 'A cooking question is required.');
};

export const createChefChatHandler = (dependencies: HandlerDependencies = {}) => {
  const verifyToken = dependencies.verifyToken ?? verifyFirebaseIdToken;
  const chat = dependencies.chat ?? ((input: ChefChatInput & { userId: string }) =>
    chefChatWithProvider(input));

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
      const input = parseBody(req.body);
      const result = await chat({ ...input, userId });
      send(res, 200, result);
    } catch (error) {
      const safe = error instanceof MenuAnalysisError
        ? error
        : new MenuAnalysisError('provider_request_failed', 502, 'AI Chef is temporarily unavailable.');
      send(res, safe.status, { error: safe.message, code: safe.code });
    }
  };
};

export default createChefChatHandler();
