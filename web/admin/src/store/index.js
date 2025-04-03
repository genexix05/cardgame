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
import { getStorage, ref, uploadBytes, getDownloadURL } from 'firebase/storage'

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
          const storage = getStorage()
          const storageRef = ref(storage, `card_images/${Date.now()}_${cardData.imageFile.name}`)
          
          // Subir la imagen
          await uploadBytes(storageRef, cardData.imageFile)
          
          // Obtener URL de descarga
          const downloadURL = await getDownloadURL(storageRef)
          cardData.imageUrl = downloadURL
          
          // Eliminar el archivo de la data que se enviará a Firestore
          delete cardData.imageFile
        }
        
        const db = getFirestore()
        const cardsRef = collection(db, 'cards')
        const docRef = await addDoc(cardsRef, cardData)
        
        const newCard = {
          id: docRef.id,
          ...cardData
        }
        
        commit('ADD_CARD', newCard)
        return newCard
      } catch (error) {
        console.error('Error al crear carta:', error)
        commit('SET_ERROR', 'Error al crear la carta. Por favor, inténtalo de nuevo.')
        return null
      } finally {
        commit('SET_LOADING', false)
      }
    },
    
    // Actualizar carta existente
    async updateCard({ commit }, { cardId, cardData }) {
      commit('SET_LOADING', true)
      commit('SET_ERROR', null)
      try {
        // Si hay una imagen para subir
        if (cardData.imageFile) {
          const storage = getStorage()
          const storageRef = ref(storage, `card_images/${Date.now()}_${cardData.imageFile.name}`)
          
          // Subir la imagen
          await uploadBytes(storageRef, cardData.imageFile)
          
          // Obtener URL de descarga
          const downloadURL = await getDownloadURL(storageRef)
          cardData.imageUrl = downloadURL
          
          // Eliminar el archivo de la data que se enviará a Firestore
          delete cardData.imageFile
        }
        
        const db = getFirestore()
        const cardRef = doc(db, 'cards', cardId)
        await updateDoc(cardRef, cardData)
        
        const updatedCard = {
          id: cardId,
          ...cardData
        }
        
        commit('UPDATE_CARD', updatedCard)
        return updatedCard
      } catch (error) {
        console.error('Error al actualizar carta:', error)
        commit('SET_ERROR', 'Error al actualizar la carta. Por favor, inténtalo de nuevo.')
        return null
      } finally {
        commit('SET_LOADING', false)
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
          return { id: packDoc.id, ...packDoc.data() }
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
      commit('SET_LOADING', true)
      commit('SET_ERROR', null)
      try {
        // Si hay una imagen para subir
        if (packData.imageFile) {
          try {
            const storage = getStorage()
            const filename = `${Date.now()}_${packData.imageFile.name.replace(/[^a-zA-Z0-9.]/g, '_')}`
            const storageRef = ref(storage, `pack_images/${filename}`)
            
            console.log('📤 Iniciando subida de imagen a Firebase Storage...')
            
            // Configurar metadatos para CORS
            const metadata = {
              contentType: packData.imageFile.type,
              customMetadata: {
                'uploaded-by': 'admin-panel',
                'upload-timestamp': Date.now().toString()
              }
            }
            
            // Subir la imagen con metadatos
            await uploadBytes(storageRef, packData.imageFile, metadata)
            
            console.log('✅ Imagen subida correctamente, obteniendo URL...')
            
            // Obtener URL de descarga con manejo de errores
            const downloadURL = await getDownloadURL(storageRef)
            packData.imageUrl = downloadURL
            
            console.log('✅ URL de imagen obtenida correctamente')
          } catch (uploadError) {
            console.error('❌ Error al subir imagen:', uploadError)
            
            // Manejo específico de errores CORS
            if (uploadError.code === 'storage/unauthorized' || 
                uploadError.message?.includes('CORS') || 
                uploadError.code === 'storage/canceled') {
              throw new Error('Error de permisos CORS al subir la imagen. Por favor, verifica la configuración de Firebase Storage.')
            }
            
            // Otros errores de Storage
            throw new Error(`Error al subir imagen: ${uploadError.message || 'Error desconocido'}`)
          }
          
          // Eliminar el archivo de la data que se enviará a Firestore
          delete packData.imageFile
        }
        
        const db = getFirestore()
        const packsRef = collection(db, 'packs')
        const docRef = await addDoc(packsRef, packData)
        
        const newPack = {
          id: docRef.id,
          ...packData
        }
        
        commit('ADD_PACK', newPack)
        return newPack
      } catch (error) {
        console.error('Error al crear sobre:', error)
        commit('SET_ERROR', 'Error al crear el sobre. Por favor, inténtalo de nuevo.')
        return null
      } finally {
        commit('SET_LOADING', false)
      }
    },
    
    // Actualizar sobre existente
    async updatePack({ commit }, { packId, packData }) {
      commit('SET_LOADING', true)
      commit('SET_ERROR', null)
      try {
        // Si hay una imagen para subir
        if (packData.imageFile) {
          try {
            const storage = getStorage()
            const filename = `${Date.now()}_${packData.imageFile.name.replace(/[^a-zA-Z0-9.]/g, '_')}`
            const storageRef = ref(storage, `pack_images/${filename}`)
            
            console.log('📤 Iniciando subida de imagen a Firebase Storage...')
            
            // Configurar metadatos para CORS
            const metadata = {
              contentType: packData.imageFile.type,
              customMetadata: {
                'uploaded-by': 'admin-panel',
                'upload-timestamp': Date.now().toString()
              }
            }
            
            // Subir la imagen con metadatos
            await uploadBytes(storageRef, packData.imageFile, metadata)
            
            console.log('✅ Imagen subida correctamente, obteniendo URL...')
            
            // Obtener URL de descarga con manejo de errores
            const downloadURL = await getDownloadURL(storageRef)
            packData.imageUrl = downloadURL
            
            console.log('✅ URL de imagen obtenida correctamente')
          } catch (uploadError) {
            console.error('❌ Error al subir imagen:', uploadError)
            
            // Manejo específico de errores CORS
            if (uploadError.code === 'storage/unauthorized' || 
                uploadError.message?.includes('CORS') || 
                uploadError.code === 'storage/canceled') {
              throw new Error('Error de permisos CORS al subir la imagen. Por favor, verifica la configuración de Firebase Storage.')
            }
            
            // Otros errores de Storage
            throw new Error(`Error al subir imagen: ${uploadError.message || 'Error desconocido'}`)
          }
          
          // Eliminar el archivo de la data que se enviará a Firestore
          delete packData.imageFile
        }
        
        const db = getFirestore()
        const packRef = doc(db, 'packs', packId)
        await updateDoc(packRef, packData)
        
        const updatedPack = {
          id: packId,
          ...packData
        }
        
        commit('UPDATE_PACK', updatedPack)
        return updatedPack
      } catch (error) {
        console.error('Error al actualizar sobre:', error)
        commit('SET_ERROR', 'Error al actualizar el sobre. Por favor, inténtalo de nuevo.')
        return null
      } finally {
        commit('SET_LOADING', false)
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