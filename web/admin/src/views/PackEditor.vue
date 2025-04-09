<template>
  <div class="pack-edit-view p-6">
    <!-- Encabezado -->
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-2xl font-bold text-gray-800">{{ isEditMode ? 'Editar Sobre' : 'Nuevo Sobre' }}</h1>
        <p class="text-gray-600 mt-1">Completa la información del sobre</p>
      </div>
      <router-link to="/packs" class="btn-outline-secondary">
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
          <button class="btn-outline-danger" @click="loadPack">Reintentar</button>
        </div>
      </div>
    </div>
    
    <!-- Formulario -->
    <div v-else class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Columna izquierda - Imagen y previsualización -->
      <div class="lg:col-span-1">
        <div class="bg-white rounded-lg shadow-sm p-6">
          <h3 class="text-lg font-semibold text-gray-800 mb-4">Imagen del Sobre</h3>
          
          <div class="pack-preview mb-4">
            <div v-if="previewUrl" class="preview-container">
              <img :src="previewUrl" alt="Vista previa" class="w-full h-64 object-cover rounded-lg">
            </div>
            <div v-else-if="packData.imageUrl" class="preview-container">
              <img :src="prepareImageUrl(packData.imageUrl)" alt="Imagen actual" class="w-full h-64 object-cover rounded-lg">
            </div>
            <div v-else class="no-image-container h-64 flex items-center justify-center bg-gray-50 rounded-lg border-2 border-dashed border-gray-300">
              <i class="fas fa-image text-gray-400 text-4xl"></i>
            </div>
          </div>
          
          <div class="mb-4">
            <label for="packImage" class="block text-sm font-medium text-gray-700 mb-1">Seleccionar imagen</label>
            <input 
              type="file" 
              class="form-control" 
              id="packImage" 
              accept="image/*" 
              @change="handleImageChange"
            >
            <p class="text-xs text-gray-500 mt-1">Formatos recomendados: JPG, PNG. Tamaño máximo: 2MB.</p>
          </div>
          
          <div class="space-y-4">
            <div class="bg-gray-50 rounded-lg p-4 text-center">
              <h3 class="text-2xl font-bold text-gray-800 mb-1">{{ packData.price || 0 }}</h3>
              <div class="text-sm text-gray-600">Precio del sobre</div>
            </div>
            
            <div class="bg-gray-50 rounded-lg p-4 text-center">
              <h3 class="text-2xl font-bold text-gray-800 mb-1">{{ packData.cardCount || 0 }}</h3>
              <div class="text-sm text-gray-600">Cartas por sobre</div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Columna derecha - Formulario -->
      <div class="lg:col-span-2">
        <div class="bg-white rounded-lg shadow-sm p-6">
          <h3 class="text-lg font-semibold text-gray-800 mb-4">Información del Sobre</h3>
          
          <form @submit.prevent="savePack" class="space-y-6">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <!-- Nombre -->
              <div>
                <label for="packName" class="block text-sm font-medium text-gray-700 mb-1">Nombre *</label>
                <input 
                  type="text" 
                  class="form-control" 
                  id="packName" 
                  v-model="packData.name" 
                  required
                  :class="{'border-red-500': formErrors.name}"
                >
                <p v-if="formErrors.name" class="text-sm text-red-500 mt-1">{{ formErrors.name }}</p>
              </div>
              
              <!-- Precio -->
              <div>
                <label for="packPrice" class="block text-sm font-medium text-gray-700 mb-1">Precio *</label>
                <div class="relative">
                  <input 
                    type="number" 
                    class="form-control pl-10" 
                    id="packPrice" 
                    v-model.number="packData.price" 
                    min="0" 
                    required
                    :class="{'border-red-500': formErrors.price}"
                  >
                  <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <i class="fas fa-coins text-yellow-500"></i>
                  </div>
                </div>
                <p v-if="formErrors.price" class="text-sm text-red-500 mt-1">{{ formErrors.price }}</p>
              </div>
              
              <!-- Cantidad de cartas -->
              <div>
                <label for="packCardCount" class="block text-sm font-medium text-gray-700 mb-1">Cartas *</label>
                <input 
                  type="number" 
                  class="form-control" 
                  id="packCardCount" 
                  v-model.number="packData.cardCount" 
                  min="1" 
                  max="20" 
                  required
                  :class="{'border-red-500': formErrors.cardCount}"
                >
                <p v-if="formErrors.cardCount" class="text-sm text-red-500 mt-1">{{ formErrors.cardCount }}</p>
              </div>
              
              <!-- Fecha de lanzamiento -->
              <div>
                <label for="packReleaseDate" class="block text-sm font-medium text-gray-700 mb-1">Fecha de Lanzamiento *</label>
                <input 
                  type="date" 
                  class="form-control" 
                  id="packReleaseDate" 
                  v-model="releaseDateStr" 
                  required
                  :class="{'border-red-500': formErrors.releaseDate}"
                >
                <p v-if="formErrors.releaseDate" class="text-sm text-red-500 mt-1">{{ formErrors.releaseDate }}</p>
              </div>
            </div>
            
            <!-- Descripción -->
            <div>
              <label for="packDescription" class="block text-sm font-medium text-gray-700 mb-1">Descripción *</label>
              <textarea 
                class="form-control" 
                id="packDescription" 
                v-model="packData.description" 
                rows="3" 
                required
                :class="{'border-red-500': formErrors.description}"
              ></textarea>
              <p v-if="formErrors.description" class="text-sm text-red-500 mt-1">{{ formErrors.description }}</p>
            </div>
            
            <!-- Disponibilidad -->
            <div>
              <label class="flex items-center">
                <input 
                  type="checkbox" 
                  class="form-checkbox h-5 w-5 text-primary focus:ring-primary border-gray-300 rounded" 
                  v-model="packData.available"
                >
                <span class="ml-2 text-sm text-gray-700">
                  {{ packData.available ? 'Disponible para compra' : 'No disponible' }}
                </span>
              </label>
            </div>
            
            <!-- Probabilidades de rareza -->
            <div class="space-y-4">
              <div class="flex items-center justify-between">
                <h4 class="text-lg font-medium text-gray-800">Probabilidades de Rareza</h4>
                <button 
                  type="button" 
                  class="btn-outline-secondary text-sm" 
                  @click="distributeProbabilities"
                >
                  Distribuir automáticamente
                </button>
              </div>
              
              <div class="bg-blue-50 border-l-4 border-blue-400 p-4">
                <div class="flex">
                  <div class="flex-shrink-0">
                    <i class="fas fa-info-circle text-blue-400"></i>
                  </div>
                  <div class="ml-3">
                    <p class="text-sm text-blue-700">La suma de todas las probabilidades debe ser igual a 100%.</p>
                  </div>
                </div>
              </div>
              
              <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                <div v-for="(rarityInfo, index) in rarityList" :key="index">
                  <label :for="'probability-' + rarityInfo.value" class="block text-sm font-medium text-gray-700 mb-1">
                    {{ rarityInfo.label }}
                  </label>
                  <div class="relative">
                    <input 
                      type="number" 
                      class="form-control pr-10" 
                      :id="'probability-' + rarityInfo.value" 
                      v-model.number="probabilities[rarityInfo.value]" 
                      min="0" 
                      max="100" 
                      step="0.1"
                      @input="validateProbabilities"
                      :class="{'border-red-500': probabilityError}"
                    >
                    <div class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
                      <span class="text-gray-500">%</span>
                    </div>
                  </div>
                </div>
              </div>
              
              <div class="flex items-center justify-between">
                <div v-if="probabilityError" class="text-sm text-red-500">
                  {{ probabilityError }}
                </div>
                <div v-else-if="probabilityTotal === 100" class="text-sm text-green-500">
                  Total: 100% ✓
                </div>
                <div v-else class="text-sm text-gray-500">
                  Total: {{ probabilityTotal.toFixed(1) }}%
                </div>
              </div>
            </div>
            
            <!-- Cartas fijas -->
            <div class="space-y-4">
              <h4 class="text-lg font-medium text-gray-800">Cartas Fijas</h4>
              
              <div v-if="loadingCards" class="flex justify-center py-4">
                <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
              </div>
              
              <div v-else>
                <div class="flex items-center gap-2 mb-4">
                  <select 
                    class="form-select flex-1" 
                    v-model="selectedCardId"
                  >
                    <option value="">Seleccionar carta para añadir...</option>
                    <option v-for="card in availableCards" :key="card.id" :value="card.id">
                      {{ card.name }} ({{ getRarityText(card.rarity) }})
                    </option>
                  </select>
                  
                  <button 
                    type="button" 
                    class="btn-outline-primary" 
                    @click="addFixedCard" 
                    :disabled="!selectedCardId"
                  >
                    <i class="fas fa-plus-circle mr-1"></i>Añadir
                  </button>
                </div>
                
                <div v-if="fixedCards.length === 0" class="bg-gray-50 rounded-lg p-4 text-center">
                  <p class="text-gray-600">No hay cartas fijas seleccionadas</p>
                  <p class="text-sm text-gray-500 mt-1">Al añadir cartas fijas, estas aparecerán siempre en este sobre cuando un usuario lo abra.</p>
                </div>
                
                <div v-else class="space-y-4">
                  <div class="bg-green-50 border-l-4 border-green-400 p-4">
                    <div class="flex items-center">
                      <div class="flex-shrink-0">
                        <i class="fas fa-info-circle text-green-400"></i>
                      </div>
                      <div class="ml-3">
                        <p class="text-sm text-green-700">
                          Este sobre contendrá {{ fixedCards.length }} carta(s) garantizada(s)
                        </p>
                      </div>
                    </div>
                  </div>
                  
                  <div class="overflow-x-auto">
                    <table class="min-w-full divide-y divide-gray-200">
                      <thead class="bg-gray-50">
                        <tr>
                          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">#</th>
                          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Nombre</th>
                          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Rareza</th>
                          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Tipo</th>
                          <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Acciones</th>
                        </tr>
                      </thead>
                      <tbody class="bg-white divide-y divide-gray-200">
                        <tr v-for="(cardId, index) in fixedCards" :key="index">
                          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ index + 1 }}</td>
                          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{{ getCardName(cardId) }}</td>
                          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ getCardRarity(cardId) }}</td>
                          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ getCardType(cardId) }}</td>
                          <td class="px-6 py-4 whitespace-nowrap text-right text-sm">
                            <button 
                              type="button" 
                              class="btn-outline-danger" 
                              @click="removeFixedCard(index)"
                              :title="`Eliminar ${getCardName(cardId)}`"
                            >
                              <i class="fas fa-times"></i>
                            </button>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                  
                  <p class="text-xs text-gray-500">Nota: Si añades más cartas fijas que el número total de cartas del sobre, todas las cartas fijas serán incluidas.</p>
                  
                  <div class="bg-yellow-50 border-l-4 border-yellow-400 p-4">
                    <div class="flex">
                      <div class="flex-shrink-0">
                        <i class="fas fa-exclamation-triangle text-yellow-400"></i>
                      </div>
                      <div class="ml-3">
                        <p class="text-sm text-yellow-700">
                          <strong>¡No olvides guardar!</strong> Haz clic en el botón "Guardar Sobre" al final del formulario para que las cartas fijas se guarden correctamente.
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
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
                :disabled="isSubmitting || !!probabilityError"
              >
                <span v-if="isSubmitting" class="animate-spin mr-2">⌛</span>
                {{ isEditMode ? 'Guardar Cambios' : 'Crear Sobre' }}
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
            console.log('Sobre cargado desde Firestore:', pack);
            
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
            
            // Cartas fijas - Asegurarse de que es un array válido
            console.log('Cargando fixedCards desde el sobre:', pack.fixedCards);
            
            // Verificar si fixedCards es un array válido en Firestore
            if (pack.fixedCards && Array.isArray(pack.fixedCards)) {
              // Crear un nuevo array con los datos de Firestore
              const loadedFixedCards = [...pack.fixedCards];
              
              // Asignar el nuevo array al ref
              fixedCards.value = loadedFixedCards;
              
              console.log('Cartas fijas cargadas correctamente:', fixedCards.value);
            } else {
              // Inicializar como array vacío si no hay datos válidos
              fixedCards.value = [];
              console.log('No se encontraron cartas fijas válidas en el sobre. Inicializado como []');
            }
          } else {
            console.error('No se pudo cargar el sobre con ID:', packId.value);
            fixedCards.value = []; // Asegurar que sea un array vacío en caso de error
          }
        } catch (error) {
          console.error('Error al cargar sobre:', error);
          fixedCards.value = []; // Asegurar que sea un array vacío en caso de error
        }
      } else {
        // Si no estamos en modo edición, inicializar como array vacío
        fixedCards.value = [];
        console.log('Modo creación: fixedCards inicializado como array vacío');
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
      // Limpiar errores anteriores
      submitError.value = '';
      
      if (!selectedCardId.value) {
        console.log('No hay carta seleccionada para añadir');
        submitError.value = 'Por favor, selecciona una carta para añadir';
        return;
      }
      
      // Asegurarse de que fixedCards.value sea un array
      if (!Array.isArray(fixedCards.value)) {
        console.warn('fixedCards no era un array, inicializando como array vacío');
        fixedCards.value = [];
      }
      
      // Verificar si la carta ya está en el array
      if (fixedCards.value.includes(selectedCardId.value)) {
        console.log('La carta ya está en fixedCards:', selectedCardId.value);
        submitError.value = 'Esta carta ya ha sido añadida al sobre';
        selectedCardId.value = '';
        return;
      }
      
      // Crear un nuevo array con la carta añadida (para asegurar reactividad)
      const newFixedCards = [...fixedCards.value, selectedCardId.value];
      
      // Asignar el nuevo array al ref de fixedCards
      fixedCards.value = newFixedCards;
      
      // Obtener el nombre de la carta para mostrar en un mensaje
      const card = cards.value.find(c => c.id === selectedCardId.value);
      const cardName = card ? card.name : 'Carta desconocida';
      const cardRarity = card ? getRarityText(card.rarity) : '';
      
      console.log('Carta añadida a fixedCards:', selectedCardId.value);
      console.log('Nombre de la carta:', cardName);
      console.log('Rareza de la carta:', cardRarity);
      console.log('fixedCards actual:', fixedCards.value);
      
      // Mostrar un mensaje de éxito visible
      const messageContainer = document.createElement('div');
      messageContainer.className = 'alert alert-success mt-2 d-flex align-items-center';
      messageContainer.innerHTML = `
        <i class="fas fa-check-circle me-2 fs-5"></i>
        <div>
          <strong>¡Carta añadida!</strong><br>
          <span>${cardName}</span>
          <span class="badge ${getBadgeClass(card ? card.rarity : '')} ms-1">${cardRarity}</span>
          <div class="mt-1">Total: ${fixedCards.value.length} carta(s) fija(s) en este sobre</div>
        </div>
      `;
      
      // Añadir botón para cerrar la alerta
      const closeButton = document.createElement('button');
      closeButton.type = 'button';
      closeButton.className = 'btn-close ms-auto';
      closeButton.addEventListener('click', () => {
        if (messageContainer.parentNode) {
          messageContainer.parentNode.removeChild(messageContainer);
        }
      });
      messageContainer.appendChild(closeButton);
      
      // Añadir al DOM cerca del botón de añadir carta
      const addCardButton = document.querySelector('#addCardButton');
      if (addCardButton && addCardButton.parentNode) {
        // Eliminar alertas anteriores si existen
        const existingAlerts = addCardButton.parentNode.querySelectorAll('.alert-success');
        existingAlerts.forEach(alert => {
          if (alert.parentNode) {
            alert.parentNode.removeChild(alert);
          }
        });
        
        addCardButton.parentNode.appendChild(messageContainer);
        
        // Eliminar después de 5 segundos
        setTimeout(() => {
          if (messageContainer.parentNode) {
            messageContainer.parentNode.removeChild(messageContainer);
          }
        }, 5000);
      }
      
      // Resetear la selección
      selectedCardId.value = '';
    };
    
    // Obtener clase de badge según rareza
    const getBadgeClass = (rarity) => {
      switch (rarity) {
        case 'common': return 'bg-secondary';
        case 'uncommon': return 'bg-success';
        case 'rare': return 'bg-primary';
        case 'superRare': return 'bg-info';
        case 'ultraRare': return 'bg-warning text-dark';
        case 'legendary': return 'bg-danger';
        default: return 'bg-secondary';
      }
    };
    
    // Eliminar una carta fija
    const removeFixedCard = (index) => {
      if (!Array.isArray(fixedCards.value)) {
        console.error('fixedCards no es un array');
        fixedCards.value = [];
        return;
      }
      
      if (index < 0 || index >= fixedCards.value.length) {
        console.error('Índice fuera de rango:', index, 'longitud:', fixedCards.value.length);
        return;
      }
      
      // Guardar la carta que vamos a eliminar para el log
      const removedCard = fixedCards.value[index];
      
      // Crear un nuevo array sin la carta eliminada
      const newFixedCards = [
        ...fixedCards.value.slice(0, index),
        ...fixedCards.value.slice(index + 1)
      ];
      
      // Asignar el nuevo array al ref de fixedCards
      fixedCards.value = newFixedCards;
      
      console.log('Carta eliminada de fixedCards:', removedCard);
      console.log('fixedCards actual:', fixedCards.value);
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
      
      // Validación explícita de fixedCards para mejor diagnóstico
      console.log('Verificando estado de fixedCards antes de guardar:');
      console.log('- Es un array?', Array.isArray(fixedCards.value));
      console.log('- Longitud:', fixedCards.value ? fixedCards.value.length : 'No disponible');
      console.log('- Contenido:', fixedCards.value);
      
      // Asegurarse de que fixedCards sea un array
      if (!Array.isArray(fixedCards.value)) {
        console.warn('fixedCards no era un array al guardar, inicializando como array vacío');
        fixedCards.value = []; // Inicializar como array vacío si no lo es
      }
      
      isSubmitting.value = true;
      
      try {
        // Preparar los datos para guardar (sin clonar con JSON.stringify ya que pierde propiedades del objeto File)
        const packToSave = {};
        
        // Copiar propiedades básicas del packData
        Object.keys(packData).forEach(key => {
          if (key !== 'imageFile') {
            packToSave[key] = packData[key];
          }
        });
        
        // Convertir probabilidades de porcentaje a decimal (0-1)
        packToSave.probabilities = {};
        rarityList.forEach(rarity => {
          packToSave.probabilities[rarity.value] = probabilities[rarity.value] / 100;
        });
        
        // Manejar cartas fijas - Ahora se guardarán en una subcolección 'packCards'
        // Preparar el array de IDs de cartas para enviar al store
        const fixedCardsArray = Array.isArray(fixedCards.value) ? [...fixedCards.value] : [];
        console.log('Array de cartas fijas para guardar:', fixedCardsArray);
        
        // Agregar información de cuántas cartas se están enviando
        if (fixedCardsArray.length > 0) {
          console.log(`Se enviarán ${fixedCardsArray.length} cartas fijas al store`);
          // Mostrar los nombres de las cartas que se enviarán
          fixedCardsArray.forEach((cardId, index) => {
            const cardName = getCardName(cardId);
            console.log(`- Carta ${index + 1}: ${cardName} (ID: ${cardId})`);
          });
        } else {
          console.log('No hay cartas fijas para enviar al store');
        }
        
        // Asignar el array de cartas fijas
        packToSave.fixedCards = fixedCardsArray;
        
        // Fecha de lanzamiento
        if (releaseDateStr.value) {
          packToSave.releaseDate = new Date(releaseDateStr.value);
        }
        
        // Añadir la imagen si hay una nueva - NO usar JSON.stringify con el objeto File
        if (imageFile.value) {
          packToSave.imageFile = imageFile.value;
          console.log('Asignando imagen:', imageFile.value);
          console.log('Es blob:', imageFile.value instanceof Blob);
          console.log('Es file:', imageFile.value instanceof File);
          console.log('Tipo de archivo:', imageFile.value.type);
        }
        
        console.log('Guardando sobre con datos completos:', {
          ...packToSave,
          imageUrl: packToSave.imageUrl ? '[base64 image]' : null,
          fixedCards: packToSave.fixedCards
        });
        
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
        
        console.log('Sobre guardado con éxito:', savedPack);
        console.log('fixedCards en el sobre guardado:', savedPack?.fixedCards);
        
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
      console.log('PackEditor montado - inicializando componente');
      
      // Asegurar que fixedCards sea un array desde el inicio
      if (!Array.isArray(fixedCards.value)) {
        console.log('fixedCards no es un array en onMounted, inicializando como []');
        fixedCards.value = [];
      } else {
        console.log('fixedCards ya es un array en onMounted, longitud:', fixedCards.value.length);
      }
      
      // Cargar datos
      loadPack();
      loadCards();
      validateProbabilities();
      
      console.log('Inicialización completada');
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
      prepareImageUrl,
      getBadgeClass
    };
  }
};
</script>

<style scoped>
.pack-edit-view {
  @apply min-h-screen bg-gray-50;
}

.pack-preview {
  @apply rounded-lg overflow-hidden;
}

.preview-container img {
  @apply w-full h-64 object-cover rounded-lg;
}

.no-image-container {
  @apply h-64 flex items-center justify-center bg-gray-50 rounded-lg border-2 border-dashed border-gray-300;
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

.form-checkbox {
  @apply h-5 w-5 text-primary focus:ring-primary border-gray-300 rounded;
}
</style>