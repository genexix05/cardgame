module.exports = {
  lintOnSave: false,
  
  // Configuración de proxy para evitar problemas CORS con Firebase Storage
  devServer: {
    proxy: {
      '/firebase-storage-proxy': {
        target: 'https://firebasestorage.googleapis.com',
        changeOrigin: true,
        pathRewrite: {
          '^/firebase-storage-proxy': ''
        },
        headers: {
          'Access-Control-Allow-Origin': '*'
        }
      }
    }
  }
}