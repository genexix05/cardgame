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
                    
                    <div class="alert alert-info mb-3">
                      <i class="fas fa-info-circle me-2"></i>
                      <strong>¿Cómo funciona?</strong>
                      <ul class="mb-0 mt-1">
                        <li>Selecciona una carta del menú desplegable y haz clic en el botón "Añadir Carta".</li>
                        <li>Puedes añadir tantas cartas fijas como desees.</li>
                        <li>Las cartas añadidas aparecerán siempre en este sobre cuando un usuario lo abra.</li>
                        <li>Para guardar los cambios, no olvides hacer clic en "Guardar Sobre" al final del formulario.</li>
                      </ul>
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
                        id="addCardButton"
                      >
                        <i class="fas fa-plus-circle me-1"></i>Añadir Carta
                      </button>
                      
                      <div v-if="fixedCards.length === 0" class="text-center py-3 bg-light rounded">
                        <p class="text-muted mb-0">No hay cartas fijas seleccionadas</p>
                        <small class="text-info mt-2 d-block">Al añadir cartas fijas, estas aparecerán siempre en este sobre cuando un usuario lo abra.</small>
                      </div>
                      <div v-else class="table-responsive">
                        <p class="text-info mb-2">
                          <i class="fas fa-info-circle me-1"></i> 
                          Este sobre contendrá {{ fixedCards.length }} carta(s) garantizada(s)
                          <span class="badge bg-success ms-2">{{ fixedCards.length }} carta(s) seleccionada(s)</span>
                        </p>
                        <table class="table table-sm table-striped">
                          <thead class="table-light">
                            <tr>
                              <th>#</th>
                              <th>Nombre</th>
                              <th>Rareza</th>
                              <th>Tipo</th>
                              <th>Acciones</th>
                            </tr>
                          </thead>
                          <tbody>
                            <tr v-for="(cardId, index) in fixedCards" :key="index">
                              <td>{{ index + 1 }}</td>
                              <td>{{ getCardName(cardId) }}</td>
                              <td>{{ getCardRarity(cardId) }}</td>
                              <td>{{ getCardType(cardId) }}</td>
                              <td class="text-end">
                                <button 
                                  type="button" 
                                  class="btn btn-sm btn-outline-danger" 
                                  @click="removeFixedCard(index)"
                                  :title="`Eliminar ${getCardName(cardId)}`"
                                >
                                  <i class="fas fa-times"></i>
                                </button>
                              </td>
                            </tr>
                          </tbody>
                        </table>
                        <small class="text-muted">Nota: Si añades más cartas fijas que el número total de cartas del sobre, todas las cartas fijas serán incluidas.</small>
                        
                        <div class="alert alert-warning mt-3">
                          <i class="fas fa-exclamation-triangle me-2"></i>
                          <strong>¡No olvides guardar!</strong> Haz clic en el botón "Guardar Sobre" al final del formulario para que las cartas fijas se guarden correctamente.
                        </div>
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