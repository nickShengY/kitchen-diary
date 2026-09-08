import { getFirebaseAuth } from './firebase';

const checkoutEndpoint = import.meta.env.VITE_STRIPE_CHECKOUT_ENDPOINT?.trim();
const portalEndpoint = import.meta.env.VITE_STRIPE_PORTAL_ENDPOINT?.trim();

export const isStripeCheckoutConfigured = (): boolean => Boolean(checkoutEndpoint);
export const isStripePortalConfigured = (): boolean => Boolean(portalEndpoint);

export const openStripePortal = async (): Promise<void> => {
  if (!portalEndpoint) throw new Error('Subscription management is not configured yet. Please contact support.');
  const user = getFirebaseAuth().currentUser;
  if (!user) throw new Error('Sign in with Google before managing your subscription.');
  const response = await fetch(portalEndpoint, {
    method: 'POST',
    headers: { Authorization: `Bearer ${await user.getIdToken()}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({}),
  });
  const payload = await response.json().catch(() => ({})) as { url?: string; error?: string };
  if (!response.ok || !payload.url) throw new Error(payload.error || 'Unable to open subscription management.');
  window.location.assign(payload.url);
};

export const startStripeCheckout = async (plan: 'monthly' | 'annual' = 'monthly'): Promise<void> => {
  if (!checkoutEndpoint) {
    throw new Error('Web billing is not configured yet.');
  }

  const user = getFirebaseAuth().currentUser;
  if (!user) {
    throw new Error('Sign in with Google before starting checkout.');
  }

  const response = await fetch(checkoutEndpoint, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${await user.getIdToken()}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ plan }),
  });
  const payload = (await response.json().catch(() => ({}))) as { url?: string; error?: string };
  if (!response.ok || !payload.url) {
    throw new Error(payload.error || 'Unable to start secure checkout.');
  }

  window.location.assign(payload.url);
};
