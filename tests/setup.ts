import '@testing-library/jest-dom';
import { afterEach, vi } from 'vitest';
import { cleanup } from '@testing-library/react';

// Cleanup after each test
afterEach(() => {
  cleanup();
});

// Mock environment variables
vi.stubEnv('API_KEY', 'test-api-key');

// Mock window.matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
});

// Mock IntersectionObserver
class MockIntersectionObserver {
  observe = vi.fn();
  disconnect = vi.fn();
  unobserve = vi.fn();
}
Object.defineProperty(window, 'IntersectionObserver', {
  writable: true,
  value: MockIntersectionObserver,
});

// Mock ResizeObserver
class MockResizeObserver {
  observe = vi.fn();
  disconnect = vi.fn();
  unobserve = vi.fn();
}
Object.defineProperty(window, 'ResizeObserver', {
  writable: true,
  value: MockResizeObserver,
});

// Mock FileReader
class MockFileReader {
  result: string | ArrayBuffer | null = null;
  onloadend: (() => void) | null = null;

  readAsDataURL(blob: Blob) {
    this.result = 'data:image/jpeg;base64,mockbase64data';
    if (this.onloadend) {
      setTimeout(this.onloadend, 0);
    }
  }
}
Object.defineProperty(window, 'FileReader', {
  writable: true,
  value: MockFileReader,
});

// Suppress console errors during tests (optional)
const originalError = console.error;
vi.spyOn(console, 'error').mockImplementation((...args) => {
  // Filter out specific React warnings if needed
  if (typeof args[0] === 'string' && args[0].includes('Warning:')) {
    return;
  }
  originalError.apply(console, args);
});
