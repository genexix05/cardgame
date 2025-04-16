<template>
  <div class="card-edit-view p-6">
    <!-- Encabezado -->
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold text-gray-800">{{ isEditMode ? 'Editar Carta' : 'Nueva Carta' }}</h1>
        <p class="text-gray-600 mt-1">Completa la información de la carta</p>
      </div>
      <router-link to="/cards" class="btn-outline-secondary">
        <i class="fas fa-arrow-left mr-2"></i>Volver
      </router-link>
    </div>
    
    <!-- Cargando -->
    <div v-if="loading && !isSubmitting" class="flex justify-center items-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
    </div>
    
    <!-- Error -->
    <div v-else-if="error && !submitError" class="bg-red-50 border-l-4 border-red-400 p-4 mb-6">
      <div class="flex">
        <div class="flex-shrink-0">
          <i class="fas fa-exclamation-circle text-red-400"></i>
        </div>
        <div class="ml-3">
          <p class="text-sm text-red-700">{{ error }}</p>
        </div>
        <div class="ml-auto pl-3" v-if="isEditMode">
          <button class="btn-outline-danger" @click="loadCard">Reintentar</button>
        </div>
      </div>
    </div>
    
    <!-- Formulario -->
    <div v-else class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Columna izquierda - Imagen y previsualización -->
      <div class="lg:col-span-1">
        <div class="bg-white rounded-lg shadow-sm p-6">
          <h3 class="text-lg font-semibold text-gray-800 mb-4">Imagen de la Carta</h3>
          
          <div class="card-preview mb-4">
            <div v-if="previewUrl" class="preview-container">
              <img :src="previewUrl" alt="Vista previa" class="w-full h-64 object-cover rounded-lg">
            </div>
            <div v-else-if="cardData.imageUrl" class="preview-container">
              <img :src="prepareImageUrl(cardData.imageUrl)" alt="Imagen actual" class="w-full h-64 object-cover rounded-lg">
            </div>
            <div v-else class="no-image-container h-64 flex items-center justify-center bg-gray-50 rounded-lg border-2 border-dashed border-gray-300">
              <i class="fas fa-image text-gray-400 text-4xl"></i>
            </div>
          </div>
          
          <div class="mb-4">
            <label for="cardImage" class="block text-sm font-medium text-gray-700 mb-1">Seleccionar imagen</label>
            <input 
              type="file" 
              class="form-control" 
              id="cardImage" 
              accept="image/*" 
              @change="handleImageChange"
            >
            <p class="text-xs text-gray-500 mt-1">Formatos recomendados: JPG, PNG. Tamaño máximo: 2MB.</p>
          </div>
          
          <div class="space-y-2">
            <div class="flex items-center">
              <span class="font-medium text-gray-700">Rareza:</span>
              <span class="ml-2 badge" :class="getRarityBadgeClass(cardData.rarity)">
                {{ getRarityText(cardData.rarity) }}
              </span>
            </div>
            <div class="flex items-center">
              <span class="font-medium text-gray-700">Tipo:</span>
              <span class="ml-2 badge bg-gray-100 text-gray-800">
                {{ getTypeText(cardData.type) }}
              </span>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Columna derecha - Formulario -->
      <div class="lg:col-span-2">
        <div class="bg-white rounded-lg shadow-sm p-6">
          <h3 class="text-lg font-semibold text-gray-800 mb-4">Información de la Carta</h3>
          
          <form @submit.prevent="saveCard" class="space-y-6">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <!-- Nombre -->
              <div>
                <label for="cardName" class="block text-sm font-medium text-gray-700 mb-1">Nombre *</label>
                <input 
                  type="text" 
                  class="form-control" 
                  id="cardName" 
                  v-model="cardData.name" 
                  required
                  :class="{'border-red-500': formErrors.name}"
                >
                <p v-if="formErrors.name" class="text-sm text-red-500 mt-1">{{ formErrors.name }}</p>
              </div>
              
              <!-- Serie -->
              <div>
                <label for="cardSeries" class="block text-sm font-medium text-gray-700 mb-1">Serie *</label>
                <input 
                  type="text" 
                  class="form-control" 
                  id="cardSeries" 
                  v-model="cardData.series" 
                  required
                  :class="{'border-red-500': formErrors.series}"
                >
                <p v-if="formErrors.series" class="text-sm text-red-500 mt-1">{{ formErrors.series }}</p>
              </div>
              
              <!-- Tipo -->
              <div>
                <label for="cardType" class="block text-sm font-medium text-gray-700 mb-1">Tipo *</label>
                <select 
                  class="form-select" 
                  id="cardType" 
                  v-model="cardData.type" 
                  required
                  :class="{'border-red-500': formErrors.type}"
                >
                  <option value="">Selecciona un tipo</option>
                  <option value="character">Personaje</option>
                  <option value="support">Soporte</option>
                  <option value="equipment">Equipamiento</option>
                  <option value="event">Evento</option>
                </select>
                <p v-if="formErrors.type" class="text-sm text-red-500 mt-1">{{ formErrors.type }}</p>
              </div>
              
              <!-- Rareza -->
              <div>
                <label for="cardRarity" class="block text-sm font-medium text-gray-700 mb-1">Rareza *</label>
                <select 
                  class="form-select" 
                  id="cardRarity" 
                  v-model="cardData.rarity" 
                  required
                  :class="{'border-red-500': formErrors.rarity}"
                >
                  <option value="">Seleccionar...</option>
                  <option value="common">Común</option>
                  <option value="uncommon">Poco común</option>
                  <option value="rare">Rara</option>
                  <option value="superRare">Super rara</option>
                  <option value="ultraRare">Ultra rara</option>
                  <option value="legendary">Legendaria</option>
                </select>
                <p v-if="formErrors.rarity" class="text-sm text-red-500 mt-1">{{ formErrors.rarity }}</p>
              </div>
            </div>
            
            <!-- Atributos de personaje -->
            <div v-if="cardData.type === 'character'" class="grid grid-cols-1 md:grid-cols-3 gap-6 mt-6">
              <div>
                <label for="cardHealth" class="block text-sm font-medium text-gray-700 mb-1">Vida *</label>
                <input 
                  type="number" 
                  class="form-control" 
                  id="cardHealth" 
                  v-model.number="cardData.health" 
                  min="0" 
                  max="100" 
                  required
                  :class="{'border-red-500': formErrors.health}"
                >
                <p v-if="formErrors.health" class="text-sm text-red-500 mt-1">{{ formErrors.health }}</p>
              </div>

              <div>
                <label for="cardAttack" class="block text-sm font-medium text-gray-700 mb-1">Ataque *</label>
                <input 
                  type="number" 
                  class="form-control" 
                  id="cardAttack" 
                  v-model.number="cardData.attack" 
                  min="0" 
                  max="100" 
                  required
                  :class="{'border-red-500': formErrors.attack}"
                >
                <p v-if="formErrors.attack" class="text-sm text-red-500 mt-1">{{ formErrors.attack }}</p>
              </div>

              <div>
                <label for="cardDefense" class="block text-sm font-medium text-gray-700 mb-1">Defensa *</label>
                <input 
                  type="number" 
                  class="form-control" 
                  id="cardDefense" 
                  v-model.number="cardData.defense" 
                  min="0" 
                  max="100" 
                  required
                  :class="{'border-red-500': formErrors.defense}"
                >
                <p v-if="formErrors.defense" class="text-sm text-red-500 mt-1">{{ formErrors.defense }}</p>
              </div>
            </div>
            
            <!-- Descripción -->
            <div>
              <label for="cardDescription" class="block text-sm font-medium text-gray-700 mb-1">Descripción *</label>
              <textarea 
                class="form-control" 
                id="cardDescription" 
                v-model="cardData.description" 
                rows="4" 
                required
                :class="{'border-red-500': formErrors.description}"
              ></textarea>
              <p v-if="formErrors.description" class="text-sm text-red-500 mt-1">{{ formErrors.description }}</p>
            </div>
            
            <!-- Efectos especiales -->
            <div>
              <label for="cardEffects" class="block text-sm font-medium text-gray-700 mb-1">
                Efectos Especiales <span class="text-gray-500">(opcional)</span>
              </label>
              <textarea 
                class="form-control" 
                id="cardEffects" 
                v-model="cardData.effects" 
                rows="2"
              ></textarea>
              <p class="text-xs text-gray-500 mt-1">Describe los efectos especiales de la carta, si los tiene.</p>
            </div>
            
            <!-- Categorías -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-2">Categorías</label>
              <div class="flex flex-wrap gap-2">
                <div v-for="category in availableCategories" :key="category.id" class="flex items-center">
                  <input 
                    class="form-checkbox h-4 w-4 text-primary focus:ring-primary border-gray-300 rounded" 
                    type="checkbox" 
                    :id="'category-' + category.id"
                    :value="category.id"
                    v-model="cardData.categories"
                  >
                  <label :for="'category-' + category.id" class="ml-2 text-sm text-gray-700">
                    {{ category.name }}
                  </label>
                </div>
              </div>
              <p class="text-xs text-gray-500 mt-1">Selecciona las categorías que aplican a esta carta.</p>
            </div>
            
            <!-- Error al enviar -->
            <div v-if="submitError" class="bg-red-50 border-l-4 border-red-400 p-4">
              <div class="flex">
                <div class="flex-shrink-0">
                  <i class="fas fa-exclamation-circle text-red-400"></i>
                </div>
                <div class="ml-3">
                  <p class="text-sm text-red-700">{{ submitError }}</p>
                </div>
              </div>
            </div>
            
            <!-- Botones de acción -->
            <div class="flex justify-end space-x-3 pt-4 border-t">
              <button 
                type="button" 
                class="btn-outline-secondary" 
                @click="resetForm"
              >
                Cancelar
              </button>
              <button 
                type="submit" 
                class="btn-primary" 
                :disabled="isSubmitting"
              >
                <span v-if="isSubmitting" class="animate-spin mr-2">⌛</span>
                {{ isEditMode ? 'Guardar Cambios' : 'Crear Carta' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, reactive, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import { prepareImageUrl } from '../utils/storage';
import { collection, getDocs } from 'firebase/firestore';
import { db } from '../firebase';

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
      series: '',
      effects: '',
      imageUrl: '',
      categories: [],
      health: 0,
      attack: 0,
      defense: 0
    });
    
    const previewUrl = ref(null);
    const imageFile = ref(null);
    const isSubmitting = ref(false);
    const submitError = ref('');
    const formErrors = reactive({});
    
    const availableCategories = ref([]);
    
    const loadCategories = async () => {
      try {
        const categoriesRef = collection(db, 'categories');
        const querySnapshot = await getDocs(categoriesRef);
        
        availableCategories.value = querySnapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
        }));
      } catch (err) {
        console.error('Error al cargar categorías:', err);
      }
    };
    
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
            // Asegurarse de que categories sea un array
            if (!Array.isArray(cardData.categories)) {
              cardData.categories = [];
            }
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
    
    // Guardar la carta
    const saveCard = async () => {
      isSubmitting.value = true;
      submitError.value = '';
      formErrors.name = '';
      formErrors.type = '';
      formErrors.rarity = '';
      formErrors.series = '';
      formErrors.description = '';
      formErrors.health = '';
      formErrors.attack = '';
      formErrors.defense = '';
      
      try {
        // Validación básica
        if (!cardData.name.trim()) {
          formErrors.name = 'El nombre es requerido';
          return;
        }
        if (!cardData.type) {
          formErrors.type = 'El tipo es requerido';
          return;
        }
        if (!cardData.rarity) {
          formErrors.rarity = 'La rareza es requerida';
          return;
        }
        if (!cardData.series.trim()) {
          formErrors.series = 'La serie es requerida';
          return;
        }
        if (!cardData.description.trim()) {
          formErrors.description = 'La descripción es requerida';
          return;
        }

        // Validación adicional para cartas de tipo personaje
        if (cardData.type === 'character') {
          if (!cardData.health || cardData.health < 0) {
            formErrors.health = 'La vida debe ser un número positivo';
            return;
          }
          if (!cardData.attack || cardData.attack < 0) {
            formErrors.attack = 'El ataque debe ser un número positivo';
            return;
          }
          if (!cardData.defense || cardData.defense < 0) {
            formErrors.defense = 'La defensa debe ser un número positivo';
            return;
          }
        }
        
        // Preparar los datos para guardar
        const cardToSave = { ...cardData };
        
        // Si hay una imagen para subir
        if (imageFile.value) {
          try {
            // Convertir imagen a base64 con compresión
            const base64Image = await compressAndConvertToBase64(
              imageFile.value, 
              800,  // Ancho máximo en píxeles
              0.7   // Calidad (0-1)
            );
            
            // Guardar la imagen como string base64
            cardToSave.imageUrl = base64Image;
          } catch (error) {
            console.error('Error al procesar imagen:', error);
            submitError.value = 'Error al procesar la imagen. Por favor, inténtalo de nuevo.';
            return;
          }
        }
        
        // Asegurarse de que categories sea un array
        if (!Array.isArray(cardToSave.categories)) {
          cardToSave.categories = [];
        }
        
        if (isEditMode.value) {
          // Actualizar carta existente
          await store.dispatch('updateCard', {
            id: cardId.value,
            cardData: cardToSave
          });
        } else {
          // Crear nueva carta
          await store.dispatch('createCard', cardToSave);
        }
        
        router.push('/cards');
      } catch (error) {
        console.error('Error al guardar carta:', error);
        submitError.value = 'Error al guardar la carta. Por favor, inténtalo de nuevo.';
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
          if (key === 'health' || key === 'attack' || key === 'defense') {
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
        case 'common': return 'bg-gray-100 text-gray-800';
        case 'uncommon': return 'bg-green-100 text-green-800';
        case 'rare': return 'bg-blue-100 text-blue-800';
        case 'superRare': return 'bg-purple-100 text-purple-800';
        case 'ultraRare': return 'bg-yellow-100 text-yellow-800';
        case 'legendary': return 'bg-red-100 text-red-800';
        default: return 'bg-gray-100 text-gray-800';
      }
    };
    
    // Cargar la carta al montar el componente
    onMounted(() => {
      loadCategories();
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
      prepareImageUrl,
      availableCategories
    };
  }
};
</script>

<style scoped>
.card-edit-view {
  @apply min-h-screen bg-gray-50;
}

.card-preview {
  @apply rounded-lg overflow-hidden;
}

.preview-container img {
  @apply w-full h-64 object-cover rounded-lg;
}

.no-image-container {
  @apply h-64 flex items-center justify-center bg-gray-50 rounded-lg border-2 border-dashed border-gray-300;
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

.btn-primary {
  @apply bg-gradient-to-r from-orange-500 to-orange-600 text-white px-4 py-2 rounded-lg 
         flex items-center hover:from-orange-600 hover:to-orange-700 transition-all 
         disabled:opacity-50 disabled:cursor-not-allowed;
}

.btn-outline-primary {
  @apply border border-orange-500 text-orange-500 px-3 py-1 rounded-lg 
         flex items-center hover:bg-orange-50 transition-all;
}

.btn-outline-secondary {
  @apply border border-gray-300 text-gray-700 px-3 py-1 rounded-lg 
         flex items-center hover:bg-gray-50 transition-all;
}

.btn-outline-danger {
  @apply border border-red-500 text-red-500 px-3 py-1 rounded-lg 
         flex items-center hover:bg-red-50 transition-all;
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