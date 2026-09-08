import React, { useEffect, useState } from 'react';
import { subscribeToAuthState } from '../services/authService';
import type { UserProfile } from '../types';

export const BillingReturn = ({ mode, onContinue }: { mode: 'success' | 'cancel' | 'manage'; onContinue: () => void }) => {
  const [user, setUser] = useState<UserProfile | null | undefined>(undefined);
  useEffect(() => subscribeToAuthState(setUser), []);
  const title = user === null ? 'Sign in to check access'
    : user?.billingStatus === 'error' ? "We couldn't confirm access"
    : user?.billingStatus === 'loading' || user === undefined ? 'Checking your Plus access'
    : user?.isVip ? 'Your Plus access is active'
    : 'Your Plus access is inactive';
  const message = user === undefined ? 'Loading your account…'
    : user === null ? 'Sign in with the same Google account you use in Kitchen Diary to check your access.'
    : user.billingStatus === 'loading' ? 'Checking your confirmed account access…'
    : user.billingStatus === 'error' ? 'We could not check your access right now. Return to your profile to try again, or contact support. Do not buy another plan to resolve an access problem.'
    : user.isVip ? 'Your account has confirmed Plus access. You can return to your kitchen.'
    : 'Your account currently has no confirmed Plus access. When Google Play billing is enabled, Restore purchases in the Android app will refresh existing Play access for the same Kitchen Diary account. For help now or a previous web subscription, contact support.';
  return <main className="toon-atmosphere min-h-screen px-6 py-16 text-toon-dark">
    <section className="mx-auto max-w-md rounded-3xl bg-white p-6 shadow-sm">
      <h1 className="text-2xl font-bold">{title}</h1>
      <p role="status" className="mt-4 text-base leading-relaxed text-gray-600">{message}</p>
      <p className="mt-4 text-sm leading-relaxed text-gray-600">Web checkout is no longer available. New subscriptions will use Google Play in the Android app when available. This page does not change your subscription.</p>
      {user?.billingProvider === 'google_play' && <a className="mt-4 block underline" href="https://play.google.com/store/account/subscriptions?package=com.kitchendiary.app">Manage in Google Play</a>}
      <button onClick={onContinue} className="mt-6 w-full rounded-xl bg-toon-primary px-4 py-3 font-bold text-toon-dark focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-toon-dark">Go to my profile</button>
      <a href="/support" className="mt-4 block text-center underline">Contact support</a>
    </section>
  </main>;
};
