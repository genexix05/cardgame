<template>
  <div class="cards-view">
    <!-- Encabezado -->
    <div class="flex items-center justify-between mb-8">
      <div>
        <h1 class="text-2xl font-bold text-gray-800">Gestión de Cartas</h1>
        <p class="text-gray-600 mt-1">Administra todas las cartas del juego</p>
      </div>
      <router-link to="/cards/new" class="btn-primary">
        <i class="fas fa-plus-circle mr-2"></i>Nueva Carta
      </router-link>
    </div>
    
    <!-- Filtros y búsqueda -->
    <div class="bg-white rounded-lg shadow-sm p-6 mb-6">
      <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div class="col-span-1 md:col-span-2">
          <label for="searchInput" class="block text-sm font-medium text-gray-700 mb-1">Buscar</label>
          <div class="relative">
            <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
              <i class="fas fa-search text-gray-400"></i>
            </div>
            <input 
              type="text" 
              class="form-control pl-10" 
              id="searchInput" 
              v-model="search"
              placeholder="Nombre, tipo o descripción..."
            >
          </div>
        </div>
        
        <div>
          <label for="rarityFilter" class="block text-sm font-medium text-gray-700 mb-1">Rareza</label>
          <select class="form-select" id="rarityFilter" v-model="rarityFilter">
            <option value="">Todas</option>
            <option value="common">Común</option>
            <option value="uncommon">Poco común</option>
            <option value="rare">Rara</option>
            <option value="superRare">Super rara</option>
            <option value="ultraRare">Ultra rara</option>
            <option value="legendary">Legendaria</option>
          </select>
        </div>
        
        <div>
          <label for="typeFilter" class="block text-sm font-medium text-gray-700 mb-1">Tipo</label>
          <select class="form-select" id="typeFilter" v-model="typeFilter">
            <option value="">Todos</option>
            <option value="character">Personaje</option>
            <option value="support">Soporte</option>
            <option value="equipment">Equipamiento</option>
            <option value="event">Evento</option>
          </select>
        </div>
      </div>
    </div>
    
    <!-- Lista de cartas -->
    <div v-if="loading" class="flex justify-center items-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
    </div>
    
    <div v-else-if="error" class="bg-red-50 border-l-4 border-red-400 p-4 mb-6">
      <div class="flex">
        <div class="flex-shrink-0">
          <i class="fas fa-exclamation-circle text-red-400"></i>
        </div>
        <div class="ml-3">
          <p class="text-sm text-red-700">{{ error }}</p>
        </div>
        <div class="ml-auto pl-3">
          <button class="btn-outline-danger" @click="loadCards">Reintentar</button>
        </div>
      </div>
    </div>
    
    <div v-else>
      <div v-if="filteredCards.length === 0" class="text-center py-12">
        <i class="fas fa-search text-gray-400 text-4xl mb-4"></i>
        <p class="text-gray-500">No se encontraron cartas que coincidan con los filtros</p>
      </div>
      
      <div v-else class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        <div v-for="card in filteredCards" :key="card.id" class="card">
          <div class="relative">
            <img :src="prepareImageUrl(card.imageUrl)" class="w-full h-48 object-cover rounded-t-lg" :alt="card.name">
            <div class="absolute top-2 right-2">
              <span class="badge" :class="getRarityBadgeClass(card.rarity)">
                {{ getRarityText(card.rarity) }}
              </span>
            </div>
          </div>
          
          <div class="p-4">
            <div class="flex justify-between items-start mb-2">
              <h3 class="text-lg font-semibold text-gray-800">{{ card.name }}</h3>
              <span class="badge bg-gray-100 text-gray-800">{{ getTypeText(card.type) }}</span>
            </div>
            
            <p class="text-sm text-gray-600 mb-4">{{ card.description }}</p>
            
            <div class="flex flex-wrap gap-2 mb-4">
              <span v-for="categoryId in (card.categories || [])" :key="categoryId" class="badge bg-info">
                {{ getCategoryName(categoryId) }}
              </span>
            </div>
            
            <div class="flex items-center space-x-4 text-sm text-gray-500">
              <div class="flex items-center">
                <i class="fas fa-tag text-blue-500 mr-1"></i>
                <span>{{ card.series }}</span>
              </div>
            </div>

            <!-- Atributos de personaje -->
            <div v-if="card.type === 'character'" class="flex items-center space-x-4 text-sm text-gray-500 mt-2">
              <div class="flex items-center">
                <i class="fas fa-heart text-red-500 mr-1"></i>
                <span>{{ card.health }}</span>
              </div>
              <div class="flex items-center">
                <i class="fas fa-fist-raised text-orange-500 mr-1"></i>
                <span>{{ card.attack }}</span>
              </div>
              <div class="flex items-center">
                <i class="fas fa-shield-alt text-blue-500 mr-1"></i>
                <span>{{ card.defense }}</span>
              </div>
            </div>
          </div>
          
          <div class="px-4 py-3 bg-gray-50 rounded-b-lg flex justify-between">
            <router-link :to="'/cards/edit/' + card.id" class="btn-outline-primary">
              <i class="fas fa-edit mr-1"></i>Editar
            </router-link>
            <button class="btn-outline-danger" @click="confirmDelete(card)">
              <i class="fas fa-trash-alt mr-1"></i>Eliminar
            </button>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Modal de confirmación de eliminación -->
    <div v-if="showDeleteModal" class="modal">
      <div class="modal-content">
        <div class="modal-header">
          <h3 class="text-lg font-semibold text-gray-800">Confirmar Eliminación</h3>
          <button class="modal-close" @click="showDeleteModal = false">
            <i class="fas fa-times"></i>
          </button>
        </div>
        
        <div class="modal-body">
          <p class="text-gray-600">¿Estás seguro de que deseas eliminar la carta <strong>{{ selectedCard?.name }}</strong>?</p>
          <p class="text-red-500 mt-2">Esta acción no se puede deshacer.</p>
        </div>
        
        <div class="modal-footer">
          <button class="btn-secondary" @click="showDeleteModal = false">Cancelar</button>
          <button class="btn-danger" @click="deleteCard" :disabled="isDeleting">
            <span v-if="isDeleting" class="animate-spin mr-2">⌛</span>
            Eliminar
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { prepareImageUrl } from '../utils/storage';
import { collection, getDocs } from 'firebase/firestore';
import { db } from '../firebase';

export default {
  name: 'CardsView',
  setup() {
    const store = useStore();
    const loading = computed(() => store.state.loading);
    const error = computed(() => store.state.error);
    const cards = computed(() => store.state.cards);
    
    // Filtros y búsqueda
    const search = ref('');
    const rarityFilter = ref('');
    const typeFilter = ref('');
    const sortOrder = ref('name');
    
    // Para eliminar cartas
    const showDeleteModal = ref(false);
    const selectedCard = ref(null);
    const isDeleting = ref(false);
    
    const categories = ref([]);

    const loadCategories = async () => {
      try {
        const categoriesRef = collection(db, 'categories');
        const querySnapshot = await getDocs(categoriesRef);
        
        categories.value = querySnapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
        }));
      } catch (err) {
        console.error('Error al cargar categorías:', err);
      }
    };

    const getCategoryName = (categoryId) => {
      const category = categories.value.find(c => c.id === categoryId);
      return category ? category.name : 'Categoría desconocida';
    };
    
    const loadCards = async () => {
      await store.dispatch('fetchCards');
    };
    
    const getRarityBadgeClass = (rarity) => {
      switch (rarity) {
        case 'common': return 'rarity-common';
        case 'uncommon': return 'rarity-uncommon';
        case 'rare': return 'rarity-rare';
        case 'superRare': return 'rarity-superRare';
        case 'ultraRare': return 'rarity-ultraRare';
        case 'legendary': return 'rarity-legendary';
        default: return 'rarity-common';
      }
    };

    const filteredCards = computed(() => {
      let result = [...(cards.value || [])];
      
      // Aplicar búsqueda
      if (search.value) {
        const searchLower = search.value.toLowerCase();
        result = result.filter(card => 
          card.name.toLowerCase().includes(searchLower) ||
          card.description.toLowerCase().includes(searchLower) ||
          card.series.toLowerCase().includes(searchLower)
        );
      }
      
      // Aplicar filtro de rareza
      if (rarityFilter.value) {
        result = result.filter(card => card.rarity === rarityFilter.value);
      }
      
      // Aplicar filtro de tipo
      if (typeFilter.value) {
        result = result.filter(card => card.type === typeFilter.value);
      }
      
      // Aplicar ordenamiento
      result.sort((a, b) => {
        switch (sortOrder.value) {
          case 'name':
            return a.name.localeCompare(b.name);
          case 'power':
            return b.power - a.power;
          case 'rarity':
            // Ordenar por nivel de rareza (común -> legendaria)
            const rarityOrder = {
              common: 1,
              uncommon: 2,
              rare: 3,
              superRare: 4,
              ultraRare: 5,
              legendary: 6
            };
            return rarityOrder[b.rarity] - rarityOrder[a.rarity];
          case 'type':
            return a.type.localeCompare(b.type);
          default:
            return 0;
        }
      });
      
      return result;
    });
    
    const getRarityText = (rarity) => {
      switch (rarity) {
        case 'common': return 'Común';
        case 'uncommon': return 'Poco común';
        case 'rare': return 'Rara';
        case 'superRare': return 'Super rara';
        case 'ultraRare': return 'Ultra rara';
        case 'legendary': return 'Legendaria';
        default: return 'Desconocida';
      }
    };
    
    const getTypeText = (type) => {
      switch (type) {
        case 'character': return 'Personaje';
        case 'support': return 'Soporte';
        case 'equipment': return 'Equipamiento';
        case 'event': return 'Evento';
        default: return 'Desconocido';
      }
    };
    
    const confirmDelete = (card) => {
      selectedCard.value = card;
      showDeleteModal.value = true;
    };
    
    const deleteCard = async () => {
      if (!selectedCard.value) return;
      
      isDeleting.value = true;
      try {
        await store.dispatch('deleteCard', selectedCard.value.id);
        showDeleteModal.value = false;
        selectedCard.value = null;
      } catch (error) {
        console.error('Error al eliminar carta:', error);
      } finally {
        isDeleting.value = false;
      }
    };
    
    onMounted(() => {
      loadCategories();
      loadCards();
    });
    
    return {
      loading,
      error,
      cards,
      filteredCards,
      search,
      rarityFilter,
      typeFilter,
      sortOrder,
      showDeleteModal,
      selectedCard,
      isDeleting,
      loadCards,
      getRarityText,
      getTypeText,
      getRarityBadgeClass,
      confirmDelete,
      deleteCard,
      prepareImageUrl,
      getCategoryName
    };
  }
};
</script>

<style scoped>
.cards-view {
  @apply p-6;
}

.card {
  @apply bg-white rounded-lg shadow-sm transition-all duration-300 hover:shadow-md;
}

.badge {
  @apply px-2 py-1 text-xs font-semibold rounded-full;
}

.rarity-common {
  @apply bg-gray-100 text-gray-800;
}

.rarity-uncommon {
  @apply bg-green-100 text-green-800;
}

.rarity-rare {
  @apply bg-blue-100 text-blue-800;
}

.rarity-superRare {
  @apply bg-purple-100 text-purple-800;
}

.rarity-ultraRare {
  @apply bg-yellow-100 text-yellow-800;
}

.rarity-legendary {
  @apply bg-red-100 text-red-800;
}

.modal {
  @apply fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50;
}

.modal-content {
  @apply bg-white rounded-lg shadow-xl max-w-md w-full;
}

.modal-header {
  @apply flex justify-between items-center p-4 border-b;
}

.modal-body {
  @apply p-4;
}

.modal-footer {
  @apply flex justify-end space-x-3 p-4 border-t;
}

.modal-close {
  @apply text-gray-400 hover:text-gray-500;
}

.btn-primary {
  @apply bg-gradient-to-r from-orange-500 to-orange-600 text-white px-4 py-2 rounded-lg 
         flex items-center hover:from-orange-600 hover:to-orange-700 transition-all;
}

.btn-outline-primary {
  @apply border border-orange-500 text-orange-500 px-3 py-1 rounded-lg 
         flex items-center hover:bg-orange-50 transition-all;
}

.btn-outline-danger {
  @apply border border-red-500 text-red-500 px-3 py-1 rounded-lg 
         flex items-center hover:bg-red-50 transition-all;
}

.btn-secondary {
  @apply bg-gray-100 text-gray-800 px-4 py-2 rounded-lg hover:bg-gray-200 transition-all;
}

.btn-danger {
  @apply bg-red-500 text-white px-4 py-2 rounded-lg hover:bg-red-600 transition-all 
         flex items-center disabled:opacity-50 disabled:cursor-not-allowed;
}

.form-control {
  @apply w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 
         focus:ring-orange-500 focus:border-orange-500 transition-all;
}

.form-select {
  @apply w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 
         focus:ring-orange-500 focus:border-orange-500 transition-all;
}
</style>