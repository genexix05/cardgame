// Importaciones de Firebase
import { initializeApp } from 'firebase/app'
import { 
  getFirestore, 
  enableIndexedDbPersistence, 
  CACHE_SIZE_UNLIMITED, 
  doc,
  getDoc,
  setLogLevel
} from 'firebase/firestore'
import { getAuth } from 'firebase/auth'
import { getStorage } from 'firebase/storage'

// Configuración de Firebase
const firebaseConfig = {
  apiKey: "AIzaSyD6T_Vf-7ShXcbLOMulrVuRGfZE41M9Y-w",
  authDomain: "dragonball-cardgame.firebaseapp.com",
  projectId: "dragonball-cardgame",
  storageBucket: "dragonball-cardgame.appspot.com",
  messagingSenderId: "1074439862642",
  appId: "1:1074439862642:android:cb701f0bff02acb7f3c5eb"
}

// Inicializa Firebase
const firebaseApp = initializeApp(firebaseConfig)

// Aumentar nivel de logging para depuración en desarrollo
if (process.env.NODE_ENV === 'development') {
  setLogLevel('debug');
}

// Inicializa Firestore con configuración básica
const db = getFirestore(firebaseApp);

// Habilitar persistencia con manejo de errores
enableIndexedDbPersistence(db)
  .then(() => {
    console.log('✅ Persistencia habilitada correctamente');
  })
  .catch((err) => {
    if (err.code === 'failed-precondition') {
      console.warn('⚠️ La persistencia no pudo habilitarse: múltiples pestañas abiertas');
    } else if (err.code === 'unimplemented') {
      console.warn('⚠️ La persistencia no está disponible en este navegador');
    } else {
      console.error('❌ Error al habilitar la persistencia:', err);
    }
  });

// Función para comprobar la conectividad de Firestore
const checkFirestoreConnection = async (maxRetries = 5, retryDelay = 5000) => {
  let retries = 0;
  
  const attemptConnection = async () => {
    try {
      // Crear una promesa con tiempo límite
      const timeoutPromise = new Promise((_, reject) => {
        setTimeout(() => reject(new Error('Tiempo de espera agotado al conectar con Firestore')), 20000); // 20 segundos máximo (aumentado de 10s)
      });
      
      console.log(`Intentando verificar conexión a Firestore (intento ${retries+1}/${maxRetries})...`);
      
      // Utilizar cualquier colección que sepamos que existe en nuestra BD
      // Aquí utilizamos 'cards' ya que se menciona en main.js
      const testCollection = 'cards';
      const docRef = doc(db, testCollection, 'any-id');
      
      // Competir entre la operación de Firestore y el tiempo límite
      await Promise.race([
        getDoc(docRef),
        timeoutPromise
      ]);
      
      console.log('✅ Conexión a Firestore establecida correctamente');
      return true;
    } catch (error) {
      retries++;
      
      // Mejorar el mensaje de error con más detalles
      let errorMessage = error.code || error.message || 'Error desconocido';
      console.warn(`❌ Error al conectar con Firestore (${errorMessage})`);
      
      // Manejo específico según el tipo de error
      if (error.code === 'unavailable' || error.message.includes('network error')) {
        console.warn('⚠️ Problema de red detectado. Verifica tu conexión a Internet.');
      } else if (error.code === 'permission-denied') {
        console.warn('⚠️ Problema de permisos. Verifica las reglas de seguridad de Firestore.');
      } else if (error.message.includes('Tiempo de espera agotado')) {
        console.warn('⚠️ Tiempo de espera agotado. El servidor puede estar sobrecargado o tu conexión es lenta.');
      }
      
      // Si alcanzamos el máximo de reintentos, devolvemos false
      if (retries >= maxRetries) {
        console.info('📱 La aplicación funcionará en modo offline con datos en caché');
        return false;
      }
      
      // Esperar antes de reintentar con backoff exponencial
      const backoffDelay = retryDelay * Math.pow(1.5, retries-1); // Aumenta el tiempo entre reintentos
      console.log(`Reintentando en ${(backoffDelay/1000).toFixed(1)} segundos...`);
      await new Promise(resolve => setTimeout(resolve, backoffDelay));
      return attemptConnection();
    }
  };
  
  try {
    return await attemptConnection();
  } catch (error) {
    console.error('Error inesperado al comprobar la conexión:', error);
    return false;
  }
};

// Verificar conexión al iniciar con un pequeño retraso
setTimeout(() => {
  checkFirestoreConnection().catch(err => {
    console.error('Error no capturado al verificar conexión:', err);
  });
}, 3000); // Aumentado a 3 segundos para dar más tiempo a la inicialización

// Crear un sistema de reconexión automática cuando se detecta conexión a Internet
let reconnectionTimer = null;

window.addEventListener('online', () => {
  console.log('🌐 Conexión a Internet detectada, intentando reconectar a Firestore...');
  
  // Limpiar cualquier temporizador existente
  if (reconnectionTimer) {
    clearTimeout(reconnectionTimer);
  }
  
  // Intentar reconexión con un pequeño retraso para estabilizar la conexión
  reconnectionTimer = setTimeout(() => {
    checkFirestoreConnection().catch(err => {
      console.error('Error no capturado al reconectar:', err);
    });
  }, 3000); // Aumentado a 3 segundos para dar más tiempo a la estabilización
});

// Detectar cuando estamos offline
window.addEventListener('offline', () => {
  console.log('🔌 Conexión a Internet perdida, funcionando en modo offline');
});

// Configuración para manejar problemas de CORS con Firebase Storage
const storage = getStorage(firebaseApp);

// Función para crear una URL firmada para acceso a Storage (ayuda con problemas CORS)
const getStorageDownloadUrl = async (storagePath) => {
  try {
    if (!storagePath) return null;
    
    const storageRef = ref(storage, storagePath);
    
    // Configurar opciones para la URL firmada con tiempo de expiración largo
    // y configuración CORS adecuada
    const url = await getDownloadURL(storageRef);
    
    console.log('✅ URL de Storage generada correctamente');
    return url;
  } catch (error) {
    console.error('❌ Error al generar URL de Storage:', error);
    
    // Manejo específico de errores de CORS
    if (error.code === 'storage/cors-error' || 
        error.message?.includes('CORS') || 
        error.code === 'storage/object-not-found') {
      console.warn('⚠️ Error CORS detectado al acceder a Firebase Storage');
      // Intentar devolver una URL alternativa o informar del problema
    }
    
    return null;
  }
};

// Exporta las instancias de Firebase
export { db, checkFirestoreConnection, getStorageDownloadUrl, storage }
export const auth = getAuth(firebaseApp)
export default firebaseApp