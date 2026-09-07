import { GoogleAuthProvider, User, onAuthStateChanged, signInWithPopup, signOut } from 'firebase/auth';
import { doc, onSnapshot } from 'firebase/firestore';
import { UserProfile } from '../types';
import { getFirebaseAuth, getFirebaseFirestore, isFirebaseConfigured } from './firebase';

type Entitlement = { active?: boolean; currentPeriodEnd?: { toMillis?: () => number } };

const toUserProfile = (user: User, entitlement?: Entitlement): UserProfile => ({
  id: user.uid,
  name: user.displayName?.trim() || 'Kitchen Diary Cook',
  avatar: user.photoURL || '🧑‍🍳',
  bio: 'Cooking with Kitchen Diary.',
  isVip:
    entitlement?.active === true &&
    (entitlement.currentPeriodEnd?.toMillis?.() === undefined ||
      entitlement.currentPeriodEnd.toMillis() > Date.now()),
  vipExpiresAt: entitlement?.currentPeriodEnd?.toMillis?.(),
  favorites: [],
  myRecipes: [],
});

export const getCurrentUser = (): UserProfile | null => {
  if (!isFirebaseConfigured()) return null;
  const user = getFirebaseAuth().currentUser;
  return user ? toUserProfile(user) : null;
};

export const subscribeToAuthState = (callback: (user: UserProfile | null) => void): (() => void) => {
  if (!isFirebaseConfigured()) {
    callback(null);
    return () => undefined;
  }

  let stopEntitlement: (() => void) | undefined;
  const stopAuth = onAuthStateChanged(getFirebaseAuth(), (user) => {
    stopEntitlement?.();
    stopEntitlement = undefined;
    if (!user) {
      callback(null);
      return;
    }

    callback(toUserProfile(user));
    stopEntitlement = onSnapshot(
      doc(getFirebaseFirestore(), 'subscriptionEntitlements', user.uid),
      (snapshot) => callback(toUserProfile(user, snapshot.exists() ? (snapshot.data() as Entitlement) : undefined)),
    );
  });

  return () => {
    stopEntitlement?.();
    stopAuth();
  };
};

export const login = async (): Promise<UserProfile> => {
  const provider = new GoogleAuthProvider();
  provider.setCustomParameters({ prompt: 'select_account' });
  const result = await signInWithPopup(getFirebaseAuth(), provider);
  return toUserProfile(result.user);
};

export const logout = async (): Promise<void> => {
  if (!isFirebaseConfigured()) return;
  await signOut(getFirebaseAuth());
};
