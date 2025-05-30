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
              <img :src="prepareImageUrl(packData.imageUrl)" alt="Imagen actual" class="w-full h-full object-cover rounded-lg">
            </div>
            <div v-else class="no-image-container h-full flex items-center justify-center bg-gray-50 rounded-lg border-2 border-dashed border-gray-300">
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
                  <div class="relative flex-1">
                    <input 
                      type="text" 
                      class="form-control pr-10" 
                      v-model="cardSearchQuery"
                      @input="filterCards"
                      @focus="showCardResults = true"
                      placeholder="Buscar carta por nombre..."
                    >
                    <div class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
                      <i class="fas fa-search text-gray-400"></i>
                    </div>
                    
                    <!-- Resultados de búsqueda -->
                    <div v-if="showCardResults && filteredCards.length > 0" 
                         class="absolute z-10 w-full mt-1 bg-white rounded-lg shadow-lg border border-gray-200 max-h-96 overflow-y-auto">
                      <div v-for="card in filteredCards" 
                           :key="card.id"
                           class="px-4 py-2 hover:bg-orange-50 cursor-pointer flex items-center gap-3"
                           @click="selectCard(card)">
                        <!-- Miniatura de la carta -->
                        <div class="w-12 h-16 flex-shrink-0">
                          <div v-if="card.imageUrl" class="w-full h-full rounded-md overflow-hidden shadow-sm">
                            <img 
                              :src="prepareImageUrl(card.imageUrl)" 
                              :alt="card.name"
                              class="w-full h-full object-cover"
                            >
                          </div>
                          <div v-else class="w-full h-full bg-gray-100 rounded-md flex items-center justify-center">
                            <i class="fas fa-image text-gray-400"></i>
                          </div>
                        </div>
                        
                        <!-- Información de la carta -->
                        <div class="flex-grow min-w-0 flex flex-col justify-center h-full">
                          <div class="flex flex-row justify-between items-start">
                            <!-- Nombre a la izquierda -->
                            <span class="font-medium truncate flex-1">{{ card.name }}</span>
                            <!-- Rareza y tipo a la derecha, en columna -->
                            <div class="flex flex-col items-end ml-2">
                              <span :class="['px-2 py-0.5 rounded text-xs whitespace-nowrap mb-1', getBadgeClass(card.rarity)]">
                                {{ getRarityText(card.rarity) }}
                              </span>
                              <span class="text-xs text-gray-500 px-2 py-0.5 bg-gray-100 rounded whitespace-nowrap">
                                {{ getTypeText(card.type) }}
                              </span>
                            </div>
                          </div>
                          <!-- Serie debajo -->
                          <div class="mt-1">
                            <span class="text-xs text-gray-500 px-2 py-0.5 bg-gray-50 rounded">
                              {{ card.series || 'Sin serie' }}
                            </span>
                          </div>
                        </div>
                      </div>
                    </div>
                    
                    <!-- Mensaje cuando no hay resultados -->
                    <div v-if="showCardResults && cardSearchQuery && filteredCards.length === 0" 
                         class="absolute z-10 w-full mt-1 bg-white rounded-lg shadow-lg border border-gray-200 p-4 text-center text-gray-500">
                      No se encontraron cartas que coincidan con "{{ cardSearchQuery }}"
                    </div>
                  </div>
                  
                  <button 
                    type="button" 
                    class="btn-outline-primary" 
                    @click="addFixedCard" 
                    :disabled="!selectedCardId"
                    id="addCardButton"
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
                          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Carta</th>
                          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Rareza</th>
                          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Tipo</th>
                          <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Acciones</th>
                        </tr>
                      </thead>
                      <tbody class="bg-white divide-y divide-gray-200">
                        <tr v-for="(cardId, index) in fixedCards" :key="index" class="hover:bg-gray-50">
                          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{{ index + 1 }}</td>
                          <td class="px-6 py-4 whitespace-nowrap">
                            <div class="flex items-center gap-3">
                              <!-- Miniatura de la carta -->
                              <div class="w-12 h-16 flex-shrink-0">
                                <div v-if="getCardImage(cardId)" class="w-full h-full rounded-md overflow-hidden shadow-sm">
                                  <img 
                                    :src="prepareImageUrl(getCardImage(cardId))" 
                                    :alt="getCardName(cardId)"
                                    class="w-full h-full object-cover"
                                  >
                                </div>
                                <div v-else class="w-full h-full bg-gray-100 rounded-md flex items-center justify-center">
                                  <i class="fas fa-image text-gray-400"></i>
                                </div>
                              </div>
                              <!-- Nombre de la carta -->
                              <div class="text-sm font-medium text-gray-900">
                                {{ getCardName(cardId) }}
                              </div>
                            </div>
                          </td>
                          <td class="px-6 py-4 whitespace-nowrap">
                            <span :class="['px-2 py-1 rounded text-xs font-medium', getBadgeClass(getCardRarityValue(cardId))]">
                              {{ getCardRarity(cardId) }}
                            </span>
                          </td>
                          <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                            {{ getCardType(cardId) }}
                          </td>
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
            
            <!-- Asistente de Auto-Rellenado de Sobre -->
            <div class="space-y-6 border-t pt-6 mt-6">
              <div class="text-center mb-4">
                <h3 class="text-xl font-semibold text-gray-800">🚀 Asistente de Auto-Rellenado</h3>
                <p class="text-sm text-gray-600">
                  Define criterios para generar automáticamente el contenido del sobre.
                </p>
              </div>

              <!-- Sección Sobres Base -->
              <div class="bg-white p-6 rounded-lg shadow-md border border-gray-200">
                <h4 class="text-lg font-medium text-gray-800 mb-3 border-b pb-2">1. Sobres Base (Opcional)</h4>
                <p class="text-xs text-gray-500 mb-2">
                  Usa cartas de sobres existentes como referencia (ej. para evitar duplicados exactos en este sobre).
                </p>
                <select 
                  multiple 
                  class="form-select" 
                  id="basePacks" 
                  v-model="autoFillConfig.basePackIds"
                  :disabled="loadingPacks"
                  size="5"
                >
                  <option v-if="loadingPacks" value="" disabled>Cargando sobres...</option>
                  <option v-else-if="allPacks.length === 0" value="" disabled>No hay sobres para usar como base</option>
                  <option v-for="pack in allPacks.filter(p => !packId || p.id !== packId.value)" :key="pack.id" :value="pack.id">
                    {{ pack.name }}
                  </option>
                </select>
                <p class="text-xs text-gray-500 mt-1">Mantén Ctrl/Cmd y haz clic para seleccionar múltiples sobres.</p>
                <div class="mt-3">
                  <label class="flex items-center cursor-pointer">
                    <input 
                      type="checkbox" 
                      class="form-checkbox h-5 w-5 text-primary focus:ring-primary border-gray-300 rounded"
                      v-model="autoFillConfig.excludeCardsFromBasePacks"
                      :disabled="autoFillConfig.basePackIds.length === 0"
                    >
                    <span class="ml-2 text-sm text-gray-700">
                      Excluir cartas fijas ya presentes en los sobres base seleccionados
                    </span>
                  </label>
                </div>
              </div>

              <!-- Sección Cantidades por Rareza -->
              <div class="bg-white p-6 rounded-lg shadow-md border border-gray-200">
                <h4 class="text-lg font-medium text-gray-800 mb-3 border-b pb-2">2. Cartas por Rareza</h4>
                <div class="grid grid-cols-2 md:grid-cols-3 gap-x-4 gap-y-3">
                  <div v-for="rarity in rarityList" :key="rarity.value">
                    <label :for="'autofill-rarity-' + rarity.value" class="block text-sm font-medium text-gray-700 mb-1">
                      {{ rarity.label }}
                    </label>
                    <input 
                      type="number" 
                      class="form-control text-sm" 
                      :id="'autofill-rarity-' + rarity.value" 
                      v-model.number="autoFillConfig.cardsPerRarity[rarity.value]" 
                      min="0"
                      :max="slotsParaAutoRellenar"
                      :placeholder="slotsParaAutoRellenar > 0 ? Math.floor(slotsParaAutoRellenar / rarityList.length) : 0"
                      :disabled="slotsParaAutoRellenar === 0"
                    >
                  </div>
                </div>
                <div :class="['text-xs mt-3 p-2 rounded-md', totalAutoFillRarityCards === slotsParaAutoRellenar ? 'bg-green-50 text-green-700' : 'bg-yellow-50 text-yellow-700']">
                  Cartas por rareza a añadir: {{ totalAutoFillRarityCards }} / {{ slotsParaAutoRellenar }}.
                  <span v-if="autoFillRarityError" class="block font-medium">{{ autoFillRarityError }}</span>
                </div>
              </div>

              <!-- Sección Cantidades por Tipo -->
              <div class="bg-white p-6 rounded-lg shadow-md border border-gray-200">
                <h4 class="text-lg font-medium text-gray-800 mb-3 border-b pb-2">3. Cartas por Tipo</h4>
                <div class="grid grid-cols-2 md:grid-cols-3 gap-x-4 gap-y-3">
                  <div v-for="type in cardTypeList" :key="type.value">
                    <label :for="'autofill-type-' + type.value" class="block text-sm font-medium text-gray-700 mb-1">
                      {{ type.label }}
                    </label>
                    <input 
                      type="number" 
                      class="form-control text-sm" 
                      :id="'autofill-type-' + type.value" 
                      v-model.number="autoFillConfig.cardsPerType[type.value]" 
                      min="0"
                      :max="slotsParaAutoRellenar"
                      :placeholder="slotsParaAutoRellenar > 0 ? Math.floor(slotsParaAutoRellenar / cardTypeList.length) : 0"
                      :disabled="slotsParaAutoRellenar === 0"
                    >
                  </div>
                </div>
                 <div :class="['text-xs mt-3 p-2 rounded-md', totalAutoFillTypeCards === slotsParaAutoRellenar ? 'bg-green-50 text-green-700' : 'bg-yellow-50 text-yellow-700']">
                  Cartas por tipo a añadir: {{ totalAutoFillTypeCards }} / {{ slotsParaAutoRellenar }}.
                  <span v-if="autoFillTypeError" class="block font-medium">{{ autoFillTypeError }}</span>
                </div>
              </div>
              
              <!-- Botón para ejecutar -->
              <div class="flex justify-center mt-6">
                <button 
                  type="button" 
                  class="btn-primary bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 text-white font-semibold py-3 px-6 rounded-lg shadow-lg transform hover:scale-105 transition-transform duration-150 ease-in-out flex items-center text-base"
                  @click="executeAutoFill"
                  :disabled="isAutoFilling || !!autoFillRarityError || !!autoFillTypeError || slotsParaAutoRellenar === 0"
                >
                  <i class="fas fa-magic mr-2"></i>
                  <span v-if="isAutoFilling" class="animate-spin mr-2">⌛</span>
                  Rellenar Sobre Automáticamente
                </button>
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
import { ref, reactive, computed, onMounted, watch, onUnmounted } from 'vue';
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
    
    // Para la búsqueda de cartas
    const cardSearchQuery = ref('');
    const showCardResults = ref(false);
    const filteredCards = ref([]);
    
    // Calcular el total de probabilidades
    const probabilityTotal = computed(() => {
      return Object.values(probabilities).reduce((sum, val) => sum + (val || 0), 0);
    });
    
    // Cartas disponibles para seleccionar
    const availableCards = computed(() => {
      return cards.value.filter(card => !fixedCards.value.includes(card.id));
    });
    
    // Para el asistente de auto-rellenado
    const allPacks = computed(() => store.state.packs || []);
    const loadingPacks = ref(false);
    const isAutoFilling = ref(false);

    const autoFillConfig = reactive({
      basePackIds: [],
      excludeCardsFromBasePacks: true,
      cardsPerRarity: {},
      cardsPerType: {}
    });

    // Lista de tipos de carta (deberías tener esto globalmente o definirlo aquí)
    const cardTypeList = [
      { value: 'character', label: 'Personaje' },
      { value: 'support', label: 'Soporte' },
      { value: 'equipment', label: 'Equipamiento' },
      { value: 'event', label: 'Evento' },
      // Añade otros tipos si los tienes
    ];

    // Inicializar contadores para autoFillConfig
    rarityList.forEach(r => autoFillConfig.cardsPerRarity[r.value] = 0);
    cardTypeList.forEach(t => autoFillConfig.cardsPerType[t.value] = 0);

    const slotsParaAutoRellenar = computed(() => {
      const remaining = packData.cardCount - (fixedCards.value?.length || 0);
      return Math.max(0, remaining);
    });

    const totalAutoFillRarityCards = computed(() => {
      return Object.values(autoFillConfig.cardsPerRarity).reduce((sum, val) => sum + (Number(val) || 0), 0);
    });
    const totalAutoFillTypeCards = computed(() => {
      return Object.values(autoFillConfig.cardsPerType).reduce((sum, val) => sum + (Number(val) || 0), 0);
    });

    const autoFillRarityError = computed(() => {
      if (slotsParaAutoRellenar.value > 0 && totalAutoFillRarityCards.value !== 0 && totalAutoFillRarityCards.value !== slotsParaAutoRellenar.value) {
        return `La suma (${totalAutoFillRarityCards.value}) debe ser 0 o ${slotsParaAutoRellenar.value} (cartas restantes).`;
      }
      return '';
    });

    const autoFillTypeError = computed(() => {
      if (slotsParaAutoRellenar.value > 0 && totalAutoFillTypeCards.value !== 0 && totalAutoFillTypeCards.value !== slotsParaAutoRellenar.value) {
        return `La suma (${totalAutoFillTypeCards.value}) debe ser 0 o ${slotsParaAutoRellenar.value} (cartas restantes).`;
      }
      return '';
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
    
    // Filtrar cartas según la búsqueda
    const filterCards = () => {
      if (!cardSearchQuery.value) {
        filteredCards.value = availableCards.value.slice(0, 10); // Mostrar solo las primeras 10 cartas si no hay búsqueda
        return;
      }
      
      const query = cardSearchQuery.value.toLowerCase();
      filteredCards.value = availableCards.value
        .filter(card => 
          card.name.toLowerCase().includes(query) ||
          getRarityText(card.rarity).toLowerCase().includes(query) ||
          getTypeText(card.type).toLowerCase().includes(query) ||
          (card.series && card.series.toLowerCase().includes(query))
        )
        .slice(0, 10); // Limitar a 10 resultados
    };
    
    // Seleccionar una carta de los resultados
    const selectCard = (card) => {
      selectedCardId.value = card.id;
      cardSearchQuery.value = card.name;
      showCardResults.value = false;
    };
    
    // Cerrar resultados al hacer clic fuera
    const handleClickOutside = (event) => {
      const searchInput = document.querySelector('.card-search-input');
      if (searchInput && !searchInput.contains(event.target)) {
        showCardResults.value = false;
      }
    };
    
    // Observar cambios en availableCards para actualizar filteredCards
    watch(availableCards, () => {
      filterCards();
    }, { immediate: true });
    
    // Agregar y remover event listener para clicks fuera
    onMounted(() => {
      document.addEventListener('click', handleClickOutside);
      
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
    
    onUnmounted(() => {
      document.removeEventListener('click', handleClickOutside);
    });
    
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
        // Preparar los datos para guardar
        const packToSave = {
          name: packData.name,
          description: packData.description,
          price: packData.price,
          cardCount: packData.cardCount,
          available: packData.available,
          // imageUrl se toma inicialmente de packData
          imageUrl: packData.imageUrl, 
          probabilities: {}, // Se poblará a continuación
          fixedCards: Array.isArray(fixedCards.value) ? [...fixedCards.value] : [],
          releaseDate: releaseDateStr.value ? new Date(releaseDateStr.value) : new Date(),
        };
        
        // Convertir probabilidades de porcentaje a decimal (0-1)
        rarityList.forEach(rarity => {
          packToSave.probabilities[rarity.value] = (probabilities[rarity.value] || 0) / 100;
        });
        
        // Si hay una nueva imagen seleccionada, añadirla al payload 
        // y establecer imageUrl a null. La acción del store es responsable 
        // de subir imageFile y establecer la nueva imageUrl.
        if (imageFile.value) {
          packToSave.imageFile = imageFile.value;
          packToSave.imageUrl = null; 
        }
        
        // Preparamos un objeto para el log, evitando mostrar el objeto File completo
        const loggablePackData = { ...packToSave };
        if (loggablePackData.imageFile) {
          loggablePackData.imageFile = '[File Object]';
        }
        console.log('Guardando sobre con datos para el store:', loggablePackData);
        
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
        // console.log('fixedCards en el sobre guardado:', savedPack?.fixedCards); // Descomentar si es necesario para depuración
        
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
    
    // Obtener información de las cartas
    const getCardName = (cardId) => {
      const card = cards.value.find(c => c.id === cardId);
      return card ? card.name : 'Carta desconocida';
    };
    
    const getCardRarity = (cardId) => {
      const card = cards.value.find(c => c.id === cardId);
      return card ? getRarityText(card.rarity) : '';
    };

    const getCardRarityValue = (cardId) => {
      const card = cards.value.find(c => c.id === cardId);
      return card ? card.rarity : '';
    };
    
    const getCardType = (cardId) => {
      const card = cards.value.find(c => c.id === cardId);
      return card ? getTypeText(card.type) : '';
    };

    const getCardImage = (cardId) => {
      const card = cards.value.find(c => c.id === cardId);
      return card ? card.imageUrl : null;
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
      
      const removedCardId = fixedCards.value[index];
      const newFixedCards = fixedCards.value.filter((_, i) => i !== index);
      fixedCards.value = newFixedCards;
      
      console.log('Carta eliminada de fixedCards:', removedCardId);
      console.log('fixedCards actual:', fixedCards.value);
    };
    
    // Obtener clase de badge según rareza
    const getBadgeClass = (rarity) => {
      switch (rarity) {
        case 'common': return 'bg-gray-200 text-gray-800';
        case 'uncommon': return 'bg-green-100 text-green-800';
        case 'rare': return 'bg-blue-100 text-blue-800';
        case 'superRare': return 'bg-purple-100 text-purple-800';
        case 'ultraRare': return 'bg-yellow-100 text-yellow-800';
        case 'legendary': return 'bg-red-100 text-red-800';
        default: return 'bg-gray-200 text-gray-800';
      }
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
        cardSearchQuery.value = '';
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
      
      // Resetear la selección
      selectedCardId.value = '';
      cardSearchQuery.value = '';
    };
    
    const loadAllPacks = async () => {
      loadingPacks.value = true;
      try {
        // Asume que tienes una acción 'fetchPacks' que obtiene todos los sobres
        if (!store.state.packs || store.state.packs.length === 0) {
           await store.dispatch('fetchPacks');
        }
      } catch (error) {
        console.error('Error al cargar todos los sobres:', error);
        // Aquí podrías mostrar un error al usuario si es necesario
      } finally {
        loadingPacks.value = false;
      }
    };
    
    const executeAutoFill = async () => {
      isAutoFilling.value = true;
      submitError.value = '';
      const logMessages = []; // Para logs detallados en consola
      console.log("Iniciando auto-rellenado v3 con config:", JSON.parse(JSON.stringify(autoFillConfig)), `Slots: ${slotsParaAutoRellenar.value}`);

      if (slotsParaAutoRellenar.value === 0) {
        submitError.value = "No hay slots que rellenar.";
        isAutoFilling.value = false;
        return;
      }

      let availableCards = cards.value.filter(card => !fixedCards.value.includes(card.id));
      if (autoFillConfig.excludeCardsFromBasePacks && autoFillConfig.basePackIds.length > 0) {
        const cardsToExclude = new Set();
        // ... (lógica de exclusión de sobres base) ...
        availableCards = availableCards.filter(card => !cardsToExclude.has(card.id));
      }
      console.log(`Cartas candidatas iniciales: ${availableCards.length}`);

      const addedCardIds = new Set(); // Para evitar duplicados en el mismo proceso de rellenado
      const filledCardsOutput = [];
      
      let currentRarityGoals = { ...autoFillConfig.cardsPerRarity };
      let currentTypeGoals = { ...autoFillConfig.cardsPerType };
      const initialRarityGoals = { ...autoFillConfig.cardsPerRarity }; // Para el informe
      const initialTypeGoals = { ...autoFillConfig.cardsPerType };   // Para el informe

      let slotsFilled = 0;

      // Bucle principal: llenar slots uno por uno
      while (slotsFilled < slotsParaAutoRellenar.value && availableCards.length > 0) {
        let bestCardToPick = null;
        let bestCardScore = -1;
        let bestCardIndex = -1;

        // Evaluar todas las cartas disponibles en cada iteración de slot
        for (let i = 0; i < availableCards.length; i++) {
          const card = availableCards[i];
          if (addedCardIds.has(card.id)) continue; // Ya seleccionada en este rellenado

          let score = 0;
          let typeContributes = false;
          let rarityContributes = false;

          // Obtener de forma segura los valores de los objetivos actuales e iniciales
          const cardType = card.type;
          const cardRarity = card.rarity;

          const currentCardTypeGoal = currentTypeGoals[cardType] || 0;
          const initialCardTypeUserGoal = initialTypeGoals[cardType] || 0;

          const currentCardRarityGoal = currentRarityGoals[cardRarity] || 0;
          const initialCardRarityUserGoal = initialRarityGoals[cardRarity] || 0;

          // Prioridad 1: Contribución al Tipo
          if (totalAutoFillTypeCards.value > 0 && currentCardTypeGoal > 0) {
            score += 100; // Alto peso base por cumplir un tipo necesitado
            // Ponderación por la cantidad absoluta que falta de este tipo
            score += currentCardTypeGoal * 25; // Factor de ponderación para tipo
            typeContributes = true;
          } else if (totalAutoFillTypeCards.value === 0) {
            // No se especificaron tipos, pequeño bonus por llenar el slot
            score += 5;
          }

          // Prioridad 2: Contribución a la Rareza (considerada si ayuda al tipo, o como secundario)
          if (totalAutoFillRarityCards.value > 0) { // El usuario especificó objetivos de rareza
            if (currentCardRarityGoal > 0 && initialCardRarityUserGoal > 0) { // Pidió esta rareza (y no era cero inicialmente) y aún faltan
              score += 20; // Peso base por cumplir una rareza necesitada
              // Ponderación por la cantidad absoluta que falta de esta rareza
              score += currentCardRarityGoal * 15; // Factor de ponderación para rareza (aumentado de 10 a 15)
              rarityContributes = true;
            }
            // Si initialCardRarityUserGoal === 0, no entra aquí, no suma puntos por rareza.
            // Si initialCardRarityUserGoal > 0 pero currentCardRarityGoal === 0 (ya se cumplió), tampoco suma ni resta por rareza aquí.
          } else if (totalAutoFillRarityCards.value === 0) {
            // No se especificaron rarezas, pequeño bonus
            score += 1;
            // En este caso, podríamos considerar que rarityContributes es true para el bonus de doble contribución si también cumple tipo? No, mejor mantenerlo simple.
          }
          
          // Penalización si la rareza fue explícitamente puesta a 0 por el usuario
          if (totalAutoFillRarityCards.value > 0 && initialCardRarityUserGoal === 0 && cardRarity !== '') {
            if (Object.prototype.hasOwnProperty.call(initialRarityGoals, cardRarity)) {
                 score -= 1000; // Penalización muy grande
                 // Asegurarse de que rarityContributes sea false para que no obtenga el bonus de doble contribución
                 rarityContributes = false; 
            }
          }

          // Bonus si la carta contribuye tanto al tipo como a la rareza necesitados
          if (typeContributes && rarityContributes) { // rarityContributes será false si fue penalizada
            score += 30; // Bonus por doble contribución
          }

          // Si no contribuye a NADA necesitado (y se especificaron objetivos para AMBAS categorías), score muy bajo
          if (totalAutoFillTypeCards.value > 0 && !typeContributes && 
              totalAutoFillRarityCards.value > 0 && !rarityContributes) {
             score = 0.1; 
          }

          if (score > bestCardScore) {
            bestCardScore = score;
            bestCardToPick = card;
            bestCardIndex = i;
          }
        }

        if (bestCardToPick) {
          filledCardsOutput.push(bestCardToPick);
          addedCardIds.add(bestCardToPick.id);
          slotsFilled++;

          // Decrementar goals si la carta seleccionada contribuyó
          if (totalAutoFillTypeCards.value > 0 && currentTypeGoals[bestCardToPick.type] > 0) {
            currentTypeGoals[bestCardToPick.type]--;
          }
          if (totalAutoFillRarityCards.value > 0 && currentRarityGoals[bestCardToPick.rarity] > 0) {
            currentRarityGoals[bestCardToPick.rarity]--;
          }
          availableCards.splice(bestCardIndex, 1); // Quitarla de disponibles para la siguiente iteración de slot
        } else {
          break; // No más cartas elegibles o disponibles
        }
      }
      
      // Actualizar fixedCards y generar informe (usando currentRarityGoals y currentTypeGoals para el estado final)
      if (filledCardsOutput.length > 0) {
        const updatedFixedCards = [...fixedCards.value, ...filledCardsOutput.map(c => c.id)];
        fixedCards.value = updatedFixedCards;
      }

      // Generación del informe final (similar a antes, pero usando los currentGoals para el estado final)
      let finalUserMessage = [];
      finalUserMessage.push(`${filledCardsOutput.length} carta(s) fueron seleccionadas por el asistente.`);
      // ... (resto de la lógica del informe usando initialRarityGoals, initialTypeGoals, currentRarityGoals, currentTypeGoals) ...
      // (Asegúrate que esta parte del informe se adapta para usar los nombres de variable correctos)
      
      // Informe de Rarezas
      let rarityReport = [];
      rarityList.forEach(r => {
        const requested = initialRarityGoals[r.value] || 0;
        const fulfilledByAlgo = requested - (currentRarityGoals[r.value] || 0);
        if (requested > 0) {
          if (currentRarityGoals[r.value] > 0 && fulfilledByAlgo < requested ) {
            rarityReport.push(`Rareza ${r.label}: se pidieron ${requested}, se intentaron añadir ${fulfilledByAlgo} (faltaron ${currentRarityGoals[r.value]}).`);
          } else {
            rarityReport.push(`Rareza ${r.label}: se pidieron ${requested}, ¡objetivo de añadir ${fulfilledByAlgo} cumplido!`);
          }
        }
      });
      if(rarityReport.length > 0) finalUserMessage.push("\nDetalle de Cumplimiento (Rarezas):\n" + rarityReport.join("\n"));

      // Informe de Tipos
      let typeReport = [];
      cardTypeList.forEach(t => {
        const requested = initialTypeGoals[t.value] || 0;
        const fulfilledByAlgo = requested - (currentTypeGoals[t.value] || 0);
        if (requested > 0) {
          if (currentTypeGoals[t.value] > 0 && fulfilledByAlgo < requested) {
            typeReport.push(`Tipo ${t.label}: se pidieron ${requested}, se intentaron añadir ${fulfilledByAlgo} (faltaron ${currentTypeGoals[t.value]}).`);
          } else {
            typeReport.push(`Tipo ${t.label}: se pidieron ${requested}, ¡objetivo de añadir ${fulfilledByAlgo} cumplido!`);
          }
        }
      });
      if(typeReport.length > 0) finalUserMessage.push("\nDetalle de Cumplimiento (Tipos):\n" + typeReport.join("\n"));

      if (slotsFilled < slotsParaAutoRellenar.value) {
        finalUserMessage.push(`\n¡Atención! Solo se pudieron llenar ${slotsFilled} de ${slotsParaAutoRellenar.value} slots.`);
      } else {
        finalUserMessage.push("\n¡Éxito! Todos los slots solicitados al asistente se han llenado.");
      }
      
      console.log(logMessages.join('\n')); // Si usas logMessages para debug interno
      // submitError.value = finalUserMessage.join('\n'); // <-- Eliminado para no mostrar el mensaje detallado
      isAutoFilling.value = false;
    };
    
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
      packId,
      
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
      getBadgeClass,
      cardSearchQuery,
      showCardResults,
      filteredCards,
      filterCards,
      selectCard,
      getCardImage,
      getCardRarityValue,
      allPacks,
      loadingPacks,
      autoFillConfig,
      cardTypeList,
      totalAutoFillRarityCards,
      totalAutoFillTypeCards,
      autoFillRarityError,
      autoFillTypeError,
      isAutoFilling,
      executeAutoFill,
      loadAllPacks,
      slotsParaAutoRellenar
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
  @apply w-full h-full object-cover rounded-lg;
}

.no-image-container {
  @apply h-full flex items-center justify-center bg-gray-50 rounded-lg border-2 border-dashed border-gray-300;
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

.form-select[multiple] {
  min-height: 100px; /* Para dar más espacio al selector múltiple */
}
</style>