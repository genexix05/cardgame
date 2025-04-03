<template>
  <div class="packs-view">
    <div class="d-flex justify-content-between align-items-center mb-4">
      <h1>Gestión de Sobres</h1>
      <router-link to="/packs/new" class="btn btn-primary">
        <i class="fas fa-plus-circle me-2"></i>Nuevo Sobre
      </router-link>
    </div>
    
    <!-- Filtros y búsqueda -->
    <div class="card mb-4 shadow-sm">
      <div class="card-body">
        <div class="row g-3">
          <div class="col-md-6">
            <label for="searchInput" class="form-label">Buscar</label>
            <div class="input-group">
              <span class="input-group-text"><i class="fas fa-search"></i></span>
              <input 
                type="text" 
                class="form-control" 
                id="searchInput" 
                v-model="search"
                placeholder="Nombre o descripción..."
              >
            </div>
          </div>
          
          <div class="col-md-3">
            <label for="priceFilter" class="form-label">Precio</label>
            <select class="form-select" id="priceFilter" v-model="priceFilter">
              <option value="">Todos</option>
              <option value="low">Bajo (< 100)</option>
              <option value="medium">Medio (100 - 300)</option>
              <option value="high">Alto (> 300)</option>
            </select>
          </div>
          
          <div class="col-md-3">
            <label for="sortOrder" class="form-label">Ordenar por</label>
            <select class="form-select" id="sortOrder" v-model="sortOrder">
              <option value="name">Nombre</option>
              <option value="price">Precio</option>
              <option value="cardCount">Cantidad de cartas</option>
            </select>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Lista de sobres -->
    <div v-if="loading" class="text-center py-5">
      <div class="spinner-border text-primary" role="status">
        <span class="visually-hidden">Cargando...</span>
      </div>
    </div>
    <div v-else-if="error" class="alert alert-danger">
      {{ error }}
      <button class="btn btn-sm btn-outline-danger ms-3" @click="loadPacks">Reintentar</button>
    </div>
    <div v-else>
      <div v-if="filteredPacks.length === 0" class="text-center py-5">
        <p class="text-muted">No se encontraron sobres que coincidan con los filtros</p>
      </div>
      <div v-else class="row row-cols-1 row-cols-md-2 row-cols-lg-3 g-4">
        <div v-for="pack in filteredPacks" :key="pack.id" class="col">
          <div class="card h-100 shadow-sm">
            <div class="card-img-top-container">
              <img :src="prepareImageUrl(pack.imageUrl)" class="card-img-top" :alt="pack.name">
              <div class="pack-price-badge">
                {{ pack.price }} <i class="fas fa-coins text-warning"></i>
              </div>
            </div>
            <div class="card-body">
              <h5 class="card-title mb-2">{{ pack.name }}</h5>
              <p class="card-text small text-muted">{{ pack.description }}</p>
              
              <div class="pack-info mt-3">
                <div class="d-flex justify-content-between">
                  <div>
                    <i class="fas fa-layer-group me-1"></i>
                    <span>{{ pack.cardCount || 0 }} cartas por sobre</span>
                  </div>
                  <div>
                    <i class="fas fa-calendar-alt me-1"></i>
                    <span>{{ formatDate(pack.releaseDate) }}</span>
                  </div>
                </div>
                
                <div class="pack-probabilities mt-2 small">
                  <div v-if="pack.probabilities">
                    <div v-for="(prob, rarity) in pack.probabilities" :key="rarity" class="d-flex justify-content-between">
                      <span>{{ getRarityText(rarity) }}:</span>
                      <span>{{ (prob * 100).toFixed(1) }}%</span>
                    </div>
                  </div>
                  <div v-else class="text-center text-muted">
                    No hay datos de probabilidad
                  </div>
                </div>
              </div>
            </div>
            <div class="card-footer bg-transparent d-flex justify-content-between">
              <router-link :to="'/packs/' + pack.id" class="btn btn-sm btn-outline-primary">
                <i class="fas fa-edit me-1"></i>Editar
              </router-link>
              <button class="btn btn-sm btn-outline-danger" @click="confirmDelete(pack)">
                <i class="fas fa-trash-alt me-1"></i>Eliminar
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Modal de confirmación de eliminación -->
    <div v-if="showDeleteModal" class="modal fade show" style="display: block;" tabindex="-1" aria-modal="true" role="dialog">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title">Confirmar Eliminación</h5>
            <button type="button" class="btn-close" @click="showDeleteModal = false"></button>
          </div>
          <div class="modal-body">
            <p>¿Estás seguro de que deseas eliminar el sobre <strong>{{ selectedPack?.name }}</strong>?</p>
            <p class="text-danger">Esta acción no se puede deshacer. Los usuarios que hayan comprado este sobre anteriormente seguirán teniendo las cartas que obtuvieron.</p>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" @click="showDeleteModal = false">Cancelar</button>
            <button type="button" class="btn btn-danger" @click="deletePack" :disabled="isDeleting">
              <span v-if="isDeleting" class="spinner-border spinner-border-sm me-2" role="status"></span>
              Eliminar
            </button>
          </div>
        </div>
      </div>
      <div class="modal-backdrop fade show"></div>
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
    
    // Para eliminar sobres
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
        await store.dispatch('deletePack', selectedPack.value.id);
        showDeleteModal.value = false;
        selectedPack.value = null;
      } catch (error) {
        console.error('Error al eliminar sobre:', error);
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
.card-img-top-container {
  position: relative;
  height: 180px;
  overflow: hidden;
}

.card-img-top {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.pack-price-badge {
  position: absolute;
  top: 10px;
  right: 10px;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-size: 0.9rem;
  font-weight: bold;
  color: white;
  background-color: rgba(0, 0, 0, 0.7);
}

.card-title {
  font-size: 1.1rem;
  font-weight: bold;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.card-text {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  height: 40px;
}

.pack-probabilities {
  background-color: #f8f9fa;
  border-radius: 4px;
  padding: 8px;
  margin-top: 12px;
}

.text-primary {
  color: #FF5722 !important;
}

.btn-primary {
  background-color: #FF5722;
  border-color: #FF5722;
}

.btn-primary:hover, .btn-primary:focus {
  background-color: #E64A19;
  border-color: #E64A19;
}

.btn-outline-primary {
  color: #FF5722;
  border-color: #FF5722;
}

.btn-outline-primary:hover, .btn-outline-primary:focus {
  background-color: #FF5722;
  border-color: #FF5722;
  color: white;
}

.modal {
  background-color: rgba(0, 0, 0, 0.5);
}
</style>