import React, { useState } from 'react';
import { AppView } from '../types';
import { landingHtml } from '../content/discovery.mjs';

interface LandingPageProps {
  onNavigate: (view: AppView) => void;
  onSignIn: () => Promise<void>;
}

export function LandingPage({ onNavigate, onSignIn }: LandingPageProps) {
  const [signingIn, setSigningIn] = useState(false);
  const [signInError, setSignInError] = useState(false);
  const handleClick = async (event: React.MouseEvent<HTMLDivElement>) => {
    const link = (event.target as Element).closest('a');
    if (!link || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return;
    const view = link.getAttribute('data-view');
    if (view && Object.values(AppView).includes(view as AppView)) {
      event.preventDefault();
      onNavigate(view as AppView);
    } else if (link.hasAttribute('data-sign-in')) {
      event.preventDefault();
      if (signingIn) return;
      setSigningIn(true);
      setSignInError(false);
      try { await onSignIn(); } catch { setSignInError(true); } finally { setSigningIn(false); }
    }
  };
  return <>
    {signingIn && <p role="status">Opening sign-in…</p>}
    {signInError && <p className="landing-sign-in-error" role="status">Sign-in could not be opened. Please try again.</p>}
    {/* This trusted, authored HTML is also rendered at build time for visitors without JavaScript. */}
    <div onClick={handleClick} dangerouslySetInnerHTML={{ __html: landingHtml }} />
  </>;
}
