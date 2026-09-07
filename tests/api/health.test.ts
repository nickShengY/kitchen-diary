import { afterEach, describe, expect, it, vi } from 'vitest';
import healthHandler from '../../api/health';
import type { ApiRequest, ApiResponse } from '../../api/analyze-menu';

const makeResponse = () => {
  const response = {
    setHeader: vi.fn(),
    status: vi.fn(),
    json: vi.fn(),
  };
  response.status.mockReturnValue(response);
  return response as unknown as ApiResponse & {
    setHeader: ReturnType<typeof vi.fn>;
    status: ReturnType<typeof vi.fn>;
    json: ReturnType<typeof vi.fn>;
  };
};

const request = (method = 'GET'): ApiRequest => ({ method });

describe('KitchenDiary API health probe', () => {
  afterEach(() => vi.unstubAllEnvs());

  it('reports configured bridges without exposing secrets', () => {
    vi.stubEnv('KITCHEN_DIARY_FIREBASE_PROJECT_ID', 'kitchen-diary-19971117');
    vi.stubEnv('OPENROUTER_API_KEY', 'test-secret');
    vi.stubEnv('KITCHEN_DIARY_WEB_ORIGIN', 'https://kitchendiary.robopioneer.ca');
    const response = makeResponse();

    healthHandler(request(), response);

    expect(response.status).toHaveBeenCalledWith(200);
    const payload = response.json.mock.calls[0][0] as Record<string, unknown>;
    expect(payload).toMatchObject({
      ok: true,
      service: 'kitchen-diary-api',
      provider: 'openrouter',
      checks: {
        firebase: { configured: true },
        ai: { configured: true },
        webOrigin: { configured: true },
      },
    });
    expect(JSON.stringify(payload)).not.toContain('test-secret');
  });

  it('returns 503 when a required bridge is not configured', () => {
    vi.stubEnv('KITCHEN_DIARY_FIREBASE_PROJECT_ID', 'kitchen-diary-19971117');
    vi.stubEnv('OPENROUTER_API_KEY', '');
    vi.stubEnv('KITCHEN_DIARY_WEB_ORIGIN', 'https://kitchendiary.robopioneer.ca');
    const response = makeResponse();

    healthHandler(request(), response);

    expect(response.status).toHaveBeenCalledWith(503);
    expect(response.json).toHaveBeenCalledWith(expect.objectContaining({
      ok: false,
      provider: 'unconfigured',
    }));
  });

  it('allows only GET probes', () => {
    const response = makeResponse();

    healthHandler(request('POST'), response);

    expect(response.status).toHaveBeenCalledWith(405);
    expect(response.json).toHaveBeenCalledWith({
      error: 'GET required.',
      code: 'invalid_request',
    });
  });
});
