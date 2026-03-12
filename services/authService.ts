import { UserProfile } from '../types';
import { fetchRealProfile, LiveUserProfile } from './liveDataService';

const STORAGE_KEY = 'kitchendiary.user_profile';

const wait = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

const getStorage = (): Storage | null => {
  if (typeof window !== 'undefined' && window.localStorage && typeof window.localStorage.getItem === 'function') {
    return window.localStorage;
  }
  if (typeof globalThis !== 'undefined' && (globalThis as any).localStorage && typeof (globalThis as any).localStorage.getItem === 'function') {
    return (globalThis as any).localStorage as Storage;
  }
  return null;
};

const normalizeProfile = (profile: LiveUserProfile | UserProfile): UserProfile => ({
  id: profile.id,
  name: profile.name,
  avatar: profile.avatar,
  bio: profile.bio,
  favorites: profile.favorites ?? [],
  myRecipes: profile.myRecipes ?? [],
  recipesCount: profile.recipesCount ?? profile.myRecipes?.length,
  followersCount: profile.followersCount,
  likesReceived: profile.likesReceived,
});

const readStoredProfile = (): UserProfile | null => {
  try {
    const storage = getStorage();
    if (!storage) return null;
    const raw = storage.getItem(STORAGE_KEY);
    if (!raw) return null;
    return normalizeProfile(JSON.parse(raw) as UserProfile);
  } catch {
    return null;
  }
};

const writeStoredProfile = (profile: UserProfile): void => {
  const storage = getStorage();
  if (!storage) return;
  storage.setItem(STORAGE_KEY, JSON.stringify(profile));
};

export const getCurrentUser = (): UserProfile | null => readStoredProfile();

export const login = async (): Promise<UserProfile> => {
  const [liveUser] = await Promise.all([fetchRealProfile(), wait(500)]);
  const normalized = normalizeProfile(liveUser);
  writeStoredProfile(normalized);
  return normalized;
};

export const logout = async (): Promise<void> => {
  await wait(250);
  const storage = getStorage();
  if (!storage) return;
  storage.removeItem(STORAGE_KEY);
};

export const updateUserProfile = async (updates: Partial<UserProfile>): Promise<UserProfile> => {
  const existing = readStoredProfile();
  if (!existing) {
    throw new Error('No active user session to update.');
  }

  const updated = normalizeProfile({
    ...existing,
    ...updates,
    favorites: updates.favorites ?? existing.favorites,
    myRecipes: updates.myRecipes ?? existing.myRecipes,
  });

  writeStoredProfile(updated);
  return updated;
};
