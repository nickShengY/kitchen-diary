import { deleteOwnedData, deletionServices } from '../server/account-deletion.js';
import type { ApiRequest, ApiResponse } from './analyze-menu.js';

type Identity = { uid: string; auth_time: number };
type Dependencies = {
  enabled?: () => boolean;
  verify?: (token: string) => Promise<Identity>;
  removeData?: (uid: string) => Promise<void>;
  removeIdentity?: (uid: string) => Promise<void>;
  now?: () => number;
};
export const createDeleteAccountHandler = (dependencies: Dependencies = {}) => async (req: ApiRequest, res: ApiResponse): Promise<void> => {
  res.setHeader('Cache-Control', 'no-store');
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  if (req.method !== 'POST') { res.setHeader('Allow', 'POST'); res.status(405).json({ error: 'POST required' }); return; }
  // Enable only after the deletion-marker Firestore rules have been deployed.
  if (!(dependencies.enabled?.() ?? process.env.KITCHEN_DIARY_ACCOUNT_DELETION_ENABLED === 'true')) {
    res.status(503).json({ error: 'Account deletion is temporarily unavailable. Please contact support.' }); return;
  }
  const header = req.headers?.authorization;
  const token = /^Bearer (\S+)$/i.exec(typeof header === 'string' ? header : '')?.[1];
  if (!token) { res.status(401).json({ error: 'Sign in again to delete your account' }); return; }
  let identity: Identity;
  try {
    identity = await (dependencies.verify ?? (token => deletionServices().auth.verifyIdToken(token, true)))(token);
    const now = (dependencies.now?.() ?? Date.now()) / 1000;
    if (!identity.uid || !Number.isFinite(identity.auth_time) || identity.auth_time > now + 60 || now - identity.auth_time > 300) throw new Error('Recent authentication required');
  } catch { res.status(401).json({ error: 'Sign in again to delete your account' }); return; }
  let body = req.body;
  if (typeof body === 'string') { try { body = JSON.parse(body); } catch { body = null; } }
  if (!body || typeof body !== 'object' || (body as Record<string, unknown>).confirmation !== 'DELETE') {
    res.status(400).json({ error: 'Explicit deletion confirmation required' }); return;
  }
  try {
    // The client can never select a UID; only the verified token controls ownership.
    await (dependencies.removeData ?? (uid => deleteOwnedData(uid, deletionServices().db)))(identity.uid);
    await (dependencies.removeIdentity ?? (uid => deletionServices().auth.deleteUser(uid)))(identity.uid);
    res.status(200).json({ deleted: true });
  } catch {
    res.status(503).json({ error: 'Deletion did not finish. Please retry. Billing records may be retained and store subscriptions must be cancelled separately.' });
  }
};
export default createDeleteAccountHandler();
