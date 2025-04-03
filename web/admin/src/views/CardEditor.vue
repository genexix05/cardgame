<template>
  <div class="card-edit-view">
    <div class="d-flex justify-content-between align-items-center mb-4">
      <h1>{{ isEditMode ? 'Editar Carta' : 'Nueva Carta' }}</h1>
      <router-link to="/cards" class="btn btn-outline-secondary">
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
      <button v-if="isEditMode" class="btn btn-sm btn-outline-danger ms-3" @click="loadCard">Reintentar</button>
    </div>
    <div v-else>
      <form @submit.prevent="saveCard" class="needs-validation" novalidate>
        <div class="row">
          <!-- Columna izquierda - Imagen y previsualización -->
          <div class="col-md-4 mb-4">
            <div class="card shadow-sm">
              <div class="card-body">
                <h5 class="card-title mb-3">Imagen de la Carta</h5>
                
                <div class="card-preview mb-3">
                  <div v-if="previewUrl" class="preview-container mb-3">
                    <img :src="previewUrl" alt="Vista previa" class="img-fluid rounded">
                  </div>
                  <div v-else-if="cardData.imageUrl" class="preview-container mb-3">
                    <img :src="prepareImageUrl(cardData.imageUrl)" alt="Imagen actual" class="img-fluid rounded">
                  </div>
                  <div v-else class="no-image-container mb-3 d-flex justify-content-center align-items-center bg-light rounded">
                    <i class="fas fa-image text-secondary" style="font-size: 3rem;"></i>
                  </div>
                </div>
                
                <div class="mb-3">
                  <label for="cardImage" class="form-label">Seleccionar imagen</label>
                  <input 
                    type="file" 
                    class="form-control" 
                    id="cardImage" 
                    accept="image/*" 
                    @change="handleImageChange"
                  >
                  <div class="form-text">Formatos recomendados: JPG, PNG. Tamaño máximo: 2MB.</div>
                </div>
                
                <div class="card-preview-details">
                  <div class="mb-2">
                    <span class="fw-bold">Rareza:</span>
                    <span class="ms-2 badge" :class="getRarityBadgeClass(cardData.rarity)">
                      {{ getRarityText(cardData.rarity) }}
                    </span>
                  </div>
                  <div class="mb-2">
                    <span class="fw-bold">Tipo:</span>
                    <span class="ms-2 badge bg-secondary">{{ getTypeText(cardData.type) }}</span>
                  </div>
                  <div>
                    <span class="fw-bold">Poder:</span>
                    <span class="ms-2">{{ cardData.power || 0 }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Columna derecha - Formulario -->
          <div class="col-md-8">
            <div class="card shadow-sm">
              <div class="card-body">
                <h5 class="card-title mb-3">Información de la Carta</h5>
                
                <div class="row g-3">
                  <!-- Nombre -->
                  <div class="col-md-6">
                    <label for="cardName" class="form-label">Nombre *</label>
                    <input 
                      type="text" 
                      class="form-control" 
                      id="cardName" 
                      v-model="cardData.name" 
                      required
                      :class="{'is-invalid': formErrors.name}"
                    >
                    <div class="invalid-feedback" v-if="formErrors.name">
                      {{ formErrors.name }}
                    </div>
                  </div>
                  
                  <!-- Serie -->
                  <div class="col-md-6">
                    <label for="cardSeries" class="form-label">Serie *</label>
                    <input 
                      type="text" 
                      class="form-control" 
                      id="cardSeries" 
                      v-model="cardData.series" 
                      required
                      :class="{'is-invalid': formErrors.series}"
                    >
                    <div class="invalid-feedback" v-if="formErrors.series">
                      {{ formErrors.series }}
                    </div>
                  </div>
                  
                  <!-- Tipo -->
                  <div class="col-md-4">
                    <label for="cardType" class="form-label">Tipo *</label>
                    <select 
                      class="form-select" 
                      id="cardType" 
                      v-model="cardData.type" 
                      required
                      :class="{'is-invalid': formErrors.type}"
                    >
                      <option value="">Seleccionar...</option>
                      <option value="character">Personaje</option>
                      <option value="support">Soporte</option>
                      <option value="equipment">Equipamiento</option>
                      <option value="event">Evento</option>
                    </select>
                    <div class="invalid-feedback" v-if="formErrors.type">
                      {{ formErrors.type }}
                    </div>
                  </div>
                  
                  <!-- Rareza -->
                  <div class="col-md-4">
                    <label for="cardRarity" class="form-label">Rareza *</label>
                    <select 
                      class="form-select" 
                      id="cardRarity" 
                      v-model="cardData.rarity" 
                      required
                      :class="{'is-invalid': formErrors.rarity}"
                    >
                      <option value="">Seleccionar...</option>
                      <option value="common">Común</option>
                      <option value="uncommon">Poco común</option>
                      <option value="rare">Rara</option>
                      <option value="superRare">Super rara</option>
                      <option value="ultraRare">Ultra rara</option>
                      <option value="legendary">Legendaria</option>
                    </select>
                    <div class="invalid-feedback" v-if="formErrors.rarity">
                      {{ formErrors.rarity }}
                    </div>
                  </div>
                  
                  <!-- Poder -->
                  <div class="col-md-4">
                    <label for="cardPower" class="form-label">Poder *</label>
                    <input 
                      type="number" 
                      class="form-control" 
                      id="cardPower" 
                      v-model.number="cardData.power" 
                      min="0" 
                      max="100" 
                      required
                      :class="{'is-invalid': formErrors.power}"
                    >
                    <div class="invalid-feedback" v-if="formErrors.power">
                      {{ formErrors.power }}
                    </div>
                  </div>
                  
                  <!-- Descripción -->
                  <div class="col-12">
                    <label for="cardDescription" class="form-label">Descripción *</label>
                    <textarea 
                      class="form-control" 
                      id="cardDescription" 
                      v-model="cardData.description" 
                      rows="4" 
                      required
                      :class="{'is-invalid': formErrors.description}"
                    ></textarea>
                    <div class="invalid-feedback" v-if="formErrors.description">
                      {{ formErrors.description }}
                    </div>
                  </div>
                  
                  <!-- Efectos especiales (para futuras expansiones) -->
                  <div class="col-12">
                    <label for="cardEffects" class="form-label">Efectos Especiales <small class="text-muted">(opcional)</small></label>
                    <textarea 
                      class="form-control" 
                      id="cardEffects" 
                      v-model="cardData.effects" 
                      rows="2"
                    ></textarea>
                    <div class="form-text">Describe los efectos especiales de la carta, si los tiene.</div>
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
                      :disabled="isSubmitting"
                    >
                      <span v-if="isSubmitting" class="spinner-border spinner-border-sm me-2" role="status"></span>
                      {{ isEditMode ? 'Guardar Cambios' : 'Crear Carta' }}
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
  name: 'CardEditView',
  setup() {
    const store = useStore();
    const route = useRoute();
    const router = useRouter();
    
    const loading = computed(() => store.state.loading);
    const error = computed(() => store.state.error);
    
    const cardId = computed(() => route.params.id);
    const isEditMode = computed(() => !!cardId.value);
    
    const cardData = reactive({
      name: '',
      description: '',
      type: '',
      rarity: '',
      power: 0,
      series: '',
      effects: '',
      imageUrl: ''
    });
    
    const previewUrl = ref(null);
    const imageFile = ref(null);
    const isSubmitting = ref(false);
    const submitError = ref('');
    const formErrors = reactive({});
    
    // Cargar los datos de la carta si estamos en modo edición
    const loadCard = async () => {
      if (isEditMode.value) {
        try {
          const card = await store.dispatch('fetchCardById', cardId.value);
          if (card) {
            Object.keys(cardData).forEach(key => {
              if (card[key] !== undefined) {
                cardData[key] = card[key];
              }
            });
          }
        } catch (error) {
          console.error('Error al cargar carta:', error);
        }
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
      
      if (!cardData.name.trim()) {
        errors.name = 'El nombre es obligatorio';
      }
      
      if (!cardData.description.trim()) {
        errors.description = 'La descripción es obligatoria';
      }
      
      if (!cardData.type) {
        errors.type = 'El tipo es obligatorio';
      }
      
      if (!cardData.rarity) {
        errors.rarity = 'La rareza es obligatoria';
      }
      
      if (cardData.power === null || cardData.power === undefined || isNaN(cardData.power)) {
        errors.power = 'El poder es obligatorio';
      } else if (cardData.power < 0 || cardData.power > 100) {
        errors.power = 'El poder debe estar entre 0 y 100';
      }
      
      if (!cardData.series.trim()) {
        errors.series = 'La serie es obligatoria';
      }
      
      if (!isEditMode.value && !imageFile.value && !cardData.imageUrl) {
        errors.image = 'La imagen es obligatoria';
        submitError.value = 'Debes seleccionar una imagen para la carta';
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
    
    // Guardar la carta
    const saveCard = async () => {
      submitError.value = '';
      
      // Validar el formulario
      if (!validateForm()) {
        return;
      }
      
      isSubmitting.value = true;
      
      try {
        const cardToSave = { ...cardData };
        
        // Añadir la imagen si hay una nueva
        if (imageFile.value) {
          cardToSave.imageFile = imageFile.value;
        }
        
        let savedCard;
        
        if (isEditMode.value) {
          // Actualizar carta existente
          savedCard = await store.dispatch('updateCard', {
            cardId: cardId.value,
            cardData: cardToSave
          });
        } else {
          // Crear nueva carta
          savedCard = await store.dispatch('createCard', cardToSave);
        }
        
        if (savedCard) {
          // Redireccionar a la lista de cartas con mensaje de éxito
          router.push({ 
            path: '/cards',
            query: { 
              success: true,
              message: isEditMode.value ? 'Carta actualizada con éxito' : 'Carta creada con éxito'
            }
          });
        } else {
          throw new Error('Error al guardar la carta');
        }
      } catch (error) {
        console.error('Error al guardar carta:', error);
        submitError.value = `Error al ${isEditMode.value ? 'actualizar' : 'crear'} la carta. Por favor, inténtalo de nuevo.`;
      } finally {
        isSubmitting.value = false;
      }
    };
    
    // Resetear el formulario
    const resetForm = () => {
      if (isEditMode.value) {
        // Si estamos editando, volver a cargar los datos originales
        loadCard();
      } else {
        // Si estamos creando, limpiar todo el formulario
        Object.keys(cardData).forEach(key => {
          if (key === 'power') {
            cardData[key] = 0;
          } else {
            cardData[key] = '';
          }
        });
      }
      
      // Limpiar errores y previsualización
      submitError.value = '';
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
    
    const getRarityBadgeClass = (rarity) => {
      switch (rarity) {
        case 'common': return 'bg-secondary';
        case 'uncommon': return 'bg-success';
        case 'rare': return 'bg-primary';
        case 'superRare': return 'bg-purple';
        case 'ultraRare': return 'bg-warning text-dark';
        case 'legendary': return 'bg-danger';
        default: return 'bg-light text-dark';
      }
    };
    
    // Cargar la carta al montar el componente
    onMounted(() => {
      loadCard();
    });
    
    return {
      cardData,
      loading,
      error,
      isEditMode,
      previewUrl,
      isSubmitting,
      submitError,
      formErrors,
      handleImageChange,
      saveCard,
      resetForm,
      loadCard,
      getRarityText,
      getTypeText,
      getRarityBadgeClass,
      prepareImageUrl
    };
  }
};
</script>

<style scoped>
.card-preview {
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

.bg-purple {
  background-color: #6f42c1;
  color: white;
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

.form-control:focus, .form-select:focus {
  border-color: #FF5722;
  box-shadow: 0 0 0 0.25rem rgba(255, 87, 34, 0.25);
}
</style>