<template>
  <div class="users-view">
    <!-- Encabezado -->
    <div class="flex items-center justify-between mb-8">
      <div>
        <h1 class="text-2xl font-bold text-gray-800">Gestión de Usuarios</h1>
        <p class="text-gray-600 mt-1">Administra todos los usuarios del sistema</p>
      </div>
      <button class="btn-primary" @click="openCreateUserModal">
        <i class="fas fa-user-plus mr-2"></i>Crear Usuario
      </button>
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
              placeholder="Nombre, email o ID..." 
                v-model="searchQuery"
                @input="debounceSearch"
              >
              <button 
                v-if="searchQuery"
              class="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-500"
              @click="clearSearch"
              >
                <i class="fas fa-times"></i>
              </button>
            </div>
          </div>
          
        <div>
          <label for="roleFilter" class="block text-sm font-medium text-gray-700 mb-1">Rol</label>
          <select class="form-select" id="roleFilter" v-model="roleFilter">
              <option value="">Todos los roles</option>
              <option value="user">Usuario normal</option>
              <option value="premium">Usuario premium</option>
              <option value="admin">Administrador</option>
            </select>
          </div>
          
        <div>
          <label for="sortBy" class="block text-sm font-medium text-gray-700 mb-1">Ordenar por</label>
          <select class="form-select" id="sortBy" v-model="sortBy">
              <option value="registrationDate_desc">Registro (más reciente)</option>
              <option value="registrationDate_asc">Registro (más antiguo)</option>
              <option value="lastLogin_desc">Último acceso (más reciente)</option>
              <option value="lastLogin_asc">Último acceso (más antiguo)</option>
              <option value="displayName_asc">Nombre (A-Z)</option>
              <option value="displayName_desc">Nombre (Z-A)</option>
              <option value="cardsCount_desc">Nº cartas (mayor)</option>
              <option value="cardsCount_asc">Nº cartas (menor)</option>
            </select>
          </div>
        </div>
      </div>

    <!-- Lista de usuarios -->
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
          <button class="btn-outline-danger" @click="loadUsers">Reintentar</button>
        </div>
      </div>
    </div>
    
    <div v-else>
      <div v-if="!users.length" class="text-center py-12">
        <i class="fas fa-users-slash text-gray-400 text-4xl mb-4"></i>
        <p class="text-gray-500">
          <span v-if="searchQuery || roleFilter">
            No se encontraron usuarios con los filtros aplicados
          </span>
          <span v-else>
            No hay usuarios registrados en el sistema
          </span>
        </p>
      </div>
      
      <div v-else class="bg-white rounded-lg shadow-sm overflow-hidden">
        <div class="overflow-x-auto">
          <table class="w-full">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Usuario</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Rol</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Registro</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Último acceso</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Colección</th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Estado</th>
                <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Acciones</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
              <tr v-for="user in users" :key="user.id" class="hover:bg-gray-50">
                <td class="px-6 py-4">
                  <div class="flex items-center">
                    <div class="flex-shrink-0 h-10 w-10">
                      <img 
                        :src="user.photoURL || '/assets/default-avatar.png'" 
                        :alt="user.displayName || 'Usuario'" 
                        class="h-10 w-10 rounded-full"
                      >
                    </div>
                    <div class="ml-4">
                      <div class="text-sm font-medium text-gray-900">{{ user.displayName || 'Usuario sin nombre' }}</div>
                      <div class="text-sm text-gray-500">ID: {{ user.id }}</div>
                  </div>
                </div>
              </td>
              
                <td class="px-6 py-4">
                  <div class="text-sm text-gray-900">{{ user.email }}</div>
                  <div class="text-xs" :class="user.emailVerified ? 'text-green-600' : 'text-yellow-600'">
                    <i :class="user.emailVerified ? 'fas fa-check-circle' : 'fas fa-exclamation-circle'" class="mr-1"></i>
                    {{ user.emailVerified ? 'Verificado' : 'Sin verificar' }}
                  </div>
              </td>
              
                <td class="px-6 py-4">
                  <span class="badge" :class="getRoleBadgeClass(user.role)">
                  {{ getRoleName(user.role) }}
                </span>
              </td>
              
                <td class="px-6 py-4">
                  <div class="text-sm text-gray-900">{{ formatDate(user.registrationDate) }}</div>
                  <div class="text-xs text-gray-500">{{ formatTimeAgo(user.registrationDate) }}</div>
              </td>
              
                <td class="px-6 py-4">
                  <div class="text-sm text-gray-900">{{ formatDate(user.lastLogin) }}</div>
                  <div class="text-xs text-gray-500">{{ formatTimeAgo(user.lastLogin) }}</div>
              </td>
              
                <td class="px-6 py-4">
                  <div class="flex items-center">
                    <i class="fas fa-layer-group text-gray-400 mr-2"></i>
                  <div>
                      <div class="text-sm font-medium text-gray-900">{{ user.stats?.cardsCount || 0 }} cartas</div>
                      <div class="text-xs text-gray-500">{{ user.stats?.packsOpened || 0 }} sobres</div>
                  </div>
                </div>
              </td>
              
                <td class="px-6 py-4">
                  <span class="badge" :class="user.disabled ? 'bg-red-100 text-red-800' : 'bg-green-100 text-green-800'">
                  {{ user.disabled ? 'Bloqueado' : 'Activo' }}
                </span>
              </td>
              
                <td class="px-6 py-4 text-right">
                  <div class="flex justify-end space-x-2">
                    <button 
                      class="btn-action btn-view"
                      @click="viewUserDetails(user.id)"
                      title="Ver detalles"
                    >
                      <i class="fas fa-eye"></i>
                    </button>
                    
                    <button 
                      class="btn-action btn-edit"
                      @click="editUserRole(user)"
                      title="Cambiar rol"
                    >
                      <i class="fas fa-user-tag"></i>
                    </button>
                    
                    <button 
                      class="btn-action"
                      :class="user.disabled ? 'btn-success' : 'btn-danger'"
                      @click="toggleUserStatus(user)"
                      :title="user.disabled ? 'Activar cuenta' : 'Bloquear cuenta'"
                    >
                      <i :class="user.disabled ? 'fas fa-user-check' : 'fas fa-user-slash'"></i>
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- Paginación -->
    <div v-if="totalPages > 1" class="mt-6">
      <div class="flex items-center justify-between">
        <div class="text-sm text-gray-500">
          Mostrando {{ (currentPage - 1) * pageSize + 1 }} - {{ Math.min(currentPage * pageSize, totalUsers) }} de {{ totalUsers }} usuarios
        </div>
        
        <div class="flex space-x-1">
          <button 
            class="btn-secondary btn-sm"
            :disabled="currentPage === 1"
            @click="changePage(currentPage - 1)"
          >
            <i class="fas fa-chevron-left"></i>
          </button>
          
          <button 
            v-for="page in paginationNumbers" 
            :key="page"
            class="btn-sm"
            :class="currentPage === page ? 'btn-primary' : 'btn-secondary'"
            @click="changePage(page)"
          >
            {{ page }}
          </button>
          
          <button 
            class="btn-secondary btn-sm"
            :disabled="currentPage === totalPages"
            @click="changePage(currentPage + 1)"
          >
            <i class="fas fa-chevron-right"></i>
          </button>
      </div>
      </div>
    </div>

    <!-- Modal de cambio de rol -->
    <div v-if="showRoleModal" class="modal">
        <div class="modal-content">
          <div class="modal-header">
          <h3 class="text-lg font-semibold text-gray-800">Cambiar rol de usuario</h3>
          <button class="modal-close" @click="showRoleModal = false">
            <i class="fas fa-times"></i>
          </button>
          </div>
        
        <div class="modal-body">
          <p class="text-gray-600">Estás cambiando el rol del usuario <strong>{{ selectedUser?.displayName || 'Usuario' }}</strong>.</p>
          <div class="mt-4">
            <label class="block text-sm font-medium text-gray-700 mb-1">Nuevo rol</label>
            <select class="form-select" v-model="newRole">
                <option value="user">Usuario normal</option>
                <option value="premium">Usuario premium</option>
                <option value="admin">Administrador</option>
              </select>
            </div>
            </div>
        
          <div class="modal-footer">
          <button class="btn-secondary" @click="showRoleModal = false">Cancelar</button>
          <button class="btn-primary" @click="updateUserRole" :disabled="isUpdatingRole">
            <span v-if="isUpdatingRole" class="animate-spin mr-2">⌛</span>
              Guardar cambios
            </button>
        </div>
      </div>
    </div>

    <!-- Modal de detalles de usuario -->
    <div v-if="showUserDetailsModal" class="modal">
      <div class="modal-content max-w-3xl">
          <div class="modal-header">
          <h3 class="text-lg font-semibold text-gray-800">
            Detalles del usuario
            <span v-if="userDetailsLoading" class="ml-2 text-sm text-gray-500">(Cargando...)</span>
          </h3>
          <button class="modal-close" @click="showUserDetailsModal = false">
            <i class="fas fa-times"></i>
          </button>
          </div>
        
          <div class="modal-body">
          <div v-if="error" class="bg-red-50 text-red-600 p-4 rounded-lg mb-4">
            {{ error }}
              </div>

          <div v-if="userDetailsLoading" class="flex justify-center py-8">
            <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
            </div>
            
          <div v-else-if="userDetails" class="space-y-6">
              <!-- Información básica -->
            <div class="bg-gray-50 rounded-lg p-4">
              <div class="flex items-center space-x-4">
                  <img 
                    :src="userDetails.photoURL || '/assets/default-avatar.png'" 
                    :alt="userDetails.displayName || 'Usuario'" 
                  class="h-16 w-16 rounded-full object-cover"
                  @error="$event.target.src = '/assets/default-avatar.png'"
                >
                <div>
                  <h4 class="text-lg font-semibold text-gray-800">
                    {{ userDetails.displayName || 'Usuario sin nombre' }}
                  </h4>
                  <p class="text-gray-600">{{ userDetails.email }}</p>
                  <div class="mt-2 flex flex-wrap gap-2">
                    <span class="badge" :class="getRoleBadgeClass(userDetails.role)">
                      {{ getRoleName(userDetails.role || 'user') }}
                    </span>
                    <span class="badge" :class="userDetails.disabled ? 'bg-red-100 text-red-800' : 'bg-green-100 text-green-800'">
                      {{ userDetails.disabled ? 'Bloqueado' : 'Activo' }}
                    </span>
                  </div>
                    </div>
                  </div>
                </div>
                
            <!-- Estadísticas -->
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div class="bg-white rounded-lg p-4 shadow-sm">
                <h5 class="text-sm font-medium text-gray-500">Cartas en colección</h5>
                <p class="text-2xl font-semibold text-gray-800">{{ userDetails.stats?.cardsCount || 0 }}</p>
                    </div>
              <div class="bg-white rounded-lg p-4 shadow-sm">
                <h5 class="text-sm font-medium text-gray-500">Sobres abiertos</h5>
                <p class="text-2xl font-semibold text-gray-800">{{ userDetails.stats?.packsOpened || 0 }}</p>
                            </div>
              <div class="bg-white rounded-lg p-4 shadow-sm">
                <h5 class="text-sm font-medium text-gray-500">Último acceso</h5>
                <p class="text-sm text-gray-800">
                  {{ userDetails.lastLogin ? formatDate(userDetails.lastLogin, true) : 'Nunca' }}
                </p>
                </div>
              </div>
              
            <!-- Colección de cartas -->
            <div v-if="userCards.length > 0" class="border rounded-lg overflow-hidden">
              <div class="bg-gray-50 px-4 py-2 border-b">
                <h4 class="font-medium text-gray-700">Cartas en colección</h4>
                  </div>
              <div class="p-4 grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
                <div v-for="card in userCards" :key="card.id" class="bg-white rounded shadow-sm p-2">
                  <img 
                    :src="card.imageUrl || '/assets/card-placeholder.png'" 
                    :alt="card.name"
                    class="w-full h-32 object-cover rounded"
                    @error="$event.target.src = '/assets/card-placeholder.png'"
                  >
                  <div class="mt-2">
                    <p class="text-sm font-medium text-gray-800">{{ card.name }}</p>
                    <p class="text-xs text-gray-500">{{ getRarityName(card.rarity) }}</p>
                        </div>
                    </div>
                  </div>
                </div>
                
            <!-- Actividad reciente -->
            <div>
              <h4 class="text-lg font-semibold text-gray-800 mb-4">Actividad reciente</h4>
              <div class="space-y-4">
                <div v-for="activity in userActivity" :key="activity.id" 
                     class="flex items-start space-x-3 p-3 bg-white rounded-lg shadow-sm">
                  <div class="flex-shrink-0 w-8 h-8 flex items-center justify-center rounded-full bg-gray-100">
                    <i :class="getActivityIcon(activity.type)" class="text-lg text-gray-600"></i>
                  </div>
                  <div class="flex-1">
                    <p class="text-sm text-gray-800">{{ getActivityDescription(activity) }}</p>
                    <p class="text-xs text-gray-500">{{ formatTimeAgo(activity.timestamp) }}</p>
                      </div>
                      </div>
                <div v-if="!userActivity.length" class="text-center py-4 text-gray-500">
                  No hay actividad reciente
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
          <div class="modal-footer">
          <button class="btn-secondary" @click="showUserDetailsModal = false">Cerrar</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';

export default {
  name: 'UsersView',
  setup() {
    const store = useStore();
    
    // Estado
    const loading = ref(false);
    const error = ref(null);
    const users = ref([]);
    const totalUsers = ref(0);
    const searchQuery = ref('');
    const roleFilter = ref('');
    const sortBy = ref('registrationDate_desc');
    const currentPage = ref(1);
    const pageSize = ref(10);
    
    // Modal de rol
    const showRoleModal = ref(false);
    const selectedUser = ref(null);
    const newRole = ref('user');
    const isUpdatingRole = ref(false);
    
    // Modal de detalles
    const showUserDetailsModal = ref(false);
    const userDetails = ref(null);
    const userDetailsLoading = ref(false);
    const userCards = ref([]);
    const userActivity = ref([]);
    const notesUpdateLoading = ref(false);
    
    // Temporizador para debounce
    let searchTimeout = null;
    
    // Paginación
    const totalPages = computed(() => Math.ceil(totalUsers.value / pageSize.value));
    
    const paginationNumbers = computed(() => {
      const pages = [];
      const maxVisiblePages = 5;
      
      if (totalPages.value <= maxVisiblePages) {
        // Mostrar todas las páginas si hay menos que el máximo
        for (let i = 1; i <= totalPages.value; i++) {
          pages.push(i);
        }
      } else {
        // Algoritmo para mostrar páginas actuales y cercanas
        let startPage = Math.max(1, currentPage.value - Math.floor(maxVisiblePages / 2));
        let endPage = startPage + maxVisiblePages - 1;
        
        if (endPage > totalPages.value) {
          endPage = totalPages.value;
          startPage = Math.max(1, endPage - maxVisiblePages + 1);
        }
        
        for (let i = startPage; i <= endPage; i++) {
          pages.push(i);
        }
      }
      
      return pages;
    });
    
    // Cargar usuarios
    const loadUsers = async () => {
      loading.value = true;
      error.value = null;
      
      try {
        await store.dispatch('users/fetchUsers');
        users.value = store.getters['users/getUsers'];
        totalUsers.value = users.value.length;
      } catch (err) {
        console.error('Error al cargar usuarios:', err);
        error.value = store.getters['users/getError'] || 'Error al cargar la lista de usuarios';
      } finally {
        loading.value = false;
      }
    };
    
    // Búsqueda con debounce
    const debounceSearch = () => {
      if (searchTimeout) {
        clearTimeout(searchTimeout);
      }
      
      searchTimeout = setTimeout(() => {
        currentPage.value = 1; // Resetear a la primera página
        loadUsers();
      }, 300);
    };
    
    const clearSearch = () => {
      searchQuery.value = '';
      loadUsers();
    };
    
    // Cambiar de página
    const changePage = (page) => {
      if (page < 1 || page > totalPages.value) return;
      currentPage.value = page;
      loadUsers();
    };
    
    // Exportar usuarios
    const exportUsers = async () => {
      try {
        // Solicitar al servidor un CSV con todos los usuarios
        await store.dispatch('exportUsers');
      } catch (err) {
        console.error('Error al exportar usuarios:', err);
        store.commit('SET_ERROR', 'Error al exportar la lista de usuarios');
      }
    };
    
    // Abrir modal de cambio de rol
    const editUserRole = (user) => {
      selectedUser.value = user;
      newRole.value = user.role || 'user';
      showRoleModal.value = true;
    };
    
    // Guardar cambio de rol
    const updateUserRole = async () => {
      if (!selectedUser.value) return;
      
      isUpdatingRole.value = true;
      
      try {
        await store.dispatch('updateUserRole', {
          userId: selectedUser.value.id,
          role: newRole.value
        });
        
        // Actualizar en la lista local
        const userIndex = users.value.findIndex(u => u.id === selectedUser.value.id);
        if (userIndex >= 0) {
          users.value[userIndex].role = newRole.value;
        }
        
        showRoleModal.value = false;
      } catch (err) {
        console.error('Error al cambiar el rol del usuario:', err);
        store.commit('SET_ERROR', 'Error al actualizar el rol del usuario');
      } finally {
        isUpdatingRole.value = false;
      }
    };
    
    // Activar/desactivar usuario
    const toggleUserStatus = async (user) => {
      if (!confirm(`¿Estás seguro de que quieres ${user.disabled ? 'activar' : 'bloquear'} la cuenta de ${user.displayName || 'este usuario'}?`)) {
        return;
      }
      
      try {
        await store.dispatch('toggleUserStatus', {
          userId: user.id,
          disabled: !user.disabled
        });
        
        // Actualizar en la lista local
        const userIndex = users.value.findIndex(u => u.id === user.id);
        if (userIndex >= 0) {
          users.value[userIndex].disabled = !user.disabled;
        }
      } catch (err) {
        console.error('Error al cambiar el estado del usuario:', err);
        store.commit('SET_ERROR', `Error al ${user.disabled ? 'activar' : 'bloquear'} al usuario`);
      }
    };
    
    // Ver detalles de usuario
    const viewUserDetails = async (userId) => {
      userDetailsLoading.value = true;
      showUserDetailsModal.value = true;
      
      try {
        // Cargar detalles del usuario
        const user = await store.dispatch('users/fetchUserDetails', userId);
        userDetails.value = user;
        
        // Cargar cartas y actividad en paralelo
        const [cards, activity] = await Promise.all([
          store.dispatch('users/fetchUserCards', userId),
          store.dispatch('users/fetchUserActivity', userId)
        ]);
        
        userCards.value = cards;
        userActivity.value = activity;
        
        // Actualizar estadísticas si es necesario
        if (cards && !userDetails.value.stats?.cardsCount) {
          userDetails.value = {
            ...userDetails.value,
            stats: {
              ...userDetails.value.stats,
              cardsCount: cards.length
            }
          };
        }
      } catch (err) {
        console.error('Error al cargar detalles del usuario:', err);
        error.value = store.getters['users/getError'] || 'Error al cargar los detalles del usuario';
      } finally {
        userDetailsLoading.value = false;
      }
    };
    
    // Guardar notas de administrador
    const saveAdminNotes = async () => {
      if (!userDetails.value) return;
      
      notesUpdateLoading.value = true;
      
      try {
        await store.dispatch('updateUserNotes', {
          userId: userDetails.value.id,
          notes: userDetails.value.adminNotes
        });
        
        store.commit('SET_SUCCESS', 'Notas guardadas correctamente');
      } catch (err) {
        console.error('Error al guardar notas:', err);
        store.commit('SET_ERROR', 'Error al guardar las notas del usuario');
      } finally {
        notesUpdateLoading.value = false;
      }
    };
    
    // Helpers para formateo
    const formatDate = (timestamp, includeTime = false) => {
      if (!timestamp) return 'N/A';
      
      const date = timestamp instanceof Date ? timestamp : new Date(timestamp);
      
      if (isNaN(date.getTime())) return 'Fecha inválida';
      
      const options = {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
      };
      
      if (includeTime) {
        options.hour = '2-digit';
        options.minute = '2-digit';
      }
      
      return date.toLocaleDateString('es-ES', options);
    };
    
    const formatTimeAgo = (timestamp) => {
      if (!timestamp) return '';
      
      const date = timestamp instanceof Date ? timestamp : new Date(timestamp);
      
      if (isNaN(date.getTime())) return '';
      
      const now = new Date();
      const diffTime = Math.abs(now - date);
      const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
      const diffHours = Math.floor(diffTime / (1000 * 60 * 60));
      const diffMinutes = Math.floor(diffTime / (1000 * 60));
      
      if (diffDays > 30) {
        const diffMonths = Math.floor(diffDays / 30);
        return `hace ${diffMonths} ${diffMonths === 1 ? 'mes' : 'meses'}`;
      } else if (diffDays > 0) {
        return `hace ${diffDays} ${diffDays === 1 ? 'día' : 'días'}`;
      } else if (diffHours > 0) {
        return `hace ${diffHours} ${diffHours === 1 ? 'hora' : 'horas'}`;
      } else if (diffMinutes > 0) {
        return `hace ${diffMinutes} ${diffMinutes === 1 ? 'minuto' : 'minutos'}`;
      } else {
        return 'hace un momento';
      }
    };
    
    const getRoleName = (role) => {
      switch (role) {
        case 'admin': return 'Administrador';
        case 'premium': return 'Premium';
        case 'user': return 'Usuario';
        default: return 'Usuario';
      }
    };
    
    const getRarityName = (rarity) => {
      switch (rarity) {
        case 'common': return 'Común';
        case 'uncommon': return 'Poco común';
        case 'rare': return 'Rara';
        case 'superRare': return 'Super rara';
        case 'ultraRare': return 'Ultra rara';
        case 'legendary': return 'Legendaria';
        default: return rarity;
      }
    };
    
    const getActivityIcon = (type) => {
      switch (type) {
        case 'login': return 'fas fa-sign-in-alt text-primary';
        case 'purchase': return 'fas fa-shopping-cart text-success';
        case 'pack_open': return 'fas fa-box-open text-warning';
        case 'level_up': return 'fas fa-arrow-up text-info';
        case 'achievement': return 'fas fa-trophy text-warning';
        default: return 'fas fa-circle text-secondary';
      }
    };
    
    const getActivityDescription = (activity) => {
      switch (activity.type) {
        case 'login':
          return `Inició sesión ${activity.data?.device ? `desde ${activity.data.device}` : ''}`;
        case 'purchase':
          return `Compró ${activity.data?.packName || 'un sobre'} por ${activity.data?.price || 'N/A'} monedas`;
        case 'pack_open':
          return `Abrió un sobre ${activity.data?.packName || ''} y obtuvo ${activity.data?.cardCount || 'N/A'} cartas`;
        case 'level_up':
          return `Subió al nivel ${activity.data?.level || 'N/A'}`;
        case 'achievement':
          return `Desbloqueó el logro "${activity.data?.name || 'N/A'}"`;
        default:
          return activity.description || 'Actividad desconocida';
      }
    };
    
    // Inicializar
    onMounted(() => {
      loadUsers();
    });
    
    // Observar cambios en filtros
    watch([roleFilter, sortBy], () => {
      currentPage.value = 1; // Resetear a la primera página
      loadUsers();
    });
    
    return {
      // Estado
      loading,
      error,
      users,
      totalUsers,
      searchQuery,
      roleFilter,
      sortBy,
      currentPage,
      pageSize,
      totalPages,
      paginationNumbers,
      
      // Modales
      showRoleModal,
      showUserDetailsModal,
      
      // Datos de modales
      selectedUser,
      newRole,
      isUpdatingRole,
      userDetails,
      userDetailsLoading,
      userCards,
      userActivity,
      notesUpdateLoading,
      
      // Métodos
      loadUsers,
      debounceSearch,
      clearSearch,
      changePage,
      exportUsers,
      editUserRole,
      updateUserRole,
      toggleUserStatus,
      viewUserDetails,
      saveAdminNotes,
      
      // Helpers
      formatDate,
      formatTimeAgo,
      getRoleName,
      getRarityName,
      getActivityIcon,
      getActivityDescription,
      getRoleBadgeClass: (role) => {
        switch (role) {
          case 'admin': return 'role-admin';
          case 'premium': return 'role-premium';
          case 'user': return 'role-user';
          default: return 'role-user';
        }
      }
    };
  }
};
</script>

<style scoped>
.users-view {
  @apply p-6;
}

.badge {
  @apply px-2 py-1 text-xs font-semibold rounded-full;
}

.modal {
  @apply fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4;
}

.modal-content {
  @apply bg-white rounded-lg shadow-xl w-full max-h-[90vh] overflow-y-auto;
}

.modal-header {
  @apply flex items-center justify-between p-4 border-b;
}

.modal-body {
  @apply p-4;
}

.modal-footer {
  @apply flex justify-end gap-2 p-4 border-t bg-gray-50;
}

.modal-close {
  @apply p-2 text-gray-500 hover:text-gray-700 rounded-full hover:bg-gray-100 transition-colors;
}

.btn-primary {
  @apply px-4 py-2 bg-primary text-white rounded hover:bg-primary-dark transition-colors disabled:opacity-50;
}

.btn-secondary {
  @apply px-4 py-2 bg-gray-100 text-gray-700 rounded hover:bg-gray-200 transition-colors;
}

.form-control {
  @apply w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 
         focus:ring-orange-500 focus:border-orange-500 transition-all;
}

.form-select {
  @apply w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 
         focus:ring-orange-500 focus:border-orange-500 transition-all;
}

.role-admin {
  @apply bg-purple-100 text-purple-800;
}

.role-premium {
  @apply bg-yellow-100 text-yellow-800;
}

.role-user {
  @apply bg-blue-100 text-blue-800;
}

.btn-action {
  @apply p-2 rounded-full transition-all duration-200 flex items-center justify-center 
         w-8 h-8 text-sm border border-transparent hover:border-current;
}

.btn-view {
  @apply bg-blue-50 text-blue-600 hover:bg-blue-100 hover:text-blue-700;
}

.btn-edit {
  @apply bg-orange-50 text-orange-600 hover:bg-orange-100 hover:text-orange-700;
}

.btn-success {
  @apply bg-green-50 text-green-600 hover:bg-green-100 hover:text-green-700;
}

.btn-danger {
  @apply bg-red-50 text-red-600 hover:bg-red-100 hover:text-red-700;
}
</style>