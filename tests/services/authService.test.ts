import { beforeEach, describe, expect, it, vi } from 'vitest';

const firebaseMocks = vi.hoisted(() => ({
  auth: { currentUser: null as any },
  onAuthStateChanged: vi.fn(),
  signInWithPopup: vi.fn(),
  signOut: vi.fn(),
  setCustomParameters: vi.fn(),
  onSnapshot: vi.fn(),
  doc: vi.fn((...parts: string[]) => parts.join('/')),
}));

vi.mock('firebase/auth', () => ({
  GoogleAuthProvider: class { setCustomParameters = firebaseMocks.setCustomParameters; },
  onAuthStateChanged: firebaseMocks.onAuthStateChanged,
  signInWithPopup: firebaseMocks.signInWithPopup,
  signOut: firebaseMocks.signOut,
}));

vi.mock('firebase/firestore', () => ({
  doc: firebaseMocks.doc,
  onSnapshot: firebaseMocks.onSnapshot,
}));

vi.mock('../../services/firebase', () => ({
  getFirebaseAuth: vi.fn(() => firebaseMocks.auth),
  getFirebaseFirestore: vi.fn(() => ({})),
  isFirebaseConfigured: vi.fn(() => true),
}));

import { getCurrentUser, login, logout, subscribeToAuthState } from '../../services/authService';

const firebaseUser = {
  uid: 'google-user-1',
  displayName: 'Google Chef',
  photoURL: 'https://example.com/chef.png',
};

describe('authService', () => {
  beforeEach(() => {
    firebaseMocks.auth.currentUser = null;
    firebaseMocks.onAuthStateChanged.mockReset();
    firebaseMocks.signInWithPopup.mockReset();
    firebaseMocks.signOut.mockReset();
    firebaseMocks.setCustomParameters.mockReset();
    firebaseMocks.onSnapshot.mockReset();
    firebaseMocks.onSnapshot.mockReturnValue(vi.fn());
    firebaseMocks.doc.mockClear();
  });

  it('signs in only through the Firebase Google popup', async () => {
    firebaseMocks.signInWithPopup.mockResolvedValue({ user: firebaseUser });

    await expect(login()).resolves.toMatchObject({ id: 'google-user-1', name: 'Google Chef' });
    expect(firebaseMocks.setCustomParameters).toHaveBeenCalledWith({ prompt: 'select_account' });
    expect(firebaseMocks.signInWithPopup).toHaveBeenCalledWith(firebaseMocks.auth, expect.anything());
  });

  it('maps the active Firebase user without browser storage', () => {
    firebaseMocks.auth.currentUser = firebaseUser;
    expect(getCurrentUser()).toMatchObject({ id: 'google-user-1', avatar: 'https://example.com/chef.png' });
  });

  it('subscribes to Firebase session changes', () => {
    const callback = vi.fn();
    subscribeToAuthState(callback);
    expect(firebaseMocks.onAuthStateChanged).toHaveBeenCalledWith(firebaseMocks.auth, expect.any(Function));
    const listener = firebaseMocks.onAuthStateChanged.mock.calls[0][1];
    listener(firebaseUser);
    expect(callback).toHaveBeenCalledWith(expect.objectContaining({ id: 'google-user-1' }));
  });

  it('hydrates server-authoritative subscription entitlements', () => {
    firebaseMocks.onSnapshot.mockImplementation((_ref: unknown, next: (snapshot: unknown) => void) => {
      next({
        exists: () => true,
        data: () => ({ active: true, currentPeriodEnd: { toMillis: () => 1_900_000_000_000 } }),
      });
      return vi.fn();
    });
    const callback = vi.fn();
    subscribeToAuthState(callback);
    const listener = firebaseMocks.onAuthStateChanged.mock.calls[0][1];
    listener(firebaseUser);
    expect(firebaseMocks.doc).toHaveBeenCalledWith({}, 'subscriptionEntitlements', 'google-user-1');
    expect(callback).toHaveBeenLastCalledWith(expect.objectContaining({ isVip: true, vipExpiresAt: 1_900_000_000_000 }));
  });

  it('signs out through Firebase', async () => {
    await logout();
    expect(firebaseMocks.signOut).toHaveBeenCalledWith(firebaseMocks.auth);
  });
});
