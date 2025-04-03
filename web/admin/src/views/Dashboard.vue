<template>
  <div class="dashboard p-6">
    <!-- Alerta de error de conexión -->
    <div v-if="error" class="mb-6 bg-red-50 border-l-4 border-red-400 p-4 rounded-md">
      <div class="flex items-center">
        <div class="flex-shrink-0">
          <i class="fas fa-exclamation-circle text-red-400"></i>
        </div>
        <div class="ml-3">
          <p class="text-sm text-red-700">{{ error }}</p>
          <button 
            @click="retryConnection" 
            class="mt-2 px-3 py-1 text-xs font-medium text-red-700 bg-red-100 rounded-md hover:bg-red-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
          >
            Reintentar conexión
          </button>
        </div>
      </div>
    </div>
    <div class="mb-6">
      <h1 class="text-3xl font-bold text-gray-800 mb-2">Dashboard</h1>
      <p class="text-gray-500">Bienvenido al panel de administración</p>
    </div>
    
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      <!-- Tarjetas de estadísticas mejoradas -->
      <div class="card p-6 bg-white rounded-xl shadow-md hover:shadow-lg transition-all duration-300 transform hover:-translate-y-2">
        <div class="flex flex-col items-center">
          <div class="bg-primary/10 p-4 rounded-full mb-4" style="background-color: rgba(79, 70, 229, 0.1);">
            <i class="fas fa-id-card text-2xl" style="color: var(--primary);"></i>
          </div>
          <h5 class="text-lg font-semibold text-gray-700 mb-2">Total de Cartas</h5>
          <p class="text-3xl font-bold" style="color: var(--primary);">{{ statistics.totalCards }}</p>
        </div>
      </div>
      
      <div class="card p-6 bg-white rounded-xl shadow-md hover:shadow-lg transition-all duration-300 transform hover:-translate-y-2">
        <div class="flex flex-col items-center">
          <div class="p-4 rounded-full mb-4" style="background-color: rgba(245, 158, 11, 0.1);">
            <i class="fas fa-box-open text-2xl" style="color: var(--secondary);"></i>
          </div>
          <h5 class="text-lg font-semibold text-gray-700 mb-2">Sobres Disponibles</h5>
          <p class="text-3xl font-bold" style="color: var(--secondary);">{{ statistics.totalPacks }}</p>
        </div>
      </div>
      
      <div class="card p-6 bg-white rounded-xl shadow-md hover:shadow-lg transition-all duration-300 transform hover:-translate-y-2">
        <div class="flex flex-col items-center">
          <div class="p-4 rounded-full mb-4" style="background-color: rgba(16, 185, 129, 0.1);">
            <i class="fas fa-users text-2xl" style="color: var(--success);"></i>
          </div>
          <h5 class="text-lg font-semibold text-gray-700 mb-2">Usuarios Registrados</h5>
          <p class="text-3xl font-bold" style="color: var(--success);">{{ statistics.totalUsers }}</p>
        </div>
      </div>
      
      <div class="card p-6 bg-white rounded-xl shadow-md hover:shadow-lg transition-all duration-300 transform hover:-translate-y-2">
        <div class="flex flex-col items-center">
          <div class="p-4 rounded-full mb-4" style="background-color: rgba(139, 92, 246, 0.1);">
            <i class="fas fa-exchange-alt text-2xl" style="color: #8b5cf6;"></i>
          </div>
          <h5 class="text-lg font-semibold text-gray-700 mb-2">Transacciones</h5>
          <p class="text-3xl font-bold" style="color: #8b5cf6;">{{ statistics.totalTransactions }}</p>
        </div>
      </div>
    </div>
    
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mt-8">
      <!-- Cartas populares -->
      <div class="card bg-white rounded-xl shadow-md overflow-hidden">
        <div class="bg-white px-6 py-4 border-b border-gray-100 flex justify-between items-center">
          <h5 class="font-semibold text-gray-800">Cartas Más Populares</h5>
          <button class="p-2 rounded-full hover:bg-gray-100 text-primary transition-colors duration-200" @click="refreshData">
            <i class="fas fa-sync-alt"></i>
          </button>
        </div>
        <div class="p-6">
          <div v-if="loading" class="flex justify-center items-center py-12">
            <svg class="animate-spin h-8 w-8 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
          </div>
          <div v-else>
            <div v-if="statistics.popularCards.length === 0" class="flex flex-col items-center justify-center py-12">
              <i class="fas fa-chart-bar text-gray-300 text-4xl mb-3"></i>
              <p class="text-gray-500">No hay datos disponibles</p>
            </div>
            <ul v-else class="divide-y divide-gray-100">
              <li v-for="card in statistics.popularCards" :key="card.id" class="py-3 flex justify-between items-center group hover:bg-gray-50 transition-colors duration-150 rounded-md px-2">
                <div class="flex items-center space-x-3">
                  <div class="w-10 h-10 rounded-md overflow-hidden bg-gray-100 flex-shrink-0 border border-gray-200">
                    <img :src="prepareImageUrl(card.imageUrl)" alt="Card image" class="w-full h-full object-cover">
                  </div>
                  <div>
                    <h6 class="font-medium text-gray-800 group-hover:text-primary transition-colors duration-150">{{ card.name }}</h6>
                    <span class="text-xs text-gray-500">{{ card.rarity }} - {{ card.type }}</span>
                  </div>
                </div>
                <span class="px-2.5 py-1 bg-primary/10 text-primary rounded-full text-xs font-medium">{{ card.count }}</span>
              </li>
            </ul>
          </div>
        </div>
      </div>
      
      <!-- Últimas aperturas de sobres -->
      <div class="card bg-white rounded-xl shadow-md overflow-hidden">
        <div class="bg-white px-6 py-4 border-b border-gray-100">
          <h5 class="font-semibold text-gray-800">Aperturas Recientes</h5>
        </div>
        <div class="p-6">
          <div v-if="loading" class="flex justify-center items-center py-12">
            <svg class="animate-spin h-8 w-8 text-primary" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
          </div>
          <div v-else>
            <div v-if="statistics.packOpenings.length === 0" class="flex flex-col items-center justify-center py-12">
              <i class="fas fa-box-open text-gray-300 text-4xl mb-3"></i>
              <p class="text-gray-500">No hay datos disponibles</p>
            </div>
            <div v-else class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead>
                  <tr>
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Usuario</th>
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Sobre</th>
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Cartas</th>
                    <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Fecha</th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-100">
                  <tr v-for="(opening, index) in statistics.packOpenings" :key="index" class="hover:bg-gray-50 transition-colors duration-150">
                    <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-700">{{ opening.userId }}</td>
                    <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-700">{{ opening.packName }}</td>
                    <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-700">{{ opening.cards ? opening.cards.length : 0 }}</td>
                    <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-500">{{ formatDate(opening.timestamp) }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <div class="mt-8">
      <!-- Accesos rápidos -->
      <div class="card bg-white rounded-xl shadow-md overflow-hidden">
        <div class="bg-white px-6 py-4 border-b border-gray-100">
          <h5 class="font-semibold text-gray-800">Acciones Rápidas</h5>
        </div>
        <div class="p-6">
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <router-link to="/cards/new" class="btn-primary flex items-center justify-center py-3 px-4 rounded-lg text-white font-medium transition-transform duration-200 transform hover:scale-105">
              <i class="fas fa-plus-circle mr-2"></i>Nueva Carta
            </router-link>
            <router-link to="/packs/new" class="bg-secondary hover:bg-secondary-light flex items-center justify-center py-3 px-4 rounded-lg text-white font-medium transition-transform duration-200 transform hover:scale-105">
              <i class="fas fa-plus-circle mr-2"></i>Nuevo Sobre
            </router-link>
            <router-link to="/cards" class="bg-white border border-gray-300 hover:bg-gray-50 flex items-center justify-center py-3 px-4 rounded-lg text-gray-700 font-medium transition-transform duration-200 transform hover:scale-105">
              <i class="fas fa-list mr-2 text-gray-600"></i>Ver Todas las Cartas
            </router-link>
            <router-link to="/users" class="bg-white border border-gray-300 hover:bg-gray-50 flex items-center justify-center py-3 px-4 rounded-lg text-gray-700 font-medium transition-transform duration-200 transform hover:scale-105">
              <i class="fas fa-users mr-2 text-gray-600"></i>Gestionar Usuarios
            </router-link>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, computed, onUnmounted } from 'vue';
import { useStore } from 'vuex';
import { prepareImageUrl } from '../utils/storage';

export default {
  name: 'DashboardView',
  setup() {
    const store = useStore();
    const loading = computed(() => store.state.loading);
    const error = computed(() => store.state.error);
    const statistics = computed(() => store.state.statistics);
    const connectionStatus = ref(navigator.onLine);
    const offlineMode = ref(false);
    
    // Monitorear el estado de la conexión
    const updateConnectionStatus = () => {
      connectionStatus.value = navigator.onLine;
      if (!connectionStatus.value) {
        offlineMode.value = true;
        store.commit('SET_ERROR', 'No hay conexión a Internet. La aplicación está funcionando en modo offline con datos limitados.');
      } else if (offlineMode.value) {
        // Si recuperamos la conexión después de estar offline
        store.commit('SET_ERROR', 'Restableciendo conexión con Firestore...');
        
        // Aumentar el tiempo de espera para dar tiempo a que la conexión se estabilice
        setTimeout(() => {
          offlineMode.value = false;
          refreshData(); // Intentar cargar datos frescos
        }, 3000);
      }
    };
    
    // Función para reintentar la conexión con retraso progresivo
    let retryCount = 0;
    const maxRetries = 5;
    const retryConnection = () => {
      if (navigator.onLine) {
        const retryDelay = Math.min(1000 * Math.pow(1.5, retryCount), 30000); // Backoff exponencial, máximo 30 segundos
        retryCount++;
        
        if (retryCount <= maxRetries) {
          store.commit('SET_ERROR', `Intentando reconectar a Firestore (intento ${retryCount}/${maxRetries})...`);
          setTimeout(() => {
            refreshData().then(success => {
              if (success) {
                retryCount = 0; // Reiniciar contador si tuvimos éxito
              }
            });
          }, retryDelay);
        } else {
          store.commit('SET_ERROR', 'No se pudo establecer conexión con Firestore después de varios intentos. Los datos mostrados pueden estar desactualizados.');
          // Reiniciar contador para el próximo intento manual
          retryCount = 0;
        }
      } else {
        store.commit('SET_ERROR', 'No hay conexión a Internet. Por favor, verifica tu conexión e intenta de nuevo.');
      }
    };
    
    const refreshData = async () => {
      try {
        await store.dispatch('fetchStatistics');
        // Si la carga fue exitosa, limpiar cualquier mensaje de error
        if (error.value && error.value.includes('Intentando reconectar')) {
          store.commit('SET_ERROR', null);
        }
      } catch (error) {
        console.error('Error al cargar estadísticas:', error);
        // Mostrar un mensaje de error más específico
        let errorMessage = 'Error al cargar estadísticas. ';
        
        if (error.code === 'unavailable' || error.code === 'resource-exhausted') {
          errorMessage += 'El servidor de Firestore no está disponible en este momento. ';
        } else if (error.code === 'permission-denied') {
          errorMessage += 'No tienes permisos para acceder a estos datos. ';
        } else if (error.code === 'deadline-exceeded') {
          errorMessage += 'La operación tardó demasiado tiempo. ';
        }
        
        errorMessage += 'Se mostrarán datos en caché si están disponibles.';
        store.commit('SET_ERROR', errorMessage);
      }
    };
    
    // Esta función ya está definida arriba, eliminamos la duplicada
    
    const formatDate = (timestamp) => {
      if (!timestamp) return 'N/A';
      
      const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
      return new Intl.DateTimeFormat('es-ES', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      }).format(date);
    };
    
    onMounted(() => {
      updateConnectionStatus(); // Verificar estado inicial de conexión
      refreshData();
      
      // Configurar un intervalo para verificar la conexión periódicamente
      const connectionCheckInterval = setInterval(() => {
        if (navigator.onLine && error.value) {
          // Si estamos online pero hay un error, intentar reconectar
          retryConnection();
        }
      }, 30000); // Verificar cada 30 segundos
      
      // Limpiar el intervalo al desmontar
      onUnmounted(() => {
        clearInterval(connectionCheckInterval);
      });
    });
    
    // Limpiar event listeners al desmontar el componente
    onUnmounted(() => {
      window.removeEventListener('online', updateConnectionStatus);
      window.removeEventListener('offline', updateConnectionStatus);
    });
    
    return {
      loading,
      error,
      statistics,
      connectionStatus,
      offlineMode,
      refreshData,
      retryConnection,
      formatDate,
      prepareImageUrl
    };
  }
};
</script>

<style scoped>
/* Los estilos ahora se manejan principalmente con clases de Tailwind */
/* Estilos adicionales específicos */
.dashboard {
  @apply bg-gray-50;
}

/* Animaciones para las tarjetas */
@keyframes pulse-soft {
  0%, 100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.02);
  }
}

.card:hover {
  animation: pulse-soft 2s infinite;
}
</style>