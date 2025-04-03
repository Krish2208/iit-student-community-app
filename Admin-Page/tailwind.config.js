/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'college-primary': '#1E3A8A',
        'college-secondary': '#DBEAFE',
      },
    },
  },
  plugins: [],
}
