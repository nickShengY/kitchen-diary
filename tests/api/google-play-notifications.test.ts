import { describe, expect, it, vi } from 'vitest';
import { createGooglePlayNotificationHandler } from '../../api/google-play/notifications';
import type { ApiRequest, ApiResponse } from '../../api/analyze-menu';

const request = (payload: unknown): ApiRequest => ({
  method: 'POST', headers: { authorization: 'Bearer signed-push-token' },
  body: { message: { data: Buffer.from(JSON.stringify(payload)).toString('base64') } },
});
const response = () => {
  const result = { setHeader: vi.fn(), status: vi.fn(), end: vi.fn(), json: vi.fn() };
  result.status.mockReturnValue(result);
  return result;
};
const notice = { packageName: 'com.kitchendiary.app', subscriptionNotification: { purchaseToken: 'purchase-token' } };

describe('authenticated Play notifications', () => {
  it('rejects an invalid identity before processing a notification', async () => {
    const refresh = vi.fn();
    const res = response();
    await createGooglePlayNotificationHandler({ verifyPush: async () => { throw new Error('wrong identity'); }, refresh })(request(notice), res as ApiResponse);
    expect(res.status).toHaveBeenCalledWith(401);
    expect(refresh).not.toHaveBeenCalled();
  });
  it('accepts a Play test message without touching entitlements', async () => {
    const refresh = vi.fn();
    const res = response();
    await createGooglePlayNotificationHandler({ verifyPush: async () => {}, refresh })(request({ packageName: 'com.kitchendiary.app', testNotification: { version: '1.0' } }), res);
    expect(res.status).toHaveBeenCalledWith(204);
    expect(refresh).not.toHaveBeenCalled();
  });
  it.each(['subscriptionNotification', 'voidedPurchaseNotification'])('rechecks Play for %s', async (kind) => {
    const refresh = vi.fn().mockResolvedValue(undefined);
    const res = response();
    await createGooglePlayNotificationHandler({ verifyPush: async () => {}, refresh })(request({ packageName: 'com.kitchendiary.app', [kind]: { purchaseToken: 'purchase-token' } }), res);
    expect(refresh).toHaveBeenCalledWith('purchase-token');
    expect(res.status).toHaveBeenCalledWith(204);
  });
  it('does not acknowledge a provider failure, allowing delivery retry', async () => {
    const res = response();
    await createGooglePlayNotificationHandler({ verifyPush: async () => {}, refresh: async () => { throw new Error('provider unavailable'); } })(request(notice), res);
    expect(res.status).toHaveBeenCalledWith(503);
  });
  it('rejects another app even with an authenticated push identity', async () => {
    const refresh = vi.fn();
    const res = response();
    await createGooglePlayNotificationHandler({ verifyPush: async () => {}, refresh })(request({ ...notice, packageName: 'other.app' }), res);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(refresh).not.toHaveBeenCalled();
  });
});
