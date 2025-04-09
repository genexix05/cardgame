import { getFirestore, collection, doc, getDoc, getDocs, updateDoc, query, orderBy, limit } from 'firebase/firestore';
import { db } from '@/firebase';

const state = {
  users: [],
  currentUser: null,
  userCards: [],
  userActivity: [],
  loading: false,
  error: null
};

const getters = {
  getUsers: (state) => state.users,
  getCurrentUser: (state) => state.currentUser,
  getUserCards: (state) => state.userCards,
  getUserActivity: (state) => state.userActivity,
  isLoading: (state) => state.loading,
  getError: (state) => state.error
};

const actions = {
  async fetchUsers({ commit }) {
    try {
      commit('SET_LOADING', true);
      commit('SET_ERROR', null);
      
      const usersRef = collection(db, 'users');
      const usersSnapshot = await getDocs(usersRef);
      const users = [];
      
      usersSnapshot.forEach(doc => {
        const userData = doc.data();
        users.push({
          id: doc.id,
          ...userData,
          registrationDate: userData.registrationDate?.toDate() || new Date(),
          lastLogin: userData.lastLogin?.toDate() || null,
          stats: userData.stats || {
            cardsCount: 0,
            packsOpened: 0
          }
        });
      });
      
      commit('SET_USERS', users);
    } catch (error) {
      console.error('Error al cargar usuarios:', error);
      commit('SET_ERROR', 'Error al cargar la lista de usuarios');
      throw error;
    } finally {
      commit('SET_LOADING', false);
    }
  },

  async fetchUserDetails({ commit }, userId) {
    try {
      commit('SET_LOADING', true);
      commit('SET_ERROR', null);
      
      const userRef = doc(db, 'users', userId);
      const userDoc = await getDoc(userRef);
      
      if (!userDoc.exists()) {
        throw new Error('Usuario no encontrado');
      }
      
      // Obtener datos de packOpenings
      const packOpeningsRef = collection(db, 'users', userId, 'packOpenings');
      const packOpeningsSnapshot = await getDocs(packOpeningsRef);
      
      let packsOpened = 0;
      let cardsObtained = 0;
      
      packOpeningsSnapshot.forEach(doc => {
        const data = doc.data();
        packsOpened++;
        if (data.cards) {
          cardsObtained += data.cards.length;
        }
      });
      
      const userData = userDoc.data();
      const user = {
        id: userDoc.id,
        ...userData,
        registrationDate: userData.registrationDate?.toDate() || new Date(),
        lastLogin: userData.lastLogin?.toDate() || null,
        stats: {
          cardsCount: cardsObtained,
          packsOpened: packsOpened
        }
      };
      
      commit('SET_CURRENT_USER', user);
      return user;
    } catch (error) {
      console.error('Error al cargar detalles del usuario:', error);
      commit('SET_ERROR', 'Error al cargar los detalles del usuario');
      throw error;
    } finally {
      commit('SET_LOADING', false);
    }
  },

  async fetchUserCards({ commit }, userId) {
    try {
      commit('SET_LOADING', true);
      commit('SET_ERROR', null);
      
      // Obtener todas las cartas de los packOpenings
      const packOpeningsRef = collection(db, 'users', userId, 'packOpenings');
      const packOpeningsSnapshot = await getDocs(packOpeningsRef);
      
      const cards = [];
      packOpeningsSnapshot.forEach(doc => {
        const data = doc.data();
        if (data.cards && Array.isArray(data.cards)) {
          data.cards.forEach(card => {
            cards.push({
              id: card.id,
              ...card,
              timestamp: data.timestamp?.toDate() || new Date()
            });
          });
        }
      });
      
      commit('SET_USER_CARDS', cards);
      return cards;
    } catch (error) {
      console.error('Error al cargar cartas del usuario:', error);
      commit('SET_ERROR', 'Error al cargar las cartas del usuario');
      throw error;
    } finally {
      commit('SET_LOADING', false);
    }
  },

  async fetchUserActivity({ commit }, userId) {
    try {
      commit('SET_LOADING', true);
      commit('SET_ERROR', null);
      
      const packOpeningsRef = collection(db, 'users', userId, 'packOpenings');
      const q = query(packOpeningsRef, orderBy('timestamp', 'desc'), limit(10));
      const packOpeningsSnapshot = await getDocs(q);
      
      const activity = [];
      packOpeningsSnapshot.forEach(doc => {
        const data = doc.data();
        activity.push({
          id: doc.id,
          type: 'pack_open',
          timestamp: data.timestamp?.toDate() || new Date(),
          data: {
            packName: data.packName || 'Sobre',
            cardCount: data.cards?.length || 0
          }
        });
      });
      
      commit('SET_USER_ACTIVITY', activity);
      return activity;
    } catch (error) {
      console.error('Error al cargar actividad del usuario:', error);
      commit('SET_ERROR', 'Error al cargar la actividad del usuario');
      throw error;
    } finally {
      commit('SET_LOADING', false);
    }
  },

  async updateUserRole({ commit }, { userId, role }) {
    try {
      const db = getFirestore();
      const userRef = doc(db, 'users', userId);
      await updateDoc(userRef, {
        role: role,
        updatedAt: new Date()
      });
    } catch (error) {
      console.error('Error al actualizar rol del usuario:', error);
      throw error;
    }
  },

  async toggleUserStatus({ commit }, { userId, disabled }) {
    try {
      const db = getFirestore();
      const userRef = doc(db, 'users', userId);
      await updateDoc(userRef, {
        disabled: disabled,
        updatedAt: new Date()
      });
    } catch (error) {
      console.error('Error al cambiar estado del usuario:', error);
      throw error;
    }
  }
};

const mutations = {
  SET_USERS(state, users) {
    state.users = users;
  },
  SET_CURRENT_USER(state, user) {
    state.currentUser = user;
  },
  SET_USER_CARDS(state, cards) {
    state.userCards = cards;
  },
  SET_USER_ACTIVITY(state, activity) {
    state.userActivity = activity;
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