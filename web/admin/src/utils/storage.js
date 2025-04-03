/**
 * Convierte una URL de Firebase Storage a una URL que pasa por nuestro proxy local
 * para evitar problemas de CORS en desarrollo
 * 
 * @param {string} firebaseStorageUrl - URL original de Firebase Storage
 * @returns {string} URL modificada que usa nuestro proxy
 */
export function getProxiedStorageUrl(firebaseStorageUrl) {
    if (!firebaseStorageUrl) return '';
    
    // Solo aplicar proxy en entorno de desarrollo
    if (process.env.NODE_ENV === 'development') {
      // Si la URL ya apunta a nuestro proxy, no hacer nada
      if (firebaseStorageUrl.includes('/firebase-storage-proxy')) {
        return firebaseStorageUrl;
      }
      
      // Extraer la parte de la ruta después de firebasestorage.googleapis.com
      const urlObj = new URL(firebaseStorageUrl);
      if (urlObj.hostname === 'firebasestorage.googleapis.com') {
        return `/firebase-storage-proxy${urlObj.pathname}${urlObj.search}`;
      }
    }
    
    // En producción o si no es una URL de Firebase Storage, devolver la URL original
    return firebaseStorageUrl;
  }
  
  /**
   * Preparar una URL de imagen para mostrar en la UI, manejando posibles errores
   * 
   * @param {string} imageUrl - URL original de la imagen
   * @param {string} fallbackUrl - URL de respaldo si la original está vacía
   * @returns {string} URL procesada para mostrar
   */
  export function prepareImageUrl(imageUrl, fallbackUrl = '/assets/default-image.png') {
    if (!imageUrl) return fallbackUrl;
    return getProxiedStorageUrl(imageUrl);
  }
  