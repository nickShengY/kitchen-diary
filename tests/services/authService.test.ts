import { describe, it, expect, vi, beforeEach, afterEach, Mock } from 'vitest';

vi.mock('../../services/liveDataService', () => ({
  fetchRealProfile: vi.fn(),
}));

import { login, logout, updateUserProfile, getCurrentUser } from '../../services/authService';
import { fetchRealProfile } from '../../services/liveDataService';

describe('authService', () => {
  const mockLiveProfile = {
    id: 'live-user-1',
    name: 'Live Chef',
    avatar: '👩‍🍳',
    bio: 'Cooking with real data.',
    favorites: [],
    myRecipes: [],
  };

  beforeEach(() => {
    vi.useFakeTimers();
    const storage = (() => {
      const store = new Map<string, string>();
      return {
        getItem: (key: string) => store.get(key) ?? null,
        setItem: (key: string, value: string) => {
          store.set(key, value);
        },
        removeItem: (key: string) => {
          store.delete(key);
        },
        clear: () => {
          store.clear();
        },
      };
    })();
    (globalThis as any).localStorage = storage;
    if (typeof window !== 'undefined') {
      (window as any).localStorage = storage;
    }
    (fetchRealProfile as Mock).mockReset();
    (fetchRealProfile as Mock).mockResolvedValue(mockLiveProfile);
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('should fetch and persist live user profile on login', async () => {
    const promise = login();
    await vi.advanceTimersByTimeAsync(500);
    const user = await promise;

    expect(fetchRealProfile).toHaveBeenCalledTimes(1);
    expect(user.name).toBe('Live Chef');
    expect(user.followersCount).toBeUndefined();
    expect(user.likesReceived).toBeUndefined();
    expect(getCurrentUser()?.id).toBe('live-user-1');
  });

  it('should clear persisted session on logout', async () => {
    const loginPromise = login();
    await vi.advanceTimersByTimeAsync(500);
    await loginPromise;

    const logoutPromise = logout();
    await vi.advanceTimersByTimeAsync(250);
    await logoutPromise;

    expect(getCurrentUser()).toBeNull();
  });

  it('should update and persist the active user profile', async () => {
    const loginPromise = login();
    await vi.advanceTimersByTimeAsync(500);
    await loginPromise;

    const updated = await updateUserProfile({
      name: 'Updated Chef',
      favorites: ['recipe-1'],
    });

    expect(updated.name).toBe('Updated Chef');
    expect(updated.favorites).toEqual(['recipe-1']);
    expect(getCurrentUser()?.name).toBe('Updated Chef');
  });

  it('should throw when updating profile without an active session', async () => {
    await expect(updateUserProfile({ name: 'No Session' })).rejects.toThrow(
      'No active user session to update.',
    );
  });
});
