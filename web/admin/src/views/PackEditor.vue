<template>
  <div class="pack-edit-view">
    <div class="d-flex justify-content-between align-items-center mb-4">
      <h1>{{ isEditMode ? 'Editar Sobre' : 'Nuevo Sobre' }}</h1>
      <router-link to="/packs" class="btn btn-outline-secondary">
        <i class="fas fa-arrow-left me-2"></i>Volver
      </router-link>
    </div>
    
    <div v-if="loading && !isSubmitting" class="text-center py-5">
      <div class="spinner-border text-primary" role="status">
        <span class="visually-hidden">Cargando...</span>
      </div>
    </div>
    <div v-else-if="error && !submitError" class="alert alert-danger">
      {{ error }}
      <button v-if="isEditMode" class="btn btn-sm btn-outline-danger ms-3" @click="loadPack">Reintentar</button>
    </div>
    <div v-else>
      <form @submit.prevent="savePack" class="needs-validation" novalidate>
        <div class="row">
          <!-- Columna izquierda - Imagen y previsualización -->
          <div class="col-md-4 mb-4">
            <div class="card shadow-sm">
              <div class="card-body">
                <h5 class="card-title mb-3">Imagen del Sobre</h5>
                
                <div class="pack-preview mb-3">
                  <div v-if="previewUrl" class="preview-container mb-3">
                    <img :src="previewUrl" alt="Vista previa" class="img-fluid rounded">
                  </div>
                  <div v-else-if="packData.imageUrl" class="preview-container mb-3">
                    <img :src="prepareImageUrl(packData.imageUrl)" alt="Imagen actual" class="img-fluid rounded">
                  </div>
                  <div v-else class="no-image-container mb-3 d-flex justify-content-center align-items-center bg-light rounded">
                    <i class="fas fa-image text-secondary" style="font-size: 3rem;"></i>
                  </div>
                </div>
                
                <div class="mb-3">
                  <label for="packImage" class="form-label">Seleccionar imagen</label>
                  <input 
                    type="file" 
                    class="form-control" 
                    id="packImage" 
                    accept="image/*" 
                    @change="handleImageChange"
                  >
                  <div class="form-text">Formatos recomendados: JPG, PNG. Tamaño máximo: 2MB.</div>
                </div>
                
                <div class="pack-preview-details mt-4">
                  <div class="price-preview p-3 bg-light rounded mb-3 text-center">
                    <h3 class="mb-0">{{ packData.price || 0 }} <i class="fas fa-coins text-warning"></i></h3>
                    <div class="text-muted small">Precio del sobre</div>
                  </div>
                  
                  <div class="card-count-preview p-3 bg-light rounded text-center">
                    <h3 class="mb-0">{{ packData.cardCount || 0 }}</h3>
                    <div class="text-muted small">Cartas por sobre</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Columna derecha - Formulario -->
          <div class="col-md-8">
            <div class="card shadow-sm">
              <div class="card-body">
                <h5 class="card-title mb-3">Información del Sobre</h5>
                
                <div class="row g-3">
                  <!-- Nombre -->
                  <div class="col-md-6">
                    <label for="packName" class="form-label">Nombre *</label>
                    <input 
                      type="text" 
                      class="form-control" 
                      id="packName" 
                      v-model="packData.name" 
                      required
                      :class="{'is-invalid': formErrors.name}"
                    >
                    <div class="invalid-feedback" v-if="formErrors.name">
                      {{ formErrors.name }}
                    </div>
                  </div>
                  
                  <!-- Precio -->
                  <div class="col-md-3">
                    <label for="packPrice" class="form-label">Precio *</label>
                    <div class="input-group">
                      <input 
                        type="number" 
                        class="form-control" 
                        id="packPrice" 
                        v-model.number="packData.price" 
                        min="0" 
                        required
                        :class="{'is-invalid': formErrors.price}"
                      >
                      <span class="input-group-text"><i class="fas fa-coins text-warning"></i></span>
                      <div class="invalid-feedback" v-if="formErrors.price">
                        {{ formErrors.price }}
                      </div>
                    </div>
                  </div>
                  
                  <!-- Cantidad de cartas -->
                  <div class="col-md-3">
                    <label for="packCardCount" class="form-label">Cartas *</label>
                    <input 
                      type="number" 
                      class="form-control" 
                      id="packCardCount" 
                      v-model.number="packData.cardCount" 
                      min="1" 
                      max="20" 
                      required
                      :class="{'is-invalid': formErrors.cardCount}"
                    >
                    <div class="invalid-feedback" v-if="formErrors.cardCount">
                      {{ formErrors.cardCount }}
                    </div>
                  </div>
                  
                  <!-- Descripción -->
                  <div class="col-12">
                    <label for="packDescription" class="form-label">Descripción *</label>
                    <textarea 
                      class="form-control" 
                      id="packDescription" 
                      v-model="packData.description" 
                      rows="3" 
                      required
                      :class="{'is-invalid': formErrors.description}"
                    ></textarea>
                    <div class="invalid-feedback" v-if="formErrors.description">
                      {{ formErrors.description }}
                    </div>
                  </div>
                  
                  <!-- Fecha de lanzamiento -->
                  <div class="col-md-6">
                    <label for="packReleaseDate" class="form-label">Fecha de Lanzamiento *</label>
                    <input 
                      type="date" 
                      class="form-control" 
                      id="packReleaseDate" 
                      v-model="releaseDateStr" 
                      required
                      :class="{'is-invalid': formErrors.releaseDate}"
                    >
                    <div class="invalid-feedback" v-if="formErrors.releaseDate">
                      {{ formErrors.releaseDate }}
                    </div>
                  </div>
                  
                  <!-- Disponibilidad -->
                  <div class="col-md-6">
                    <label for="packAvailable" class="form-label">Disponibilidad</label>
                    <div class="form-check form-switch">
                      <input 
                        class="form-check-input" 
                        type="checkbox" 
                        id="packAvailable" 
                        v-model="packData.available"
                      >
                      <label class="form-check-label" for="packAvailable">
                        {{ packData.available ? 'Disponible para compra' : 'No disponible' }}
                      </label>
                    </div>
                  </div>
                  
                  <!-- Probabilidades de rareza -->
                  <div class="col-12 mt-4">
                    <h6 class="mb-3">Probabilidades de Rareza</h6>
                    <div class="alert alert-info">
                      <i class="fas fa-info-circle me-2"></i>
                      La suma de todas las probabilidades debe ser igual a 100%.
                    </div>
                    
                    <div class="row g-3">
                      <div class="col-md-4" v-for="(rarityInfo, index) in rarityList" :key="index">
                        <label :for="'probability-' + rarityInfo.value" class="form-label">
                          {{ rarityInfo.label }}
                        </label>
                        <div class="input-group">
                          <input 
                            type="number" 
                            class="form-control" 
                            :id="'probability-' + rarityInfo.value" 
                            v-model.number="probabilities[rarityInfo.value]" 
                            min="0" 
                            max="100" 
                            step="0.1"
                            @input="validateProbabilities"
                            :class="{'is-invalid': probabilityError}"
                          >
                          <span class="input-group-text">%</span>
                        </div>
                      </div>
                    </div>
                    
                    <div class="mt-2 d-flex justify-content-between align-items-center">
                      <div class="text-danger" v-if="probabilityError">
                        {{ probabilityError }}
                      </div>
                      <div class="text-success" v-else-if="probabilityTotal === 100">
                        Total: 100% ✓
                      </div>
                      <div v-else>
                        Total: {{ probabilityTotal.toFixed(1) }}%
                      </div>
                      
                      <button 
                        type="button" 
                        class="btn btn-sm btn-outline-secondary" 
                        @click="distributeProbabilities"
                      >
                        Distribuir automáticamente
                      </button>
                    </div>
                  </div>
                  
                  <!-- Contenido fijo (opcional) -->
                  <div class="col-12 mt-4">
                    <h6 class="mb-3">Contenido Fijo <small class="text-muted">(opcional)</small></h6>
                    <div class="form-text mb-3">
                      Puedes especificar cartas que se incluirán siempre en este sobre. Esto es útil para sobres temáticos o promocionales.
                    </div>
                    
                    <div v-if="loadingCards" class="text-center py-2">
                      <div class="spinner-border spinner-border-sm text-primary" role="status">
                        <span class="visually-hidden">Cargando cartas...</span>
                      </div>
                    </div>
                    <div v-else>
                      <select 
                        class="form-select mb-2" 
                        v-model="selectedCardId"
                      >
                        <option value="">Seleccionar carta para añadir...</option>
                        <option v-for="card in availableCards" :key="card.id" :value="card.id">
                          {{ card.name }} ({{ getRarityText(card.rarity) }})
                        </option>
                      </select>
                      
                      <button 
                        type="button" 
                        class="btn btn-sm btn-outline-primary mb-3" 
                        @click="addFixedCard" 
                        :disabled="!selectedCardId"
                      >
                        <i class="fas fa-plus-circle me-1"></i>Añadir Carta
                      </button>
                      
                      <div v-if="fixedCards.length === 0" class="text-center py-3 bg-light rounded">
                        <p class="text-muted mb-0">No hay cartas fijas seleccionadas</p>
                      </div>
                      <div v-else class="table-responsive">
                        <table class="table table-sm">
                          <thead>
                            <tr>
                              <th>Nombre</th>
                              <th>Rareza</th>
                              <th>Tipo</th>
                              <th></th>
                            </tr>
                          </thead>
                          <tbody>
                            <tr v-for="(cardId, index) in fixedCards" :key="index">
                              <td>{{ getCardName(cardId) }}</td>
                              <td>{{ getCardRarity(cardId) }}</td>
                              <td>{{ getCardType(cardId) }}</td>
                              <td class="text-end">
                                <button 
                                  type="button" 
                                  class="btn btn-sm btn-outline-danger" 
                                  @click="removeFixedCard(index)"
                                >
                                  <i class="fas fa-times"></i>
                                </button>
                              </td>
                            </tr>
                          </tbody>
                        </table>
                      </div>
                    </div>
                  </div>
                  
                  <!-- Mensaje de error al enviar -->
                  <div class="col-12">
                    <div class="alert alert-danger" v-if="submitError">
                      {{ submitError }}
                    </div>
                  </div>
                  
                  <!-- Botones de acción -->
                  <div class="col-12 d-flex justify-content-end mt-4">
                    <button 
                      type="button" 
                      class="btn btn-outline-secondary me-2" 
                      @click="resetForm"
                    >
                      Cancelar
                    </button>
                    <button 
                      type="submit" 
                      class="btn btn-primary" 
                      :disabled="isSubmitting || !!probabilityError"
                    >
                      <span v-if="isSubmitting" class="spinner-border spinner-border-sm me-2" role="status"></span>
                      {{ isEditMode ? 'Guardar Cambios' : 'Crear Sobre' }}
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </form>
    </div>
  </div>
</template>

<script>
import { ref, reactive, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import { prepareImageUrl } from '../utils/storage';

export default {
  name: 'PackEditView',
  setup() {
    const store = useStore();
    const route = useRoute();
    const router = useRouter();
    
    const loading = computed(() => store.state.loading);
    const error = computed(() => store.state.error);
    const cards = computed(() => store.state.cards);
    
    const packId = computed(() => route.params.id);
    const isEditMode = computed(() => !!packId.value);
    
    const packData = reactive({
      name: '',
      description: '',
      price: 100,
      cardCount: 5,
      available: true,
      releaseDate: new Date(),
      imageUrl: '',
      probabilities: {},
      fixedCards: []
    });
    
    // Para la fecha en formato string (para el input date)
    const releaseDateStr = ref(formatDateForInput(new Date()));
    
    // Para las probabilidades
    const probabilities = reactive({
      common: 50,
      uncommon: 30,
      rare: 15,
      superRare: 4,
      ultraRare: 0.9,
      legendary: 0.1
    });
    
    const rarityList = [
      { value: 'common', label: 'Común' },
      { value: 'uncommon', label: 'Poco común' },
      { value: 'rare', label: 'Rara' },
      { value: 'superRare', label: 'Super rara' },
      { value: 'ultraRare', label: 'Ultra rara' },
      { value: 'legendary', label: 'Legendaria' }
    ];
    
    // Para cartas fijas
    const fixedCards = ref([]);
    const selectedCardId = ref('');
    const loadingCards = ref(false);
    
    // Para la imagen
    const previewUrl = ref(null);
    const imageFile = ref(null);
    
    // Para el formulario
    const isSubmitting = ref(false);
    const submitError = ref('');
    const formErrors = reactive({});
    const probabilityError = ref('');
    
    // Calcular el total de probabilidades
    const probabilityTotal = computed(() => {
      return Object.values(probabilities).reduce((sum, val) => sum + (val || 0), 0);
    });
    
    // Cartas disponibles para seleccionar
    const availableCards = computed(() => {
      return cards.value.filter(card => !fixedCards.value.includes(card.id));
    });
    
    // Formatear una fecha para el input date (YYYY-MM-DD)
    function formatDateForInput(date) {
      if (!date) return '';
      
      const d = new Date(date);
      const year = d.getFullYear();
      const month = String(d.getMonth() + 1).padStart(2, '0');
      const day = String(d.getDate()).padStart(2, '0');
      
      return `${year}-${month}-${day}`;
    }
    
    // Cargar los datos del sobre si estamos en modo edición
    const loadPack = async () => {
      if (isEditMode.value) {
        try {
          const pack = await store.dispatch('fetchPackById', packId.value);
          if (pack) {
            // Cargar datos generales
            Object.keys(packData).forEach(key => {
              if (key !== 'probabilities' && key !== 'fixedCards' && pack[key] !== undefined) {
                packData[key] = pack[key];
              }
            });
            
            // Fecha de lanzamiento
            if (pack.releaseDate) {
              const date = pack.releaseDate.toDate ? pack.releaseDate.toDate() : new Date(pack.releaseDate);
              packData.releaseDate = date;
              releaseDateStr.value = formatDateForInput(date);
            }
            
            // Probabilidades
            if (pack.probabilities) {
              rarityList.forEach(rarity => {
                probabilities[rarity.value] = (pack.probabilities[rarity.value] || 0) * 100;
              });
            }
            
            // Cartas fijas
            if (pack.fixedCards && Array.isArray(pack.fixedCards)) {
              fixedCards.value = [...pack.fixedCards];
            }
          }
        } catch (error) {
          console.error('Error al cargar sobre:', error);
        }
      }
    };
    
    // Cargar las cartas disponibles
    const loadCards = async () => {
      loadingCards.value = true;
      try {
        if (cards.value.length === 0) {
          await store.dispatch('fetchCards');
        }
      } catch (error) {
        console.error('Error al cargar cartas:', error);
      } finally {
        loadingCards.value = false;
      }
    };
    
    // Manejar la selección de imagen
    const handleImageChange = (event) => {
      const file = event.target.files[0];
      if (file) {
        // Validar tamaño (máximo 2MB)
        if (file.size > 2 * 1024 * 1024) {
          submitError.value = 'La imagen es demasiado grande. El tamaño máximo es 2MB.';
          return;
        }
        
        // Validar tipo (solo imágenes)
        if (!file.type.startsWith('image/')) {
          submitError.value = 'El archivo seleccionado no es una imagen válida.';
          return;
        }
        
        // Crear URL para previsualización
        URL.revokeObjectURL(previewUrl.value);
        previewUrl.value = URL.createObjectURL(file);
        imageFile.value = file;
        submitError.value = '';
      } else {
        previewUrl.value = null;
        imageFile.value = null;
      }
    };
    
    // Validar el formulario
    const validateForm = () => {
      const errors = {};
      
      if (!packData.name.trim()) {
        errors.name = 'El nombre es obligatorio';
      }
      
      if (!packData.description.trim()) {
        errors.description = 'La descripción es obligatoria';
      }
      
      if (packData.price === null || packData.price === undefined || isNaN(packData.price)) {
        errors.price = 'El precio es obligatorio';
      } else if (packData.price < 0) {
        errors.price = 'El precio no puede ser negativo';
      }
      
      if (packData.cardCount === null || packData.cardCount === undefined || isNaN(packData.cardCount)) {
        errors.cardCount = 'La cantidad de cartas es obligatoria';
      } else if (packData.cardCount < 1) {
        errors.cardCount = 'Debe incluir al menos 1 carta';
      } else if (packData.cardCount > 20) {
        errors.cardCount = 'No puede incluir más de 20 cartas';
      }
      
      if (!releaseDateStr.value) {
        errors.releaseDate = 'La fecha de lanzamiento es obligatoria';
      }
      
      if (probabilityTotal.value !== 100) {
        errors.probabilities = 'La suma de las probabilidades debe ser 100%';
      }
      
      if (!isEditMode.value && !imageFile.value && !packData.imageUrl) {
        errors.image = 'La imagen es obligatoria';
        submitError.value = 'Debes seleccionar una imagen para el sobre';
      }
      
      // Actualizar errores del formulario
      Object.keys(formErrors).forEach(key => {
        delete formErrors[key];
      });
      
      Object.keys(errors).forEach(key => {
        formErrors[key] = errors[key];
      });
      
      return Object.keys(errors).length === 0;
    };
    
    // Validar que las probabilidades sumen 100%
    const validateProbabilities = () => {
      if (probabilityTotal.value !== 100) {
        probabilityError.value = `La suma debe ser 100% (actual: ${probabilityTotal.value.toFixed(1)}%)`;
      } else {
        probabilityError.value = '';
      }
    };
    
    // Distribuir las probabilidades automáticamente
    const distributeProbabilities = () => {
      // Distribución predeterminada basada en la rareza
      probabilities.common = 50;
      probabilities.uncommon = 30;
      probabilities.rare = 15;
      probabilities.superRare = 4;
      probabilities.ultraRare = 0.9;
      probabilities.legendary = 0.1;
      
      validateProbabilities();
    };
    
    // Añadir una carta fija
    const addFixedCard = () => {
      if (selectedCardId.value && !fixedCards.value.includes(selectedCardId.value)) {
        fixedCards.value.push(selectedCardId.value);
        selectedCardId.value = '';
      }
    };
    
    // Eliminar una carta fija
    const removeFixedCard = (index) => {
      fixedCards.value.splice(index, 1);
    };
    
    // Obtener información de las cartas
    const getCardName = (cardId) => {
      const card = cards.value.find(c => c.id === cardId);
      return card ? card.name : 'Carta desconocida';
    };
    
    const getCardRarity = (cardId) => {
      const card = cards.value.find(c => c.id === cardId);
      return card ? getRarityText(card.rarity) : '';
    };
    
    const getCardType = (cardId) => {
      const card = cards.value.find(c => c.id === cardId);
      return card ? getTypeText(card.type) : '';
    };
    
    // Guardar el sobre
    const savePack = async () => {
      submitError.value = '';
      
      // Validar probabilidades
      if (probabilityTotal.value !== 100) {
        probabilityError.value = `La suma debe ser 100% (actual: ${probabilityTotal.value.toFixed(1)}%)`;
        return;
      }
      
      // Validar el formulario
      if (!validateForm()) {
        return;
      }
      
      isSubmitting.value = true;
      
      try {
        // Preparar los datos para guardar
        const packToSave = { ...packData };
        
        // Convertir probabilidades de porcentaje a decimal (0-1)
        packToSave.probabilities = {};
        rarityList.forEach(rarity => {
          packToSave.probabilities[rarity.value] = probabilities[rarity.value] / 100;
        });
        
        // Cartas fijas
        packToSave.fixedCards = [...fixedCards.value];
        
        // Fecha de lanzamiento
        if (releaseDateStr.value) {
          packToSave.releaseDate = new Date(releaseDateStr.value);
        }
        
        // Añadir la imagen si hay una nueva
        if (imageFile.value) {
          packToSave.imageFile = imageFile.value;
        }
        
        let savedPack;
        
        if (isEditMode.value) {
          // Actualizar sobre existente
          savedPack = await store.dispatch('updatePack', {
            packId: packId.value,
            packData: packToSave
          });
        } else {
          // Crear nuevo sobre
          savedPack = await store.dispatch('createPack', packToSave);
        }
        
        if (savedPack) {
          // Redireccionar a la lista de sobres con mensaje de éxito
          router.push({ 
            path: '/packs',
            query: { 
              success: true,
              message: isEditMode.value ? 'Sobre actualizado con éxito' : 'Sobre creado con éxito'
            }
          });
        } else {
          throw new Error('Error al guardar el sobre');
        }
      } catch (error) {
        console.error('Error al guardar sobre:', error);
        submitError.value = `Error al ${isEditMode.value ? 'actualizar' : 'crear'} el sobre. Por favor, inténtalo de nuevo.`;
      } finally {
        isSubmitting.value = false;
      }
    };
    
    // Resetear el formulario
    const resetForm = () => {
      if (isEditMode.value) {
        // Si estamos editando, volver a cargar los datos originales
        loadPack();
      } else {
        // Si estamos creando, limpiar todo el formulario
        packData.name = '';
        packData.description = '';
        packData.price = 100;
        packData.cardCount = 5;
        packData.available = true;
        packData.releaseDate = new Date();
        packData.imageUrl = '';
        
        releaseDateStr.value = formatDateForInput(new Date());
        
        distributeProbabilities();
        
        fixedCards.value = [];
        selectedCardId.value = '';
      }
      
      // Limpiar errores y previsualización
      submitError.value = '';
      probabilityError.value = '';
      Object.keys(formErrors).forEach(key => {
        delete formErrors[key];
      });
      
      if (previewUrl.value) {
        URL.revokeObjectURL(previewUrl.value);
        previewUrl.value = null;
      }
      
      imageFile.value = null;
    };
    
    // Textos formatados
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
    
    // Actualizar la fecha cuando cambia el input
    watch(releaseDateStr, (newValue) => {
      if (newValue) {
        packData.releaseDate = new Date(newValue);
      }
    });
    
    // Inicializar
    onMounted(() => {
      loadPack();
      loadCards();
      validateProbabilities();
    });
    
    return {
      packData,
      loading,
      error,
      isEditMode,
      previewUrl,
      isSubmitting,
      submitError,
      formErrors,
      releaseDateStr,
      probabilities,
      rarityList,
      probabilityTotal,
      probabilityError,
      fixedCards,
      selectedCardId,
      loadingCards,
      availableCards,
      
      handleImageChange,
      savePack,
      resetForm,
      loadPack,
      validateProbabilities,
      distributeProbabilities,
      addFixedCard,
      removeFixedCard,
      getCardName,
      getCardRarity,
      getCardType,
      getRarityText,
      getTypeText,
      prepareImageUrl
    };
  }
};
</script>

<style scoped>
.pack-preview {
  min-height: 200px;
  border-radius: 8px;
  overflow: hidden;
}

.preview-container img {
  width: 100%;
  object-fit: cover;
  max-height: 300px;
}

.no-image-container {
  height: 200px;
  border: 2px dashed #dee2e6;
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

.form-control:focus, .form-select:focus {
  border-color: #FF5722;
  box-shadow: 0 0 0 0.25rem rgba(255, 87, 34, 0.25);
}

.form-check-input:checked {
  background-color: #FF5722;
  border-color: #FF5722;
}
</style>