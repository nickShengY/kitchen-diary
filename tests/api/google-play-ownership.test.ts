import { afterEach, describe, expect, it, vi } from 'vitest';
import { generateKeyPairSync } from 'node:crypto';
import type { Firestore } from 'firebase-admin/firestore';
import { googlePlayAccountId, validateGooglePlayAccountBinding, verifyAndPersistGooglePlayPurchase } from '../../server/google-play';

function store() {
  const records = new Map<string, Record<string, unknown>>();
  let queue = Promise.resolve();
  const db = {
    collection: (name: string) => ({
      doc: (id: string) => ({ path: `${name}/${id}` }),
      where: (_field: string, _op: string, hash: string) => ({ hash }),
    }),
    runTransaction: (action: (tx: unknown) => Promise<void>) => {
      const run = queue.then(async () => {
        const writes: Array<() => void> = [];
        await action({
          get: async (ref: {path?: string; hash?: string}) => ref.path
            ? { exists: records.has(ref.path), data: () => records.get(ref.path!) }
            : { docs: [...records].filter(([path, data]) => path.startsWith('subscriptionEntitlements/') && data.purchaseTokenHash === ref.hash).map(([path]) => ({ id: path.split('/')[1] })) },
          set: (ref: {path: string}, data: Record<string, unknown>, options: {merge: boolean}) => {
            expect(options.merge).toBe(true);
            writes.push(() => records.set(ref.path, {...records.get(ref.path), ...data}));
          },
        });
        writes.forEach(write => write());
      });
      queue = run.catch(() => {});
      return run;
    },
  } as unknown as Firestore;
  return {db, records};
}
const input = (userId: string) => ({userId, productId: 'kitchendiary_premium_monthly', purchaseToken: 'test-token'});
const readSubscription = async () => ({expiry: new Date('2030-01-01'), active: true, orderId: 'test-order'});
afterEach(() => { vi.unstubAllGlobals(); vi.unstubAllEnvs(); });

describe('Play account ownership', () => {
  it('rejects the real Publisher response for another verified user before storage', async () => {
    const {privateKey} = generateKeyPairSync('rsa', {modulusLength: 2048});
    vi.stubEnv('KITCHEN_DIARY_GOOGLE_PLAY_SERVICE_ACCOUNT_JSON', JSON.stringify({
      client_email: 'mock@example.invalid', private_key: privateKey.export({type:'pkcs8',format:'pem'}),
    }));
    const request = vi.fn()
      .mockResolvedValueOnce(new Response(JSON.stringify({access_token:'mock-token'})))
      .mockResolvedValueOnce(new Response(JSON.stringify({
        externalAccountIdentifiers:{obfuscatedExternalAccountId:googlePlayAccountId('owner')},
        subscriptionState:'SUBSCRIPTION_STATE_ACTIVE',
        lineItems:[{productId:input('other').productId,expiryTime:'2030-01-01T00:00:00Z'}],
      })));
    vi.stubGlobal('fetch', request);
    const {db, records} = store();
    await expect(verifyAndPersistGooglePlayPurchase(input('other'), {db})).rejects.toThrow('another account');
    expect(request).toHaveBeenCalledTimes(2);
    expect(records.size).toBe(0);
  });
  it('matches native UTF8 FNV1a and rejects a different or malformed binding', () => {
    expect(googlePlayAccountId('hello')).toBe('4f9f2cab');
    expect(() => validateGooglePlayAccountBinding('hello', '4f9f2cab')).not.toThrow();
    expect(() => validateGooglePlayAccountBinding('other', '4f9f2cab')).toThrow();
    expect(() => validateGooglePlayAccountBinding('hello', {})).toThrow();
    expect(() => validateGooglePlayAccountBinding('hello', undefined)).not.toThrow();
  });
  it('serializes competing first claims, preserves fields, and supports owner restore', async () => {
    const {db, records} = store();
    records.set('subscriptionEntitlements/one', {retained: 'yes'});
    const outcomes = await Promise.allSettled(['one', 'two'].map(uid => verifyAndPersistGooglePlayPurchase(input(uid), {db, readSubscription})));
    expect(outcomes.map(x => x.status)).toEqual(['fulfilled', 'rejected']);
    expect(records.get('subscriptionEntitlements/one')?.retained).toBe('yes');
    expect(records.has('subscriptionEntitlements/two')).toBe(false);
    await expect(verifyAndPersistGooglePlayPurchase(input('one'), {db, readSubscription})).resolves.toMatchObject({active:true});
  });
  it('retains legacy token ownership even without a dedicated claim', async () => {
    const {db, records} = store();
    await verifyAndPersistGooglePlayPurchase(input('one'), {db, readSubscription});
    for(const path of records.keys()) if(path.startsWith('googlePlayPurchaseClaims/')) records.delete(path);
    await expect(verifyAndPersistGooglePlayPurchase(input('two'), {db, readSubscription})).rejects.toThrow('already linked');
    expect(records.has('subscriptionEntitlements/two')).toBe(false);
  });
  it('retains the first token owner after their entitlement switches to another token', async () => {
    const {db} = store();
    await verifyAndPersistGooglePlayPurchase(input('one'), {db, readSubscription});
    await verifyAndPersistGooglePlayPurchase({...input('one'), purchaseToken:'replacement-token'}, {db, readSubscription});
    await expect(verifyAndPersistGooglePlayPurchase(input('two'), {db, readSubscription})).rejects.toThrow('already linked');
  });
  it('does not let a delayed notification for an old token overwrite the replacement', async () => {
    const {db, records} = store();
    await verifyAndPersistGooglePlayPurchase(input('one'), {db, readSubscription});
    await verifyAndPersistGooglePlayPurchase({...input('one'), purchaseToken:'replacement-token'}, {db, readSubscription});
    const current = records.get('subscriptionEntitlements/one');
    await verifyAndPersistGooglePlayPurchase(input('one'), {db, readSubscription: async () => ({expiry: null, active: false, orderId: null}), onlyIfCurrentPurchase: true});
    expect(records.get('subscriptionEntitlements/one')).toBe(current);
    expect(current?.active).toBe(true);
  });
});
