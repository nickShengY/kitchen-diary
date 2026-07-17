import { GoogleAuthProvider, User, onAuthStateChanged, signInWithPopup, signOut } from 'firebase/auth';
import { UserProfile } from '../types';
import { getFirebaseAuth, isFirebaseConfigured } from './firebase';

const toUserProfile = (user: User): UserProfile => ({
  id: user.uid,
  name: user.displayName?.trim() || 'Kitchen Diary Cook',
  avatar: user.photoURL || '🧑‍🍳',
  bio: 'Cooking with Kitchen Diary.',
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

  return onAuthStateChanged(getFirebaseAuth(), (user) => callback(user ? toUserProfile(user) : null));
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
