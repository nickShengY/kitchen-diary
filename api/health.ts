import type { ApiRequest, ApiResponse } from './analyze-menu.js';

type HealthCheck = {
  configured: boolean;
};

type HealthPayload = {
  ok: boolean;
  service: 'kitchen-diary-api';
  provider: 'openrouter' | 'unconfigured';
  checks: {
    firebase: HealthCheck;
    ai: HealthCheck;
    webOrigin: HealthCheck;
  };
  timestamp: string;
};

const isConfigured = (value: string | undefined): boolean => Boolean(value?.trim());

/**
 * Lightweight, secret-free production probe used by the web and Flutter
 * clients. It checks only that the configuration needed by the API bridges is
 * present; it never calls a provider or returns credential material.
 */
export default function healthHandler(req: ApiRequest, res: ApiResponse): void {
  res.setHeader('Cache-Control', 'no-store');
  res.setHeader('Content-Type', 'application/json; charset=utf-8');

  if (req.method !== 'GET') {
    res.setHeader('Allow', 'GET');
    void res.status(405).json({ error: 'GET required.', code: 'invalid_request' });
    return;
  }

  const checks = {
    firebase: {
      configured: isConfigured(
        process.env.KITCHEN_DIARY_FIREBASE_PROJECT_ID
          ?? process.env.VITE_FIREBASE_PROJECT_ID,
      ),
    },
    ai: {
      configured: isConfigured(process.env.OPENROUTER_API_KEY),
    },
    webOrigin: {
      configured: isConfigured(process.env.KITCHEN_DIARY_WEB_ORIGIN),
    },
  };
  const ok = Object.values(checks).every((check) => check.configured);
  const payload: HealthPayload = {
    ok,
    service: 'kitchen-diary-api',
    provider: checks.ai.configured ? 'openrouter' : 'unconfigured',
    checks,
    timestamp: new Date().toISOString(),
  };
  void res.status(ok ? 200 : 503).json(payload);
}
