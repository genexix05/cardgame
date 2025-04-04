import { createStore } from 'vuex'
import { 
  getFirestore, 
  collection, 
  getDocs, 
  doc, 
  getDoc, 
  addDoc, 
  updateDoc, 
  deleteDoc,
  query,
  orderBy,
  limit 
} from 'firebase/firestore'
import { compressAndConvertToBase64 } from '../utils/storage'

export default createStore({
  state: {
    cards: [],
    packs: [],
    users: [],
    loading: false,
    error: null,
    statistics: {
      totalUsers: 0,
      totalCards: 0,
      totalPacks: 0,
      totalTransactions: 0,
      popularCards: [],
      packOpenings: []
    }
  },
  getters: {
    getCardById: (state) => (id) => {
      return state.cards.find(card => card.id === id)
    },
    getPackById: (state) => (id) => {
      return state.packs.find(pack => pack.id === id)
    },
    getUserById: (state) => (id) => {
      return state.users.find(user => user.id === id)
    }
  },
  mutations: {
    SET_LOADING(state, value) {
      state.loading = value
    },
    SET_ERROR(state, error) {
      state.error = error
    },
    SET_CARDS(state, cards) {
      state.cards = cards
    },
    SET_PACKS(state, packs) {
      state.packs = packs
    },
    SET_USERS(state, users) {
      state.users = users
    },
    SET_STATISTICS(state, statistics) {
      state.statistics = statistics
    },
    ADD_CARD(state, card) {
      state.cards.push(card)
    },
    UPDATE_CARD(state, updatedCard) {
      const index = state.cards.findIndex(c => c.id === updatedCard.id)
      if (index !== -1) {
        state.cards.splice(index, 1, updatedCard)
      }
    },
    DELETE_CARD(state, cardId) {
      state.cards = state.cards.filter(c => c.id !== cardId)
    },
    ADD_PACK(state, pack) {
      state.packs.push(pack)
    },
    UPDATE_PACK(state, updatedPack) {
      const index = state.packs.findIndex(p => p.id === updatedPack.id)
      if (index !== -1) {
        state.packs.splice(index, 1, updatedPack)
      }
    },
    DELETE_PACK(state, packId) {
      state.packs = state.packs.filter(p => p.id !== packId)
    }
  },
  actions: {
    // Cargar todas las cartas
    async fetchCards({ commit }) {
      commit('SET_LOADING', true)
      commit('SET_ERROR', null)
      try {
        const db = getFirestore()
        const cardsRef = collection(db, 'cards')
        const querySnapshot = await getDocs(cardsRef)
        
        const cards = querySnapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
        }))
        
        commit('SET_CARDS', cards)
      } catch (error) {
        console.error('Error al cargar cartas:', error)
        commit('SET_ERROR', 'Error al cargar las cartas. Por favor, inténtalo de nuevo.')
      } finally {
        commit('SET_LOADING', false)
      }
    },
    
    // Obtener una carta por ID
    async fetchCardById({ commit }, cardId) {
      commit('SET_LOADING', true)
      commit('SET_ERROR', null)
      try {
        const db = getFirestore()
        const cardRef = doc(db, 'cards', cardId)
        const cardDoc = await getDoc(cardRef)
        
        if (cardDoc.exists()) {
          return { id: cardDoc.id, ...cardDoc.data() }
        } else {
          throw new Error('Carta no encontrada')
        }
      } catch (error) {
        console.error('Error al cargar carta:', error)
        commit('SET_ERROR', 'Error al cargar la carta. Por favor, inténtalo de nuevo.')
        return null
      } finally {
        commit('SET_LOADING', false)
      }
    },
    
    // Crear nueva carta
    async createCard({ commit }, cardData) {
      commit('SET_LOADING', true)
      commit('SET_ERROR', null)
      try {
        // Si hay una imagen para subir
        if (cardData.imageFile) {
          try {
            // Convertir imagen a base64 con compresión
            const base64Image = await compressAndConvertToBase64(
              cardData.imageFile, 
              800,  // Ancho máximo en píxeles
              0.7   // Calidad (0-1)
            );
            
            // Guardar la imagen como string base64 en lugar de URL
            cardData.imageUrl = base64Image;
            
            // Eliminar el archivo de la data que se enviará a Firestore
            delete cardData.imageFile;
            
            console.log('✅ Imagen convertida a base64 correctamente');
          } catch (error) {
            console.error('❌ Error al procesar imagen:', error);
            throw new Error(`Error al procesar la imagen: ${error.message || 'Error desconocido'}`);
          }
        }
        
        const db = getFirestore();
        const cardsRef = collection(db, 'cards');
        const docRef = await addDoc(cardsRef, cardData);
        
        const newCard = {
          id: docRef.id,
          ...cardData
        };
        
        commit('ADD_CARD', newCard);
        return newCard;
      } catch (error) {
        console.error('Error al crear carta:', error);
        commit('SET_ERROR', 'Error al crear la carta. Por favor, inténtalo de nuevo.');
        return null;
      } finally {
        commit('SET_LOADING', false);
      }
    },
    
    // Actualizar carta existente
    async updateCard({ commit }, { cardId, cardData }) {
      commit('SET_LOADING', true);
      commit('SET_ERROR', null);
      try {
        // Si hay una imagen para subir
        if (cardData.imageFile) {
          try {
            // Convertir imagen a base64 con compresión
            const base64Image = await compressAndConvertToBase64(
              cardData.imageFile, 
              800,  // Ancho máximo en píxeles
              0.7   // Calidad (0-1)
            );
            
            // Guardar la imagen como string base64 en lugar de URL
            cardData.imageUrl = base64Image;
            
            // Eliminar el archivo de la data que se enviará a Firestore
            delete cardData.imageFile;
            
            console.log('✅ Imagen convertida a base64 correctamente');
          } catch (error) {
            console.error('❌ Error al procesar imagen:', error);
            throw new Error(`Error al procesar la imagen: ${error.message || 'Error desconocido'}`);
          }
        }
        
        const db = getFirestore();
        const cardRef = doc(db, 'cards', cardId);
        await updateDoc(cardRef, cardData);
        
        const updatedCard = {
          id: cardId,
          ...cardData
        };
        
        commit('UPDATE_CARD', updatedCard);
        return updatedCard;
      } catch (error) {
        console.error('Error al actualizar carta:', error);
        commit('SET_ERROR', 'Error al actualizar la carta. Por favor, inténtalo de nuevo.');
        return null;
      } finally {
        commit('SET_LOADING', false);
      }
    },
    
    // Eliminar carta
    async deleteCard({ commit }, cardId) {
      commit('SET_LOADING', true)
      commit('SET_ERROR', null)
      try {
        const db = getFirestore()
        const cardRef = doc(db, 'cards', cardId)
        await deleteDoc(cardRef)
        
        commit('DELETE_CARD', cardId)
        return true
      } catch (error) {
        console.error('Error al eliminar carta:', error)
        commit('SET_ERROR', 'Error al eliminar la carta. Por favor, inténtalo de nuevo.')
        return false
      } finally {
        commit('SET_LOADING', false)
      }
    },
    
    // Cargar todos los sobres
    async fetchPacks({ commit }) {
      commit('SET_LOADING', true)
      commit('SET_ERROR', null)
      try {
        const db = getFirestore()
        const packsRef = collection(db, 'packs')
        const querySnapshot = await getDocs(packsRef)
        
        const packs = querySnapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
        }))
        
        commit('SET_PACKS', packs)
      } catch (error) {
        console.error('Error al cargar sobres:', error)
        commit('SET_ERROR', 'Error al cargar los sobres. Por favor, inténtalo de nuevo.')
      } finally {
        commit('SET_LOADING', false)
      }
    },
    
    // Obtener un sobre por ID
    async fetchPackById({ commit }, packId) {
      commit('SET_LOADING', true)
      commit('SET_ERROR', null)
      try {
        const db = getFirestore()
        const packRef = doc(db, 'packs', packId)
        const packDoc = await getDoc(packRef)
        
        if (packDoc.exists()) {
          const packData = packDoc.data();
          
          // Cargar las cartas fijas desde la subcolección
          const packCardsRef = collection(db, 'packs', packId, 'packCards');
          const packCardsQuery = query(packCardsRef, orderBy('order', 'asc'));
          const packCardsSnapshot = await getDocs(packCardsQuery);
          
          // Extraer los IDs de las cartas
          const fixedCards = packCardsSnapshot.docs.map(doc => doc.data().cardId);
          console.log(`fetchPackById - Sobre con ID ${packId} tiene ${fixedCards.length} cartas en la subcolección:`, fixedCards);
          
          // Añadir las cartas fijas al objeto del sobre
          packData.fixedCards = fixedCards;
          
          return { 
            id: packDoc.id, 
            ...packData 
          };
        } else {
          throw new Error('Sobre no encontrado')
        }
      } catch (error) {
        console.error('Error al cargar sobre:', error)
        commit('SET_ERROR', 'Error al cargar el sobre. Por favor, inténtalo de nuevo.')
        return null
      } finally {
        commit('SET_LOADING', false)
      }
    },
    
    // Crear nuevo sobre
    async createPack({ commit }, packData) {
      commit('SET_LOADING', true);
      commit('SET_ERROR', null);
      try {
        console.log('createPack - Recibiendo datos:', {
          ...packData, 
          imageFile: packData.imageFile ? 'Objeto File' : null,
          fixedCards: packData.fixedCards || []
        });
        
        // Crear una copia del packData sin clonar objetos File/Blob
        const packToSave = {};
        Object.keys(packData).forEach(key => {
          if (key !== 'imageFile' && key !== 'fixedCards') { // No incluir fixedCards en el documento principal
            packToSave[key] = packData[key];
          }
        });
        
        // Extraer el array de fixedCards para guardar en la subcolección
        const fixedCardsArray = Array.isArray(packData.fixedCards) ? [...packData.fixedCards] : [];
        console.log('Array de cartas fijas para guardar en subcolección:', fixedCardsArray);
        
        // Manejar la referencia al archivo de imagen directamente (sin clonar)
        if (packData.imageFile) {
          packToSave.imageFile = packData.imageFile;
        }
        
        // Si hay una imagen para subir
        if (packToSave.imageFile) {
          try {
            // Depuración: Verificar tipo de la imagen
            console.log('Tipo de imageFile:', typeof packToSave.imageFile);
            console.log('Es instancia de Blob?', packToSave.imageFile instanceof Blob);
            console.log('Es instancia de File?', packToSave.imageFile instanceof File);
            console.log('Valor de imageFile:', packToSave.imageFile);
            
            // Convertir imagen a base64 con compresión
            const base64Image = await compressAndConvertToBase64(
              packToSave.imageFile, 
              800,  // Ancho máximo en píxeles
              0.7   // Calidad (0-1)
            );
            
            // Guardar la imagen como string base64 en lugar de URL
            packToSave.imageUrl = base64Image;
            
            // Eliminar el archivo de la data que se enviará a Firestore
            delete packToSave.imageFile;
            
            console.log('✅ Imagen convertida a base64 correctamente');
          } catch (error) {
            console.error('❌ Error al procesar imagen:', error);
            throw new Error(`Error al procesar la imagen: ${error.message || 'Error desconocido'}`);
          }
        }
        
        console.log('Creando sobre con datos finales:', {
          ...packToSave,
          imageUrl: packToSave.imageUrl ? '[base64 image]' : null,
        });
        
        // 1. Guardar el documento principal del sobre
        const db = getFirestore();
        const packsRef = collection(db, 'packs');
        const docRef = await addDoc(packsRef, packToSave);
        const packId = docRef.id;
        
        // 2. Ahora guardar cada carta fija en la subcolección
        const packCardsRef = collection(db, 'packs', packId, 'packCards');
        const savedCardPromises = fixedCardsArray.map(async (cardId, index) => {
          await addDoc(packCardsRef, {
            cardId: cardId,
            order: index, // Para mantener el orden de las cartas
            addedAt: new Date()
          });
          return cardId;
        });
        
        // Esperar a que se guarden todas las cartas
        const savedCardIds = await Promise.all(savedCardPromises);
        console.log('Cartas guardadas en la subcolección:', savedCardIds);
        
        // Para mantener compatibilidad con el resto del código, incluimos las cartas en el objeto retornado
        const newPack = {
          id: packId,
          ...packToSave,
          fixedCards: savedCardIds // Mantenemos el array para compatibilidad con el código actual
        };
        
        console.log('Sobre creado exitosamente:', {
          id: newPack.id,
          fixedCards: newPack.fixedCards
        });
        
        commit('ADD_PACK', newPack);
        return newPack;
      } catch (error) {
        console.error('Error al crear sobre:', error);
        commit('SET_ERROR', 'Error al crear el sobre. Por favor, inténtalo de nuevo.');
        return null;
      } finally {
        commit('SET_LOADING', false);
      }
    },
    
    // Actualizar sobre existente
    async updatePack({ commit }, { packId, packData }) {
      commit('SET_LOADING', true);
      commit('SET_ERROR', null);
      try {
        console.log('updatePack - Recibiendo datos:', {
          id: packId,
          ...packData, 
          imageFile: packData.imageFile ? 'Objeto File' : null,
          fixedCards: packData.fixedCards || []
        });
        
        // Crear una copia del packData sin clonar objetos File/Blob
        const packToSave = {};
        Object.keys(packData).forEach(key => {
          if (key !== 'imageFile' && key !== 'fixedCards') { // No incluir fixedCards en el documento principal
            packToSave[key] = packData[key];
          }
        });
        
        // Extraer el array de fixedCards para guardar en la subcolección
        const fixedCardsArray = Array.isArray(packData.fixedCards) ? [...packData.fixedCards] : [];
        console.log('Array de cartas fijas para actualizar en subcolección:', fixedCardsArray);
        
        // Manejar la referencia al archivo de imagen directamente (sin clonar)
        if (packData.imageFile) {
          packToSave.imageFile = packData.imageFile;
        }
        
        // Si hay una imagen para subir
        if (packToSave.imageFile) {
          try {
            // Depuración: Verificar tipo de la imagen
            console.log('Tipo de imageFile (update):', typeof packToSave.imageFile);
            console.log('Es instancia de Blob? (update)', packToSave.imageFile instanceof Blob);
            console.log('Es instancia de File? (update)', packToSave.imageFile instanceof File);
            console.log('Valor de imageFile (update):', packToSave.imageFile);
            
            // Convertir imagen a base64 con compresión
            const base64Image = await compressAndConvertToBase64(
              packToSave.imageFile, 
              800,  // Ancho máximo en píxeles
              0.7   // Calidad (0-1)
            );
            
            // Guardar la imagen como string base64 en lugar de URL
            packToSave.imageUrl = base64Image;
            
            // Eliminar el archivo de la data que se enviará a Firestore
            delete packToSave.imageFile;
            
            console.log('✅ Imagen convertida a base64 correctamente');
          } catch (error) {
            console.error('❌ Error al procesar imagen:', error);
            throw new Error(`Error al procesar la imagen: ${error.message || 'Error desconocido'}`);
          }
        }
        
        console.log('Actualizando sobre con datos finales:', {
          id: packId,
          ...packToSave,
          imageUrl: packToSave.imageUrl ? '[base64 image]' : null
        });
        
        const db = getFirestore();
        
        // 1. Actualizar el documento principal del sobre
        const packRef = doc(db, 'packs', packId);
        await updateDoc(packRef, packToSave);
        
        // 2. Actualizar la colección de cartas fijas
        // Primero eliminar todas las cartas existentes
        const packCardsRef = collection(db, 'packs', packId, 'packCards');
        const existingCards = await getDocs(packCardsRef);
        
        // Eliminar cada documento existente
        const deletePromises = existingCards.docs.map(doc => deleteDoc(doc.ref));
        await Promise.all(deletePromises);
        
        // Ahora guardar las nuevas cartas
        const savedCardPromises = fixedCardsArray.map(async (cardId, index) => {
          await addDoc(packCardsRef, {
            cardId: cardId,
            order: index,
            addedAt: new Date()
          });
          return cardId;
        });
        
        // Esperar a que se guarden todas las cartas
        const savedCardIds = await Promise.all(savedCardPromises);
        console.log('Cartas actualizadas en la subcolección:', savedCardIds);
        
        // Para mantener compatibilidad con el resto del código
        const updatedPack = {
          id: packId,
          ...packToSave,
          fixedCards: savedCardIds // Mantenemos el array para compatibilidad
        };
        
        console.log('Sobre actualizado exitosamente:', {
          id: updatedPack.id,
          fixedCards: updatedPack.fixedCards
        });
        
        commit('UPDATE_PACK', updatedPack);
        return updatedPack;
      } catch (error) {
        console.error('Error al actualizar sobre:', error);
        commit('SET_ERROR', 'Error al actualizar el sobre. Por favor, inténtalo de nuevo.');
        return null;
      } finally {
        commit('SET_LOADING', false);
      }
    },
    
    // Eliminar sobre
    async deletePack({ commit }, packId) {
      commit('SET_LOADING', true)
      commit('SET_ERROR', null)
      try {
        const db = getFirestore()
        const packRef = doc(db, 'packs', packId)
        await deleteDoc(packRef)
        
        commit('DELETE_PACK', packId)
        return true
      } catch (error) {
        console.error('Error al eliminar sobre:', error)
        commit('SET_ERROR', 'Error al eliminar el sobre. Por favor, inténtalo de nuevo.')
        return false
      } finally {
        commit('SET_LOADING', false)
      }
    },
    
    // Cargar usuarios
    async fetchUsers({ commit }) {
      commit('SET_LOADING', true)
      commit('SET_ERROR', null)
      try {
        const db = getFirestore()
        const usersRef = collection(db, 'users')
        const querySnapshot = await getDocs(usersRef)
        
        const users = querySnapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
        }))
        
        commit('SET_USERS', users)
      } catch (error) {
        console.error('Error al cargar usuarios:', error)
        commit('SET_ERROR', 'Error al cargar los usuarios. Por favor, inténtalo de nuevo.')
      } finally {
        commit('SET_LOADING', false)
      }
    },
    
    // Cargar estadísticas
    async fetchStatistics({ commit }) {
      commit('SET_LOADING', true)
      commit('SET_ERROR', null)
      try {
        const db = getFirestore()
        
        // Verificar conectividad antes de realizar operaciones
        const networkStatus = window.navigator.onLine
        if (!networkStatus) {
          throw new Error('No hay conexión a Internet. La aplicación funcionará en modo offline con datos limitados.')
        }
        
        // Establecer un timeout para las operaciones de Firestore
        const timeout = new Promise((_, reject) => 
          setTimeout(() => reject(new Error('Tiempo de espera agotado al conectar con Firestore')), 15000)
        )
        
        // Contar usuarios
        const usersRef = collection(db, 'users')
        const usersSnapshot = await getDocs(usersRef)
        const totalUsers = usersSnapshot.size
        
        // Contar cartas
        const cardsRef = collection(db, 'cards')
        const cardsSnapshot = await getDocs(cardsRef)
        const totalCards = cardsSnapshot.size
        
        // Contar sobres
        const packsRef = collection(db, 'packs')
        const packsSnapshot = await getDocs(packsRef)
        const totalPacks = packsSnapshot.size
        
        // Contar transacciones
        const transactionsRef = collection(db, 'transactions')
        const transactionsSnapshot = await getDocs(transactionsRef)
        const totalTransactions = transactionsSnapshot.size
        
        // Cartas populares (más coleccionadas)
        const userCollectionsRef = collection(db, 'userCollections')
        const userCollectionsSnapshot = await getDocs(userCollectionsRef)
        
        // Mapa para contar ocurrencias de cartas
        const cardCounts = {}
        
        userCollectionsSnapshot.forEach(doc => {
          const data = doc.data()
          if (data.cards) {
            Object.entries(data.cards).forEach(([cardId, cardInfo]) => {
              if (!cardCounts[cardId]) {
                cardCounts[cardId] = 0
              }
              cardCounts[cardId] += cardInfo.quantity || 0
            })
          }
        })
        
        // Convertir a array y ordenar
        const sortedCards = Object.entries(cardCounts)
          .map(([cardId, count]) => ({ cardId, count }))
          .sort((a, b) => b.count - a.count)
          .slice(0, 10) // Top 10
        
        // Obtener detalles de las cartas más populares
        const popularCards = []
        for (const item of sortedCards) {
          const cardRef = doc(db, 'cards', item.cardId)
          const cardDoc = await getDoc(cardRef)
          if (cardDoc.exists()) {
            popularCards.push({
              id: cardDoc.id,
              ...cardDoc.data(),
              count: item.count
            })
          }
        }
        
        // Historial de apertura de sobres
        const packOpeningsRef = collection(db, 'packOpenings')
        const q = query(packOpeningsRef, orderBy('timestamp', 'desc'), limit(20))
        const packOpeningsSnapshot = await getDocs(q)
        
        const packOpenings = packOpeningsSnapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
        }))
        
        const statistics = {
          totalUsers,
          totalCards,
          totalPacks,
          totalTransactions,
          popularCards,
          packOpenings
        }
        
        commit('SET_STATISTICS', statistics)
      } catch (error) {
        console.error('Error al cargar estadísticas:', error)
        commit('SET_ERROR', 'Error al cargar las estadísticas. Por favor, inténtalo de nuevo.')
      } finally {
        commit('SET_LOADING', false)
      }
    }
  },
  modules: {
  }
})