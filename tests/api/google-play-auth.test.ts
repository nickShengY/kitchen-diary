import { describe, expect, it, vi } from 'vitest';
const auth = vi.hoisted(() => ({ verifyIdToken: vi.fn() }));
vi.mock('firebase-admin/app', () => ({ getApps: () => [{}], initializeApp: vi.fn(), cert: vi.fn() }));
vi.mock('firebase-admin/auth', () => ({ getAuth: () => auth }));
import { createGooglePlayVerifyHandler } from '../../api/google-play/verify-purchase';
import type { ApiResponse } from '../../api/analyze-menu';

describe('purchase endpoint revocation gate', () => {
  it('checks revocation and rejects revoked sessions before purchase storage', async () => {
    auth.verifyIdToken.mockRejectedValue(new Error('auth/id-token-revoked'));
    const response = { setHeader: vi.fn(), status: vi.fn(), json: vi.fn(), end: vi.fn() };
    response.status.mockReturnValue(response);
    const verifyPurchase = vi.fn();
    await createGooglePlayVerifyHandler({verifyPurchase})({method:'POST',headers:{authorization:'Bearer test-token'},body:{productId:'kitchendiary_premium_monthly',purchaseToken:'fixture'}}, response as unknown as ApiResponse);
    expect(auth.verifyIdToken).toHaveBeenCalledWith('test-token', true);
    expect(response.status).toHaveBeenCalledWith(401);
    expect(verifyPurchase).not.toHaveBeenCalled();
  });
});
