import React, { useEffect, useState } from 'react';
import { subscribeToAuthState } from '../services/authService';
import type { UserProfile } from '../types';

export const BillingReturn = ({ mode, onContinue }: { mode: 'success' | 'cancel' | 'manage'; onContinue: () => void }) => {
  const [user, setUser] = useState<UserProfile | null | undefined>(undefined);
  useEffect(() => subscribeToAuthState(setUser), []);
  const title = mode === 'cancel' ? 'Checkout closed'
    : user === null ? 'Sign in to check access'
    : user?.billingStatus === 'error' ? "We couldn't confirm access"
    : user?.billingStatus === 'loading' || user === undefined ? 'Checking your Plus access'
    : user?.isVip ? 'Your Plus access is active'
    : mode === 'manage' ? 'Your Plus access is inactive' : 'Waiting for confirmation';
  const message = mode === 'cancel'
    ? 'You left checkout. Your access only changes when our payment service confirms your subscription.'
    : user === undefined ? 'Loading your account…'
    : user === null ? 'Sign in with the same Google account used for checkout to check your subscription.'
    : user.billingStatus === 'loading' ? 'Checking your subscription with our payment service…'
    : user.billingStatus === 'error' ? 'We could not check your subscription right now. Return to your profile to try again, or contact support. If you were charged, do not buy another plan.'
    : user.isVip ? 'Your account has confirmed Plus access. You can return to your kitchen.'
    : mode === 'manage' ? 'Your account currently has no active Plus access. Your profile shows the latest confirmed subscription status.'
    : 'Your account has not confirmed active Plus access yet. Confirmation can take a little time. Check your profile again shortly; if you were charged, do not buy another plan. Contact support if access does not appear.';
  return <main className="toon-atmosphere min-h-screen px-6 py-16 text-toon-dark">
    <section className="mx-auto max-w-md rounded-3xl bg-white p-6 shadow-sm">
      <h1 className="text-2xl font-bold">{title}</h1>
      <p role="status" className="mt-4 text-base leading-relaxed text-gray-600">{message}</p>
      <button onClick={onContinue} className="mt-6 w-full rounded-xl bg-toon-primary px-4 py-3 font-bold text-toon-dark focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-toon-dark">Go to my profile</button>
      <a href="/support" className="mt-4 block text-center underline">Contact support</a>
    </section>
  </main>;
};
