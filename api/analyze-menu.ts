import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth, type Auth } from 'firebase-admin/auth';
import {
  analyzeMenuImageWithProvider,
  MenuAnalysisError,
  normalizeImageData,
  type MenuAnalysisInput,
  type MenuAnalysisResult,
} from '../server/menu-analysis.js';

export type ApiRequest = {
  method?: string;
  headers?: Record<string, string | string[] | undefined>;
  body?: unknown;
};

export type ApiResponse = {
  setHeader: (name: string, value: string) => void;
  status: (code: number) => ApiResponse;
  json: (payload: unknown) => unknown;
  end: (body?: string) => unknown;
};

type AnalyzeMenuInput = MenuAnalysisInput & { userId: string };

type HandlerDependencies = {
  verifyToken?: (token: string) => Promise<string>;
  analyze?: (input: AnalyzeMenuInput) => Promise<MenuAnalysisResult>;
};

type ServiceAccount = {
  project_id?: unknown;
  client_email?: unknown;
  private_key?: unknown;
};

const KITCHEN_DIARY_PROJECT_ID = 'kitchen-diary-19971117';

const getHeader = (req: ApiRequest, name: string): string => {
  const headers = req.headers ?? {};
  const value = headers[name] ?? headers[name.toLowerCase()];
  return Array.isArray(value) ? value[0] ?? '' : value ?? '';
};

const responseError = (error: unknown): { status: number; code: string; message: string } => {
  if (error instanceof MenuAnalysisError) {
    return { status: error.status, code: error.code, message: error.message };
  }
  return {
    status: 502,
    code: 'provider_request_failed',
    message: 'Menu image analysis is temporarily unavailable.',
  };
};

const sendJson = (res: ApiResponse, status: number, payload: unknown): void => {
  void res.status(status).json(payload);
};

const adminAuth = (): Auth => {
  const existingApp = getApps()[0];
  if (existingApp) return getAuth(existingApp);

  const projectId = process.env.KITCHEN_DIARY_FIREBASE_PROJECT_ID?.trim()
    || process.env.VITE_FIREBASE_PROJECT_ID?.trim()
    || KITCHEN_DIARY_PROJECT_ID;
  const rawCredentials = process.env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim();
  let credential: ReturnType<typeof cert> | undefined;
  if (rawCredentials) {
    try {
      const credentials = JSON.parse(rawCredentials) as ServiceAccount;
      const credentialProjectId = typeof credentials.project_id === 'string' ? credentials.project_id : '';
      const clientEmail = typeof credentials.client_email === 'string' ? credentials.client_email : '';
      const privateKey = typeof credentials.private_key === 'string'
        ? credentials.private_key.replace(/\\n/g, '\n')
        : '';

      // Never let a credential from another Firebase project validate
      // KitchenDiary tokens under the wrong audience. Public certificate
      // verification below is sufficient and avoids requiring a server key.
      if (credentialProjectId === projectId && clientEmail && privateKey) {
        credential = cert({ projectId, clientEmail, privateKey });
      }
    } catch {
      // Optional service-account JSON is ignored when malformed; the
      // project-ID-only verifier remains the safe default.
    }
  }

  const app = initializeApp({ projectId, ...(credential ? { credential } : {}) });
  return getAuth(app);
};

export const verifyFirebaseIdToken = async (token: string): Promise<string> => {
  try {
    const decoded = await adminAuth().verifyIdToken(token);
    if (!decoded.uid) throw new Error('Missing Firebase UID');
    return decoded.uid;
  } catch (error) {
    if (error instanceof MenuAnalysisError) throw error;
    throw new MenuAnalysisError('unauthorized', 401, 'A valid Firebase ID token is required.');
  }
};

const parseBody = (body: unknown): Record<string, unknown> => {
  if (typeof body === 'string') {
    try {
      const parsed = JSON.parse(body) as unknown;
      if (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) {
        return parsed as Record<string, unknown>;
      }
    } catch {
      // Fall through to the same safe invalid-request response.
    }
  } else if (body && typeof body === 'object' && !Array.isArray(body)) {
    return body as Record<string, unknown>;
  }

  throw new MenuAnalysisError('invalid_request', 400, 'A JSON image payload is required.');
};

export const createAnalyzeMenuHandler = (
  dependencies: HandlerDependencies = {},
) => {
  const verifyToken = dependencies.verifyToken ?? verifyFirebaseIdToken;
  const analyze = dependencies.analyze ?? ((input: AnalyzeMenuInput) => analyzeMenuImageWithProvider(input));

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
      sendJson(res, 405, { error: 'POST required.', code: 'invalid_request' });
      return;
    }

    let userId: string;
    const authorization = getHeader(req, 'authorization');
    const tokenMatch = /^Bearer\s+(.+)$/i.exec(authorization);
    if (!tokenMatch) {
      sendJson(res, 401, { error: 'A Firebase ID token is required.', code: 'unauthorized' });
      return;
    }

    try {
      userId = await verifyToken(tokenMatch[1]);
    } catch (error) {
      const safeError = responseError(error);
      sendJson(res, safeError.status === 503 ? 503 : 401, {
        error: safeError.status === 503 ? safeError.message : 'A valid Firebase ID token is required.',
        code: safeError.status === 503 ? safeError.code : 'unauthorized',
      });
      return;
    }

    try {
      const body = parseBody(req.body);
      const imageData = body.imageData ?? body.base64Image ?? body.image;
      if (typeof imageData !== 'string') {
        throw new MenuAnalysisError('invalid_request', 400, 'A base64 menu image is required.');
      }
      const mimeType = typeof body.mimeType === 'string' ? body.mimeType : 'image/jpeg';
      const normalized = normalizeImageData(imageData, mimeType);
      const result = await analyze({
        userId,
        imageData: normalized.data,
        mimeType: normalized.mimeType,
      });
      sendJson(res, 200, { items: result.items, provider: result.provider });
    } catch (error) {
      const safeError = responseError(error);
      sendJson(res, safeError.status, { error: safeError.message, code: safeError.code });
    }
  };
};

export default createAnalyzeMenuHandler();
