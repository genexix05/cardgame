<template>
  <div class="packs-view">
    <!-- Encabezado -->
    <div class="flex items-center justify-between mb-8">
      <div>
        <h1 class="text-2xl font-bold text-gray-800">Gestión de Sobres</h1>
        <p class="text-gray-600 mt-1">Administra los sobres de cartas disponibles</p>
      </div>
      <router-link to="/packs/new" class="btn-primary">
        <i class="fas fa-plus-circle mr-2"></i>Nuevo Sobre
      </router-link>
    </div>
    
    <!-- Filtros y búsqueda -->
    <div class="bg-white rounded-lg shadow-sm p-6 mb-6">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
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
              placeholder="Nombre o descripción..."
            >
          </div>
        </div>
        
        <div>
          <label for="priceFilter" class="block text-sm font-medium text-gray-700 mb-1">Precio</label>
          <select class="form-select" id="priceFilter" v-model="priceFilter">
            <option value="">Todos</option>
            <option value="low">Bajo (< 100)</option>
            <option value="medium">Medio (100 - 300)</option>
            <option value="high">Alto (> 300)</option>
          </select>
        </div>
      </div>
    </div>
    
    <!-- Lista de sobres -->
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
          <button class="btn-outline-danger" @click="loadPacks">Reintentar</button>
        </div>
      </div>
    </div>
    
    <div v-else>
      <div v-if="filteredPacks.length === 0" class="text-center py-12">
        <i class="fas fa-box-open text-gray-400 text-4xl mb-4"></i>
        <p class="text-gray-500">No se encontraron sobres que coincidan con los filtros</p>
      </div>
      
      <div v-else class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        <div v-for="pack in filteredPacks" :key="pack.id" class="card">
          <div class="relative">
            <img :src="prepareImageUrl(pack.imageUrl)" class="w-full h-48 object-cover rounded-t-lg" :alt="pack.name">
            <div class="absolute top-2 right-2">
              <span class="badge bg-yellow-100 text-yellow-800">
                {{ pack.price }} <i class="fas fa-coins ml-1"></i>
              </span>
            </div>
          </div>
          
          <div class="p-4">
            <h3 class="text-lg font-semibold text-gray-800 mb-2">{{ pack.name }}</h3>
            <p class="text-sm text-gray-600 mb-4">{{ pack.description }}</p>
            
            <div class="space-y-3">
              <div class="flex items-center text-sm text-gray-500">
                <i class="fas fa-layer-group text-blue-500 mr-2"></i>
                <span>{{ pack.cardCount || 0 }} cartas por sobre</span>
              </div>
              
              <div class="flex items-center text-sm text-gray-500">
                <i class="fas fa-calendar-alt text-green-500 mr-2"></i>
                <span>{{ formatDate(pack.releaseDate) }}</span>
              </div>
              
              <div class="mt-4">
                <h4 class="text-sm font-medium text-gray-700 mb-2">Probabilidades</h4>
                <div v-if="pack.probabilities" class="space-y-1">
                  <div v-for="(prob, rarity) in pack.probabilities" :key="rarity" 
                       class="flex justify-between items-center text-sm">
                    <span class="badge" :class="'rarity-' + rarity">
                      {{ getRarityText(rarity) }}
                    </span>
                    <span class="text-gray-600">{{ (prob * 100).toFixed(1) }}%</span>
                  </div>
                </div>
                <div v-else class="text-center text-gray-400 text-sm">
                  No hay datos de probabilidad
                </div>
              </div>
            </div>
          </div>
          
          <div class="px-4 py-3 bg-gray-50 rounded-b-lg flex justify-between">
            <router-link :to="'/packs/edit/' + pack.id" class="btn-outline-primary">
              <i class="fas fa-edit mr-1"></i>Editar
            </router-link>
            <button class="btn-outline-danger" @click="confirmDelete(pack)">
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
          <p class="text-gray-600">¿Estás seguro de que deseas eliminar el sobre <strong>{{ selectedPack?.name }}</strong>?</p>
          <p class="text-red-500 mt-2">Esta acción no se puede deshacer. Los usuarios que hayan comprado este sobre anteriormente seguirán teniendo las cartas que obtuvieron.</p>
        </div>
        
        <div class="modal-footer">
          <button class="btn-secondary" @click="showDeleteModal = false">Cancelar</button>
          <button class="btn-danger" @click="deletePack" :disabled="isDeleting">
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

export default {
  name: 'PacksView',
  setup() {
    const store = useStore();
    const loading = computed(() => store.state.loading);
    const error = computed(() => store.state.error);
    const packs = computed(() => store.state.packs);
    
    // Filtros y búsqueda
    const search = ref('');
    const priceFilter = ref('');
    const sortOrder = ref('name');
    
    // Variables para manejo de eliminación
    const showDeleteModal = ref(false);
    const selectedPack = ref(null);
    const isDeleting = ref(false);
    
    const loadPacks = async () => {
      await store.dispatch('fetchPacks');
    };
    
    const filteredPacks = computed(() => {
      let result = [...packs.value];
      
      // Aplicar búsqueda
      if (search.value) {
        const searchLower = search.value.toLowerCase();
        result = result.filter(pack => 
          pack.name.toLowerCase().includes(searchLower) ||
          (pack.description && pack.description.toLowerCase().includes(searchLower))
        );
      }
      
      // Aplicar filtro de precio
      if (priceFilter.value) {
        switch(priceFilter.value) {
          case 'low':
            result = result.filter(pack => pack.price < 100);
            break;
          case 'medium':
            result = result.filter(pack => pack.price >= 100 && pack.price <= 300);
            break;
          case 'high':
            result = result.filter(pack => pack.price > 300);
            break;
        }
      }
      
      // Aplicar ordenamiento
      result.sort((a, b) => {
        switch (sortOrder.value) {
          case 'name':
            return a.name.localeCompare(b.name);
          case 'price':
            return a.price - b.price;
          case 'cardCount':
            return (a.cardCount || 0) - (b.cardCount || 0);
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
    
    const formatDate = (timestamp) => {
      if (!timestamp) return 'N/A';
      
      const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
      return new Intl.DateTimeFormat('es-ES', {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
      }).format(date);
    };
    
    const confirmDelete = (pack) => {
      selectedPack.value = pack;
      showDeleteModal.value = true;
    };
    
    const deletePack = async () => {
      if (!selectedPack.value) return;
      isDeleting.value = true;
      try {
        const result = await store.dispatch('deletePack', selectedPack.value.id);
        if (result) {
          // Volvemos a cargar los sobres para actualizar la lista
          await loadPacks();
          alert('Sobre eliminado correctamente');
        } else {
          alert('Error al eliminar el sobre');
        }
        showDeleteModal.value = false;
        selectedPack.value = null;
      } catch (error) {
        console.error('Error al eliminar sobre:', error);
        alert('Error al eliminar el sobre, por favor intenta nuevamente');
      } finally {
        isDeleting.value = false;
      }
    };
    
    onMounted(() => {
      loadPacks();
    });
    
    return {
      loading,
      error,
      packs,
      filteredPacks,
      search,
      priceFilter,
      sortOrder,
      showDeleteModal,
      selectedPack,
      isDeleting,
      loadPacks,
      getRarityText,
      formatDate,
      confirmDelete,
      deletePack,
      prepareImageUrl
    };
  }
};
</script>

<style scoped>
.packs-view {
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
