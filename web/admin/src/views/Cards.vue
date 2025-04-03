<template>
  <div class="cards-view p-4">
    <div class="d-flex justify-content-between align-items-center mb-4">
      <div>
        <h1 class="fw-bold mb-1">Gestión de Cartas</h1>
        <p class="text-muted">Administra todas las cartas del juego</p>
      </div>
      <router-link to="/cards/new" class="btn btn-primary d-flex align-items-center">
        <i class="fas fa-plus-circle me-2"></i>Nueva Carta
      </router-link>
    </div>
    
    <!-- Filtros y búsqueda mejorados -->
    <div class="card mb-4">
      <div class="card-header d-flex align-items-center">
        <i class="fas fa-filter me-2" style="color: var(--primary);"></i>
        <span>Filtros y búsqueda</span>
      </div>
      <div class="card-body">
        <div class="row g-3">
          <div class="col-md-4">
            <label for="searchInput" class="form-label">Buscar</label>
            <div class="input-group">
              <span class="input-group-text" style="background-color: transparent;">
                <i class="fas fa-search text-muted"></i>
              </span>
              <input 
                type="text" 
                class="form-control" 
                id="searchInput" 
                v-model="search"
                placeholder="Nombre, tipo o descripción..."
              >
            </div>
          </div>
          
          <div class="col-md-3">
            <label for="rarityFilter" class="form-label">Rareza</label>
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
          
          <div class="col-md-3">
            <label for="typeFilter" class="form-label">Tipo</label>
            <select class="form-select" id="typeFilter" v-model="typeFilter">
              <option value="">Todos</option>
              <option value="character">Personaje</option>
              <option value="support">Soporte</option>
              <option value="equipment">Equipamiento</option>
              <option value="event">Evento</option>
            </select>
          </div>
          
          <div class="col-md-2">
            <label for="sortOrder" class="form-label">Ordenar por</label>
            <select class="form-select" id="sortOrder" v-model="sortOrder">
              <option value="name">Nombre</option>
              <option value="power">Poder</option>
              <option value="rarity">Rareza</option>
              <option value="type">Tipo</option>
            </select>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Lista de cartas -->
    <div v-if="loading" class="text-center py-5">
      <div class="spinner-border text-primary" role="status">
        <span class="visually-hidden">Cargando...</span>
      </div>
    </div>
    <div v-else-if="error" class="alert alert-danger">
      {{ error }}
      <button class="btn btn-sm btn-outline-danger ms-3" @click="loadCards">Reintentar</button>
    </div>
    <div v-else>
      <div v-if="filteredCards.length === 0" class="text-center py-5">
        <p class="text-muted">No se encontraron cartas que coincidan con los filtros</p>
      </div>
      <div v-else class="row row-cols-1 row-cols-md-2 row-cols-lg-3 row-cols-xl-4 g-4">
        <div v-for="card in filteredCards" :key="card.id" class="col">
          <div class="card h-100 shadow-sm">
            <div class="card-img-top-container">
              <img :src="prepareImageUrl(card.imageUrl)" class="card-img-top" :alt="card.name">
              <div class="card-rarity-badge" :class="'rarity-' + card.rarity">
                {{ getRarityText(card.rarity) }}
              </div>
            </div>
            <div class="card-body">
              <div class="d-flex justify-content-between align-items-start mb-2">
                <h5 class="card-title mb-0">{{ card.name }}</h5>
                <span class="badge bg-secondary">{{ getTypeText(card.type) }}</span>
              </div>
              <p class="card-text small text-muted">{{ card.description }}</p>
              <div class="d-flex align-items-center mt-3">
                <div class="me-3">
                  <i class="fas fa-bolt text-warning"></i>
                  <span class="ms-1">{{ card.power }}</span>
                </div>
                <div class="me-3">
                  <i class="fas fa-tag text-info"></i>
                  <span class="ms-1">{{ card.series }}</span>
                </div>
              </div>
            </div>
            <div class="card-footer bg-transparent d-flex justify-content-between">
              <router-link :to="'/cards/' + card.id" class="btn btn-sm btn-outline-primary">
                <i class="fas fa-edit me-1"></i>Editar
              </router-link>
              <button class="btn btn-sm btn-outline-danger" @click="confirmDelete(card)">
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
            <p>¿Estás seguro de que deseas eliminar la carta <strong>{{ selectedCard?.name }}</strong>?</p>
            <p class="text-danger">Esta acción no se puede deshacer.</p>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" @click="showDeleteModal = false">Cancelar</button>
            <button type="button" class="btn btn-danger" @click="deleteCard" :disabled="isDeleting">
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
    
    const loadCards = async () => {
      await store.dispatch('fetchCards');
    };
    
    const filteredCards = computed(() => {
      let result = [...cards.value];
      
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
      confirmDelete,
      deleteCard,
      prepareImageUrl
    };
  }
};
</script>

<style scoped>
.card-img-top-container {
  position: relative;
  height: 200px;
  overflow: hidden;
}

.card-img-top {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.card-rarity-badge {
  position: absolute;
  top: 10px;
  right: 10px;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: bold;
  color: white;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.6);
  background-color: rgba(0, 0, 0, 0.5);
}

.rarity-common { background-color: #6c757d; }
.rarity-uncommon { background-color: #28a745; }
.rarity-rare { background-color: #007bff; }
.rarity-superRare { background-color: #6f42c1; }
.rarity-ultraRare { background-color: #fd7e14; }
.rarity-legendary { background-color: #dc3545; }

.card-title {
  font-size: 1.1rem;
  font-weight: bold;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.card-text {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
  height: 60px;
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