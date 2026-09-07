import { describe, expect, it, vi } from 'vitest';
import {
  createAnalyzeMenuHandler,
  type ApiRequest,
  type ApiResponse,
} from '../../api/analyze-menu';
import { MenuAnalysisError } from '../../server/menu-analysis';

const makeResponse = () => {
  const response = {
    setHeader: vi.fn(),
    status: vi.fn(),
    json: vi.fn(),
    end: vi.fn(),
  };
  response.status.mockReturnValue(response);
  return response as unknown as ApiResponse & {
    setHeader: ReturnType<typeof vi.fn>;
    status: ReturnType<typeof vi.fn>;
    json: ReturnType<typeof vi.fn>;
    end: ReturnType<typeof vi.fn>;
  };
};

const request = (overrides: Partial<ApiRequest> = {}): ApiRequest => ({
  method: 'POST',
  headers: { authorization: 'Bearer firebase-test-token' },
  body: { imageData: 'data:image/png;base64,bWVudQ==' },
  ...overrides,
});

describe('analyze-menu Vercel handler', () => {
  it('requires a Firebase bearer token before touching the analyzer', async () => {
    const verifyToken = vi.fn();
    const analyze = vi.fn();
    const response = makeResponse();
    const handler = createAnalyzeMenuHandler({ verifyToken, analyze });

    await handler(request({ headers: {} }), response);

    expect(response.status).toHaveBeenCalledWith(401);
    expect(response.json).toHaveBeenCalledWith({
      error: 'A Firebase ID token is required.',
      code: 'unauthorized',
    });
    expect(verifyToken).not.toHaveBeenCalled();
    expect(analyze).not.toHaveBeenCalled();
  });

  it('passes the verified user and normalized image to the analyzer', async () => {
    const verifyToken = vi.fn().mockResolvedValue('firebase-user-1');
    const analyze = vi.fn().mockResolvedValue({
      provider: 'openrouter',
      items: [{ name: 'Ramen' }],
    });
    const response = makeResponse();
    const handler = createAnalyzeMenuHandler({ verifyToken, analyze });

    await handler(request(), response);

    expect(verifyToken).toHaveBeenCalledWith('firebase-test-token');
    expect(analyze).toHaveBeenCalledWith({
      userId: 'firebase-user-1',
      imageData: 'bWVudQ==',
      mimeType: 'image/png',
    });
    expect(response.status).toHaveBeenCalledWith(200);
    expect(response.json).toHaveBeenCalledWith({
      provider: 'openrouter',
      items: [{ name: 'Ramen' }],
    });
  });

  it('returns safe configuration errors without leaking provider details', async () => {
    const verifyToken = vi.fn().mockResolvedValue('firebase-user-1');
    const analyze = vi.fn().mockRejectedValue(new MenuAnalysisError(
      'provider_unconfigured',
      503,
      'AI menu analysis is not configured. The built-in recipe catalog remains available.',
    ));
    const response = makeResponse();
    const handler = createAnalyzeMenuHandler({ verifyToken, analyze });

    await handler(request(), response);

    expect(response.status).toHaveBeenCalledWith(503);
    expect(response.json).toHaveBeenCalledWith({
      error: 'AI menu analysis is not configured. The built-in recipe catalog remains available.',
      code: 'provider_unconfigured',
    });
  });

  it('handles preflight, methods, and malformed payloads explicitly', async () => {
    const handler = createAnalyzeMenuHandler({
      verifyToken: vi.fn().mockResolvedValue('firebase-user-1'),
      analyze: vi.fn(),
    });

    const optionsResponse = makeResponse();
    await handler(request({ method: 'OPTIONS' }), optionsResponse);
    expect(optionsResponse.status).toHaveBeenCalledWith(204);

    const methodResponse = makeResponse();
    await handler(request({ method: 'GET' }), methodResponse);
    expect(methodResponse.status).toHaveBeenCalledWith(405);
    expect(methodResponse.json).toHaveBeenCalledWith({ error: 'POST required.', code: 'invalid_request' });

    const bodyResponse = makeResponse();
    await handler(request({ body: { imageData: 'not-base64!' } }), bodyResponse);
    expect(bodyResponse.status).toHaveBeenCalledWith(400);
    expect(bodyResponse.json).toHaveBeenCalledWith({
      error: 'The menu image is not valid base64 data.',
      code: 'invalid_image',
    });
  });
});
