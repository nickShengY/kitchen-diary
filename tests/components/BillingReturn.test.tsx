import React from 'react';
import { render, screen, act } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { BillingReturn } from '../../components/BillingReturn';
const state = vi.hoisted(() => ({ callback: undefined as ((user: any) => void) | undefined, stop: vi.fn() }));
vi.mock('../../services/authService', () => ({ subscribeToAuthState: (callback: (user: any) => void) => { state.callback = callback; return state.stop; } }));
describe('checkout return', () => {
  it('distinguishes loading, lookup errors and an inactive portal return', () => {
    render(<BillingReturn mode="manage" onContinue={vi.fn()} />);
    act(() => state.callback?.({ isVip: false, billingStatus: 'loading' }));
    expect(screen.getByText('Checking your Plus access')).toBeInTheDocument();
    act(() => state.callback?.({ isVip: false, billingStatus: 'error' }));
    expect(screen.getByText("We couldn't confirm access")).toBeInTheDocument();
    act(() => state.callback?.({ isVip: false, billingStatus: 'ready' }));
    expect(screen.getByText('Your Plus access is inactive')).toBeInTheDocument();
    expect(screen.getByRole('status')).not.toHaveTextContent('Confirmation can take');
  });
  it('does not trust a success URL and updates only from account entitlement', () => {
    window.history.replaceState(null, '', '/billing/success?session_id=untrusted');
    const view = render(<BillingReturn mode="success" onContinue={vi.fn()} />);
    expect(screen.getByText('Checking your Plus access')).toBeInTheDocument();
    act(() => state.callback?.({ isVip: false }));
    expect(screen.getByRole('status')).toHaveTextContent('do not buy another plan');
    act(() => state.callback?.({ isVip: true }));
    expect(screen.getByText('Your Plus access is active')).toBeInTheDocument();
    view.unmount(); expect(state.stop).toHaveBeenCalled();
  });
  it('requires the checkout account and handles cancellation without claiming a refund', () => {
    const view = render(<BillingReturn mode="success" onContinue={vi.fn()} />);
    act(() => state.callback?.(null));
    expect(screen.getByRole('status')).toHaveTextContent('same Google account');
    view.rerender(<BillingReturn mode="cancel" onContinue={vi.fn()} />);
    expect(screen.getByText('Checkout closed')).toBeInTheDocument();
    expect(screen.getByRole('status')).toHaveTextContent('only changes');
  });
});
