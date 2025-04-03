/** @type {import('tailwindcss').Config} */
// tailwind.config.js
module.exports = {
  content: [
    "./src/**/*.{html,js,vue}",  // Ajusta según tus rutas y extensiones
    "./src/index.html",
  ],
  theme: {
    extend: {
      colors: {
        primary: '#3490dc',
        'primary-dark': '#2779bd',
        secondary: '#ffed4a',
        'secondary-light': '#f9d71c',
      },
    },
  },
  plugins: [],
}

