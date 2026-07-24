/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./index.html', './App.tsx', './components/**/*.{ts,tsx}', './data/**/*.ts', './services/**/*.ts'],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Quicksand', 'sans-serif'],
        display: ['Fredoka', 'Quicksand', 'sans-serif'],
      },
      colors: {
        'toon-bg': '#FFF5F0',
        'toon-cream': '#FFFAF6',
        'toon-primary': '#FF8E72',
        'toon-primary-deep': '#F2704F',
        'toon-secondary': '#FFC482',
        'toon-accent': '#6EC6CA',
        'toon-accent-deep': '#4FA9AD',
        'toon-dark': '#4A403A',
        'toon-pink': '#FF9EAA',
        'toon-butter': '#F9DC5C',
        'toon-mint': '#9ADBC5',
      },
      boxShadow: {
        'toon-soft': '0 1px 2px rgba(74,64,58,0.05), 0 10px 30px -12px rgba(74,64,58,0.18)',
        'toon-pop': '0 4px 0 rgba(74,64,58,0.9)',
        'toon-glow': '0 0 0 4px rgba(255,142,114,0.18), 0 14px 35px -10px rgba(255,142,114,0.5)',
        'toon-candy': '0 2px 0 rgba(255,255,255,0.6) inset, 0 8px 20px -6px rgba(242,112,79,0.45)',
        'toon-lift': '0 2px 4px rgba(74,64,58,0.06), 0 18px 40px -14px rgba(74,64,58,0.28)',
        'toon-ring': '0 0 0 3px #fff, 0 0 0 5px rgba(255,196,130,0.7), 0 12px 28px -10px rgba(74,64,58,0.25)',
      },
      animation: {
        'bounce-slow': 'bounce 3s infinite',
        wiggle: 'wiggle 1s ease-in-out infinite',
        'spin-slow': 'spin 3s linear infinite',
      },
      keyframes: {
        wiggle: {
          '0%, 100%': { transform: 'rotate(-3deg)' },
          '50%': { transform: 'rotate(3deg)' },
        },
      },
    },
  },
  plugins: [],
};
