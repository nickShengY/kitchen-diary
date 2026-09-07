import { describe, expect, it, vi } from 'vitest';
import { createChefChatHandler } from '../../api/chef-chat';
import { MenuAnalysisError } from '../../server/menu-analysis';
import type { ApiRequest, ApiResponse } from '../../api/analyze-menu';

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
  body: { message: 'What can I cook?', pantry: ['rice', 'onion'] },
  ...overrides,
});

describe('chef-chat Vercel handler', () => {
  it('requires a Firebase bearer token before touching the provider', async () => {
    const verifyToken = vi.fn();
    const chat = vi.fn();
    const response = makeResponse();

    await createChefChatHandler({ verifyToken, chat })(request({ headers: {} }), response);

    expect(response.status).toHaveBeenCalledWith(401);
    expect(response.json).toHaveBeenCalledWith({
      error: 'A Firebase ID token is required.',
      code: 'unauthorized',
    });
    expect(verifyToken).not.toHaveBeenCalled();
    expect(chat).not.toHaveBeenCalled();
  });

  it('passes the verified user and normalized conversation to the provider', async () => {
    const verifyToken = vi.fn().mockResolvedValue('firebase-user-1');
    const chat = vi.fn().mockResolvedValue({
      provider: 'openrouter',
      reply: 'Try a quick fried rice.',
    });
    const response = makeResponse();

    await createChefChatHandler({ verifyToken, chat })(request(), response);

    expect(chat).toHaveBeenCalledWith({
      userId: 'firebase-user-1',
      message: 'What can I cook?',
      pantry: ['rice', 'onion'],
      history: [],
    });
    expect(response.status).toHaveBeenCalledWith(200);
    expect(response.json).toHaveBeenCalledWith({
      provider: 'openrouter',
      reply: 'Try a quick fried rice.',
    });
  });

  it('rejects blank questions and keeps provider errors safe', async () => {
    const response = makeResponse();
    const chat = vi.fn();
    const handler = createChefChatHandler({
      verifyToken: vi.fn().mockResolvedValue('firebase-user-1'),
      chat,
    });

    await handler(request({ body: { message: '   ' } }), response);
    expect(response.status).toHaveBeenCalledWith(400);
    expect(response.json).toHaveBeenCalledWith({
      error: 'A cooking question is required.',
      code: 'invalid_request',
    });
    expect(chat).not.toHaveBeenCalled();

    const providerResponse = makeResponse();
    chat.mockRejectedValue(new MenuAnalysisError(
      'provider_unconfigured',
      503,
      'AI Chef is not configured. Try the built-in recipe catalog instead.',
    ));
    await handler(request(), providerResponse);
    expect(providerResponse.status).toHaveBeenCalledWith(503);
    expect(providerResponse.json).toHaveBeenCalledWith({
      error: 'AI Chef is not configured. Try the built-in recipe catalog instead.',
      code: 'provider_unconfigured',
    });
  });

  it('handles preflight and method checks', async () => {
    const handler = createChefChatHandler({
      verifyToken: vi.fn().mockResolvedValue('firebase-user-1'),
      chat: vi.fn(),
    });
    const optionsResponse = makeResponse();
    await handler(request({ method: 'OPTIONS' }), optionsResponse);
    expect(optionsResponse.status).toHaveBeenCalledWith(204);

    const methodResponse = makeResponse();
    await handler(request({ method: 'GET' }), methodResponse);
    expect(methodResponse.status).toHaveBeenCalledWith(405);
    expect(methodResponse.json).toHaveBeenCalledWith({
      error: 'POST required.',
      code: 'invalid_request',
    });
  });
});
