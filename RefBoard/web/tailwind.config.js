/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{vue,js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: '#3B82F6',
        accent: '#10B981',
        warning: '#F59E0B',
        bg: '#0F172A',
      },
    },
  },
  plugins: [],
}
