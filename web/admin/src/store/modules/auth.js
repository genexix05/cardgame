import { getAuth, signInWithEmailAndPassword, onAuthStateChanged, setPersistence, browserLocalPersistence, browserSessionPersistence } from 'firebase/auth';
import { getFirestore, doc, getDoc } from 'firebase/firestore';
import { auth, db } from '@/firebase';

const state = {
  user: null,
  loading: true,
  error: null
};

const getters = {
  isAuthenticated: (state) => !!state.user,
  isAdmin: (state) => state.user?.role === 'admin',
  currentUser: (state) => state.user
};

const actions = {
  async login({ commit }, { email, password, remember }) {
    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      
      // Obtener datos adicionales del usuario desde Firestore
      const userDoc = await getDoc(doc(db, 'users', userCredential.user.uid));
      
      if (!userDoc.exists()) {
        throw new Error('Usuario no encontrado en la base de datos');
      }
      
      const userData = userDoc.data();
      
      // Verificar si el usuario es admin
      if (userData.role !== 'admin') {
        await auth.signOut();
        throw new Error('No tienes permisos para acceder al panel de administración');
      }
      
      commit('SET_USER', {
        ...userCredential.user,
        ...userData
      });
      
      // Configurar persistencia de sesión
      if (remember) {
        await setPersistence(auth, browserLocalPersistence);
      } else {
        await setPersistence(auth, browserSessionPersistence);
      }
      
    } catch (error) {
      console.error('Error en login:', error);
      let message = 'Error al iniciar sesión';
      
      switch (error.code) {
        case 'auth/invalid-credential':
          message = 'Credenciales inválidas';
          break;
        case 'auth/user-not-found':
          message = 'Usuario no encontrado';
          break;
        case 'auth/wrong-password':
          message = 'Contraseña incorrecta';
          break;
        case 'auth/too-many-requests':
          message = 'Demasiados intentos. Intenta más tarde';
          break;
        default:
          message = error.message || 'Error al iniciar sesión';
      }
      
      throw new Error(message);
    }
  },
  
  async checkAuth({ commit }) {
    try {
      const auth = getAuth();
      
      return new Promise((resolve) => {
        onAuthStateChanged(auth, async (user) => {
          if (user) {
            // Obtener datos adicionales del usuario
            const db = getFirestore();
            const userDoc = await getDoc(doc(db, 'users', user.uid));
            
            if (userDoc.exists()) {
              const userData = userDoc.data();
              commit('SET_USER', {
                ...user,
                ...userData
              });
              
              // Si no es admin, cerrar sesión
              if (userData.role !== 'admin') {
                await auth.signOut();
                commit('SET_USER', null);
              }
            } else {
              await auth.signOut();
              commit('SET_USER', null);
            }
          } else {
            commit('SET_USER', null);
          }
          
          commit('SET_LOADING', false);
          resolve();
        });
      });
    } catch (error) {
      console.error('Error al verificar autenticación:', error);
      commit('SET_USER', null);
      commit('SET_LOADING', false);
    }
  },
  
  async logout({ commit }) {
    try {
      const auth = getAuth();
      await auth.signOut();
      commit('SET_USER', null);
    } catch (error) {
      console.error('Error al cerrar sesión:', error);
      throw error;
    }
  }
};

const mutations = {
  SET_USER(state, user) {
    state.user = user;
  },
  SET_LOADING(state, loading) {
    state.loading = loading;
  },
  SET_ERROR(state, error) {
    state.error = error;
  }
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations
}; 