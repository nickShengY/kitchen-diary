import { describe, it, expect, vi } from 'vitest';
const auth = vi.hoisted(() => ({ currentUser: null as any }));
vi.mock('../../services/firebase', () => ({ getFirebaseAuth: () => auth }));
describe('portal request', () => {
  it('requires authentication before any request', async () => {
    vi.stubEnv('VITE_STRIPE_PORTAL_ENDPOINT', 'https://example.test/portal');
    vi.resetModules();
    const fetcher = vi.fn(); vi.stubGlobal('fetch', fetcher);
    const { openStripePortal } = await import('../../services/billingService');
    await expect(openStripePortal()).rejects.toThrow('Sign in with Google');
    expect(fetcher).not.toHaveBeenCalled();
  });
  it('sends only authenticated request, never a browser customer id', async () => {
    vi.stubEnv('VITE_STRIPE_PORTAL_ENDPOINT', 'https://example.test/portal');
    vi.resetModules();
    auth.currentUser = { getIdToken: vi.fn().mockResolvedValue('test-token') };
    const fetcher = vi.fn().mockResolvedValue({ ok: false, json: async () => ({ error: 'No web subscription' }) });
    vi.stubGlobal('fetch', fetcher);
    const { openStripePortal } = await import('../../services/billingService');
    await expect(openStripePortal()).rejects.toThrow('No web subscription');
    expect(fetcher).toHaveBeenCalledWith('https://example.test/portal', expect.objectContaining({ headers: expect.objectContaining({ Authorization: 'Bearer test-token' }), body: '{}' }));
  });
});
