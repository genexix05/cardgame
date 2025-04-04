/**
 * Utilidades para manejo de imágenes y almacenamiento sin depender de Firebase Storage
 * Almacenamiento de imágenes como base64 en Firestore
 */

/**
 * Convierte un archivo de imagen a una cadena base64
 * 
 * @param {File} file - Archivo de imagen a convertir
 * @returns {Promise<string>} Promesa que resuelve a la cadena base64
 */
export function fileToBase64(file) {
  return new Promise((resolve, reject) => {
    if (!file) {
      reject(new Error("No se proporcionó ningún archivo"));
      return;
    }
    
    // Verificar que sea una imagen y no sea demasiado grande
    if (!file.type.match('image.*')) {
      reject(new Error("El archivo debe ser una imagen"));
      return;
    }
    
    // Límite de 1MB para imágenes en base64 (ajustar según necesidades)
    const MAX_SIZE = 1 * 1024 * 1024; // 1MB
    if (file.size > MAX_SIZE) {
      reject(new Error(`La imagen es demasiado grande. El tamaño máximo es ${MAX_SIZE / 1024 / 1024}MB`));
      return;
    }
    
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = () => resolve(reader.result);
    reader.onerror = error => reject(error);
  });
}

/**
 * Comprime una imagen para reducir su tamaño antes de convertirla a base64
 * 
 * @param {File|string} file - Archivo de imagen a comprimir o URL/Base64 de imagen
 * @param {number} maxWidth - Ancho máximo de la imagen resultante
 * @param {number} quality - Calidad de compresión (0-1)
 * @returns {Promise<string>} Promesa que resuelve a la cadena base64 de la imagen comprimida
 */
export function compressAndConvertToBase64(file, maxWidth = 800, quality = 0.7) {
  return new Promise((resolve, reject) => {
    if (!file) {
      reject(new Error("No se proporcionó ningún archivo"));
      return;
    }
    
    // Si ya es una cadena (base64 o URL), devolverla directamente
    if (typeof file === 'string') {
      if (file.startsWith('data:image')) {
        // Si ya es base64, solo devolvemos
        resolve(file);
        return;
      } else if (file.startsWith('http')) {
        // Si es una URL, la usamos como está
        resolve(file);
        return;
      }
    }
    
    // Si no es un archivo Blob/File, rechazamos
    if (!(file instanceof Blob)) {
      reject(new Error("El archivo debe ser un objeto de tipo Blob o File"));
      return;
    }
    
    const reader = new FileReader();
    reader.readAsDataURL(file);
    reader.onload = event => {
      const img = new Image();
      img.src = event.target.result;
      img.onload = () => {
        // Calcular el nuevo tamaño manteniendo la proporción
        let width = img.width;
        let height = img.height;
        if (width > maxWidth) {
          height = Math.round(height * maxWidth / width);
          width = maxWidth;
        }
        
        // Crear un canvas para dibujar la imagen redimensionada
        const canvas = document.createElement('canvas');
        const ctx = canvas.getContext('2d');
        canvas.width = width;
        canvas.height = height;
        ctx.drawImage(img, 0, 0, width, height);
        
        // Convertir el canvas a base64 con la calidad especificada
        const base64String = canvas.toDataURL(file.type, quality);
        resolve(base64String);
      };
      img.onerror = error => reject(error);
    };
    reader.onerror = error => reject(error);
  });
}

/**
 * Prepara la URL o cadena base64 para mostrar en la UI
 * 
 * @param {string} imageData - URL o cadena base64 de la imagen
 * @param {string} fallbackUrl - URL de respaldo si imageData está vacío
 * @returns {string} - URL o cadena base64 lista para usar en src de imagen
 */
export function prepareImageUrl(imageData, fallbackUrl = '/assets/default-image.png') {
  if (!imageData) return fallbackUrl;
  
  // Si ya es una cadena base64, devolverla directamente
  if (imageData.startsWith('data:image')) {
    return imageData;
  }
  
  // Si es una URL, puede ser una URL externa o una URL de Firebase Storage antigua
  if (imageData.startsWith('http')) {
    // Solo aplicar proxy en entorno de desarrollo para URLs de Firebase Storage
    if (process.env.NODE_ENV === 'development' && 
        imageData.includes('firebasestorage.googleapis.com')) {
      const urlObj = new URL(imageData);
      return `/firebase-storage-proxy${urlObj.pathname}${urlObj.search}`;
    }
    return imageData;
  }
  
  // Si no es base64 ni URL, devolver imagen por defecto
  return fallbackUrl;
}

// Mantener la función original para compatibilidad con código existente
export function getProxiedStorageUrl(firebaseStorageUrl) {
  return prepareImageUrl(firebaseStorageUrl);
}
