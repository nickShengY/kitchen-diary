import { describe, expect, it, vi } from 'vitest';
import { createGooglePlayVerifyHandler } from '../../api/google-play/verify-purchase';
import {
  normalizeGooglePlayVerificationInput,
  KITCHEN_DIARY_ANDROID_PACKAGE,
} from '../../server/google-play';
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
  body: { productId: 'kitchendiary_premium_monthly', purchaseToken: 'play-token' },
  ...overrides,
});

describe('Google Play verification contract', () => {
  it('targets the released Android package by default', () => {
    expect(KITCHEN_DIARY_ANDROID_PACKAGE).toBe('com.kitchendiary.app');
  });
  it('accepts only configured product IDs and bounded tokens', () => {
    expect(normalizeGooglePlayVerificationInput({
      productId: 'kitchendiary_premium_yearly',
      purchaseToken: 'token-123',
    })).toEqual({
      userId: '',
      productId: 'kitchendiary_premium_yearly',
      purchaseToken: 'token-123',
    });

    expect(() => normalizeGooglePlayVerificationInput({
      productId: 'other-plan',
      purchaseToken: 'token-123',
    })).toThrowError(MenuAnalysisError);
  });

  it('requires Firebase authentication before verifying a purchase', async () => {
    const verifyToken = vi.fn();
    const verifyPurchase = vi.fn();
    const response = makeResponse();

    await createGooglePlayVerifyHandler({ verifyToken, verifyPurchase })(
      request({ headers: {} }),
      response,
    );

    expect(response.status).toHaveBeenCalledWith(401);
    expect(verifyToken).not.toHaveBeenCalled();
    expect(verifyPurchase).not.toHaveBeenCalled();
  });

  it('passes the verified user and returns only safe entitlement fields', async () => {
    const verifyPurchase = vi.fn().mockResolvedValue({
      active: true,
      currentPeriodEnd: '2030-01-01T00:00:00.000Z',
      productId: 'kitchendiary_premium_monthly',
      provider: 'google_play',
    });
    const response = makeResponse();

    await createGooglePlayVerifyHandler({
      verifyToken: vi.fn().mockResolvedValue('firebase-user-1'),
      verifyPurchase,
    })(request(), response);

    expect(verifyPurchase).toHaveBeenCalledWith({
      userId: 'firebase-user-1',
      productId: 'kitchendiary_premium_monthly',
      purchaseToken: 'play-token',
    });
    expect(response.status).toHaveBeenCalledWith(200);
    expect(response.json).toHaveBeenCalledWith({
      active: true,
      currentPeriodEnd: '2030-01-01T00:00:00.000Z',
      productId: 'kitchendiary_premium_monthly',
      provider: 'google_play',
    });
  });

  it('maps verification failures to safe API errors and handles preflight', async () => {
    const response = makeResponse();
    const handler = createGooglePlayVerifyHandler({
      verifyToken: vi.fn().mockResolvedValue('firebase-user-1'),
      verifyPurchase: vi.fn().mockRejectedValue(
        new MenuAnalysisError(
          'provider_unconfigured',
          503,
          'Google Play verification is not configured.',
        ),
      ),
    });
    await handler(request(), response);
    expect(response.status).toHaveBeenCalledWith(503);
    expect(response.json).toHaveBeenCalledWith({
      error: 'Google Play verification is not configured.',
      code: 'provider_unconfigured',
    });

    const options = makeResponse();
    await handler(request({ method: 'OPTIONS' }), options);
    expect(options.status).toHaveBeenCalledWith(204);
  });
});
