import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import store from './store'
import './assets/css/admin-theme.css'
import 'tailwindcss/tailwind.css'
import { getAuth, onAuthStateChanged } from 'firebase/auth'
import firebaseApp, { db, checkFirestoreConnection } from './firebase'
import { collection, getDocs, limit, query } from 'firebase/firestore'

// Crear la instancia de la app
const app = createApp(App)

// Registrar componentes globales y servicios
app.use(store).use(router)

// Función para detectar si hay bloqueadores que impiden conexiones a Firebase
const detectBlockers = () => {
  // Añadir evento para detectar cuando una solicitud es bloqueada
  window.addEventListener('error', (event) => {
    const target = event.target || event.srcElement;
    if (target && target.tagName === 'LINK' || target.tagName === 'SCRIPT') {
      console.warn('Recurso bloqueado:', target.src || target.href);
    }
  }, true);

  // Comprobar errores específicos que indican bloqueo
  window.addEventListener('unhandledrejection', (event) => {
    if (event.reason && (
        event.reason.message?.includes('ERR_BLOCKED_BY_CLIENT') || 
        event.reason.toString().includes('ERR_BLOCKED_BY_CLIENT')
    )) {
      console.error('Detectado bloqueo por extensión o firewall:', event.reason);
      store.commit('SET_ERROR', 'Se detectó que un bloqueador de contenido está impidiendo la conexión con Firebase. Por favor, desactiva extensiones como AdBlock o revisa tu firewall.');
    }
  });
};

// Función para verificar que Firestore está funcionando después del login
const verifyFirestoreAfterLogin = async (user) => {
  if (!user) return;
  
  console.log('Verificando Firestore después del login...');
  
  try {
    // Primero verificamos la conexión básica
    const connectionResult = await checkFirestoreConnection();
    
    if (!connectionResult) {
      console.warn('La verificación de conexión falló, pero el usuario está autenticado.');
      store.commit('SET_ERROR', 'Has iniciado sesión correctamente, pero hay problemas para acceder a los datos. La aplicación funcionará con funcionalidad limitada.');
      return;
    }
    
    // Intentamos leer una pequeña cantidad de datos para verificar que Firestore realmente funciona
    try {
      const testQuery = query(collection(db, 'cards'), limit(1));
      const testSnapshot = await getDocs(testQuery);
      
      if (testSnapshot.empty) {
        console.log('Firestore está disponible pero la colección está vacía o no tienes permisos');
      } else {
        console.log('Firestore está completamente funcional');
        // Si llegamos aquí, Firestore está funcionando bien, limpiamos cualquier error
        store.commit('SET_ERROR', null);
      }
    } catch (firestoreError) {
      console.error('Error al leer datos de Firestore después del login:', firestoreError);
      
      // Detectar si el error está relacionado con bloqueo por parte del navegador
      if (firestoreError.code === 'unavailable' || firestoreError.message?.includes('ERR_BLOCKED_BY_CLIENT')) {
        store.commit('SET_ERROR', 'Parece que un bloqueador de contenido está impidiendo la conexión con Firebase. Por favor, desactiva extensiones como AdBlock para usar la aplicación.');
      } else if (firestoreError.code === 'permission-denied') {
        store.commit('SET_ERROR', 'Has iniciado sesión, pero no tienes permisos para acceder a los datos requeridos. Contacta al administrador.');
      } else {
        store.commit('SET_ERROR', 'Has iniciado sesión correctamente, pero hay problemas para acceder a los datos. La aplicación funcionará con funcionalidad limitada.');
      }
    }
  } catch (error) {
    console.error('Error durante la verificación de Firestore post-login:', error);
  }
};

// Configuración para manejar errores de Firebase
app.config.errorHandler = (err, vm, info) => {
  console.error('Error de la aplicación:', err)
  console.debug('Información adicional:', info)
  
  // Detectar bloqueo por bloqueadores de anuncios
  if (err.message && err.message.includes('ERR_BLOCKED_BY_CLIENT')) {
    store.commit('SET_ERROR', 'Un bloqueador de contenido está impidiendo que la aplicación funcione correctamente. Por favor, desactiva extensiones como AdBlock.');
    return;
  }
  
  // Manejar errores específicos de Firebase
  if (err.name === 'FirebaseError') {
    console.warn('Error de Firebase detectado:', err.code)
    
    // Manejar tipos específicos de errores
    if (err.code === 'unavailable' || err.code === 'failed-precondition') {
      store.commit('SET_ERROR', 'No se pudo establecer conexión con Firebase. La aplicación funcionará en modo offline si hay datos en caché.')
    } else if (err.code === 'permission-denied') {
      store.commit('SET_ERROR', 'Acceso denegado a Firebase. Por favor, verifica que tienes permisos suficientes.')
    } else if (err.code === 'unauthenticated') {
      console.log('Usuario no autenticado, redirigiendo al login...')
      router.push('/login')
    } else {
      store.commit('SET_ERROR', `Error de Firebase: ${err.message}`)
    }

    // Verificar la conexión si es un error de disponibilidad
    if (err.code === 'unavailable') {
      setTimeout(() => {
        checkFirestoreConnection()
      }, 5000)
    }
  }
}

// Iniciar la detección de bloqueadores
detectBlockers();

// Verificar autenticación antes de montar la app
const auth = getAuth(firebaseApp)
let appMounted = false

onAuthStateChanged(auth, (user) => {
  // Si el usuario no está autenticado y no está en una ruta pública, redirigir a login
  if (!user && router.currentRoute.value.meta.requiresAuth) {
    router.push('/login')
  } else if (user) {
    // Si el usuario está autenticado, verificar que Firestore funciona correctamente
    verifyFirestoreAfterLogin(user);
  }
  
  // Solo montar la app una vez para evitar duplicados
  if (!appMounted) {
    app.mount('#app')
    appMounted = true
    
    // Verificar conexión con Firestore después de montar
    checkFirestoreConnection().catch(err => {
      console.warn('Error al verificar conexión inicial:', err)
    })
  }
})

// Configurar manejo de errores globales
window.addEventListener('error', (event) => {
  console.error('Error global:', event.error)
  
  // Detectar si hay un bloqueador de contenido activo
  if (event.filename && event.filename.includes('firebase') && event.error?.message?.includes('ERR_BLOCKED_BY_CLIENT')) {
    store.commit('SET_ERROR', 'Detectamos que un bloqueador de contenido está impidiendo que Firebase funcione. Por favor, desactiva extensiones como AdBlock.');
    return;
  }
  
  // Manejar errores de conexión de red
  if (event.error && event.error.message && 
      (event.error.message.includes('NetworkError') || 
       event.error.message.includes('network error') ||
       event.error.message.includes('Connection') ||
       event.error.message.includes('timeout'))) {
    store.commit('SET_ERROR', 'Error de red detectado. Verifica tu conexión a Internet.')
  }
})

// Escuchar a los eventos de estado de red para intentar reconectar automáticamente
window.addEventListener('online', () => {
  console.log('Conexión a Internet restaurada, intentando reconectar...');
  
  // Limpiar el mensaje de error específico de conexión
  if (store.state.error && 
      (store.state.error.includes('conexión') || 
       store.state.error.includes('Internet') ||
       store.state.error.includes('red'))) {
    store.commit('SET_ERROR', 'Intentando restablecer la conexión...');
    
    // Intentar verificar la conexión después de un breve retraso
    setTimeout(() => {
      checkFirestoreConnection()
        .then(connected => {
          if (connected) {
            store.commit('SET_ERROR', null);
            store.dispatch('fetchStatistics'); // Intentar cargar datos frescos
          }
        })
        .catch(err => console.error('Error en reconexión automática:', err));
    }, 2000);
  }
});

window.addEventListener('offline', () => {
  console.log('Conexión a Internet perdida');
  store.commit('SET_ERROR', 'No hay conexión a Internet. La aplicación funcionará en modo offline con datos en caché.');
});

// Configurar manejo de promesas rechazadas sin capturar
window.addEventListener('unhandledrejection', (event) => {
  console.error('Promesa rechazada sin manejar:', event.reason)
  
  // Manejar errores específicos de Firebase
  if (event.reason && event.reason.code) {
    if (event.reason.code === 'unavailable' || event.reason.code.includes('network')) {
      store.commit('SET_ERROR', 'Error de conexión con Firebase. La aplicación funcionará en modo offline si hay datos en caché.')
    }
  }
})