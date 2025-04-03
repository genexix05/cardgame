module.exports = {
  plugins: [
    require('tailwindcss'),
    require('autoprefixer'),
    // Añadimos configuración para optimizar el CSS en producción
    process.env.NODE_ENV === 'production' ? require('cssnano')({ preset: 'default' }) : null
  ].filter(Boolean),
};
  