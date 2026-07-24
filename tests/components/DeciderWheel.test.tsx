import { describe, it, expect, vi, beforeEach, Mock } from 'vitest';
import { render, screen, waitFor, fireEvent, act } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { DeciderWheel } from '../../components/DeciderWheel';
import { CUISINE_CATEGORIES } from '../../data/kitchenData';

vi.mock('../../services/geminiService', () => ({
  analyzeMenuImage: vi.fn(),
  getFoodDescription: vi.fn(),
}));

vi.mock('../../services/liveDataService', () => ({
  fetchCuisineWheelData: vi.fn(),
}));

import { analyzeMenuImage, getFoodDescription } from '../../services/geminiService';
import { fetchCuisineWheelData } from '../../services/liveDataService';

describe('DeciderWheel Component', () => {
  const mockCuisines = [
    { id: 'it', name: 'Italian', emoji: '🍝', dishes: ['Carbonara', 'Lasagna'] },
    { id: 'mx', name: 'Mexican', emoji: '🌮', dishes: ['Tacos', 'Burrito'] },
  ];

  beforeEach(() => {
    vi.useFakeTimers({ shouldAdvanceTime: true });
    (fetchCuisineWheelData as Mock).mockReset();
    (analyzeMenuImage as Mock).mockReset();
    (getFoodDescription as Mock).mockReset();
    (fetchCuisineWheelData as Mock).mockResolvedValue(mockCuisines);
    (analyzeMenuImage as Mock).mockResolvedValue([{ name: 'Pad Thai' }]);
    (getFoodDescription as Mock).mockResolvedValue('Sweet and savory noodles.');
  });

  it('loads and renders live cuisines', async () => {
    render(<DeciderWheel />);

    await waitFor(() => {
      expect(screen.getByText('Italian')).toBeInTheDocument();
      expect(screen.getByText('Mexican')).toBeInTheDocument();
    });
  });

  it('completes cuisine to dish spin flow', async () => {
    const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime });
    render(<DeciderWheel />);

    await screen.findByText('Italian');
    await user.click(screen.getByRole('button', { name: /spin cuisine/i }));
    await act(async () => {
      await vi.advanceTimersByTimeAsync(3000);
    });

    const findDishButton = await screen.findByRole('button', { name: /find a dish/i });
    await user.click(findDishButton);
    await user.click(screen.getByRole('button', { name: /spin dish/i }));
    await act(async () => {
      await vi.advanceTimersByTimeAsync(3000);
    });

    await waitFor(() => {
      expect(screen.getByText(/bon app/i)).toBeInTheDocument();
    });
  });

  it('supports adding cuisine in edit modal', async () => {
    const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime });
    render(<DeciderWheel />);

    await screen.findByText('Italian');
    await user.click(screen.getByText('Customize Wheel'));
    const input = screen.getByPlaceholderText('Add new cuisine...');
    await user.type(input, 'Korean');
    fireEvent.submit(input.closest('form')!);

    await waitFor(() => {
      expect(screen.getAllByText('Korean').length).toBeGreaterThan(0);
    });
  });

  it('falls back to the built-in cuisine catalog when live loading fails', async () => {
    (fetchCuisineWheelData as Mock).mockRejectedValueOnce(new Error('network down'));

    render(<DeciderWheel />);

    await waitFor(() => {
      expect(
        screen.getByText('Spinning with our starter cuisines today!'),
      ).toBeInTheDocument();
    });

    expect(screen.getByText(CUISINE_CATEGORIES[0].name)).toBeInTheDocument();
  });

  it('supports scan mode result flow', async () => {
    const user = userEvent.setup({ advanceTimers: vi.advanceTimersByTime });
    render(<DeciderWheel />);

    await user.click(screen.getByRole('button', { name: /^Scan$/ }));
    const input = document.querySelector('input[type="file"]') as HTMLInputElement;
    const file = new File(['test'], 'menu.jpg', { type: 'image/jpeg' });
    Object.defineProperty(input, 'files', { value: [file] });
    fireEvent.change(input);

    await waitFor(() => {
      expect(screen.getByText('Pad Thai')).toBeInTheDocument();
    });
  });
});
