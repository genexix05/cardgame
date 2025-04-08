import { getFirestore, collection, doc, getDoc, getDocs, updateDoc, query, orderBy, limit } from 'firebase/firestore';

const state = {
  users: [],
  currentUser: null,
  userCards: [],
  userActivity: []
};

const getters = {
  getUsers: (state) => state.users,
  getCurrentUser: (state) => state.currentUser,
  getUserCards: (state) => state.userCards,
  getUserActivity: (state) => state.userActivity
};

const actions = {
  async fetchUsers({ commit }) {
    try {
      const db = getFirestore();
      const usersRef = collection(db, 'users');
      const usersSnapshot = await getDocs(usersRef);
      const users = [];
      
      usersSnapshot.forEach(doc => {
        users.push({
          id: doc.id,
          ...doc.data()
        });
      });
      
      commit('SET_USERS', users);
    } catch (error) {
      console.error('Error al cargar usuarios:', error);
      throw error;
    }
  },

  async fetchUserDetails({ commit }, userId) {
    try {
      const db = getFirestore();
      const userRef = doc(db, 'users', userId);
      const userDoc = await getDoc(userRef);
      
      if (!userDoc.exists()) {
        throw new Error('Usuario no encontrado');
      }
      
      return {
        id: userDoc.id,
        ...userDoc.data()
      };
    } catch (error) {
      console.error('Error al cargar detalles del usuario:', error);
      throw error;
    }
  },

  async fetchUserCards({ commit }, userId) {
    try {
      const db = getFirestore();
      const cardsRef = collection(db, 'users', userId, 'cards');
      const cardsSnapshot = await getDocs(cardsRef);
      
      const cards = [];
      cardsSnapshot.forEach(doc => {
        cards.push({
          id: doc.id,
          ...doc.data()
        });
      });
      
      return cards;
    } catch (error) {
      console.error('Error al cargar cartas del usuario:', error);
      throw error;
    }
  },

  async fetchUserActivity({ commit }, userId) {
    try {
      const db = getFirestore();
      const activityRef = collection(db, 'users', userId, 'activity');
      const q = query(activityRef, orderBy('timestamp', 'desc'), limit(10));
      const activitySnapshot = await getDocs(q);
      
      const activity = [];
      activitySnapshot.forEach(doc => {
        activity.push({
          id: doc.id,
          ...doc.data()
        });
      });
      
      return activity;
    } catch (error) {
      console.error('Error al cargar actividad del usuario:', error);
      throw error;
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
  }
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations
}; 