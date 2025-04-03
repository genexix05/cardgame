<template>
  <div class="users-view">
    <div class="d-flex justify-content-between align-items-center mb-4">
      <div>
        <h1 class="fw-bold mb-1">Gestión de Usuarios</h1>
        <p class="text-muted">Administra todos los usuarios del sistema</p>
      </div>
      <button class="btn btn-primary d-flex align-items-center" @click="openCreateUserModal">
        <i class="fas fa-user-plus me-2"></i>Crear Usuario
      </button>
    </div>

    <!-- Filtros y búsqueda -->
    <div class="card mb-4">
      <div class="card-body">
        <div class="row g-3">
          <div class="col-md-6">
            <div class="input-group">
              <span class="input-group-text">
                <i class="fas fa-search"></i>
              </span>
              <input 
                type="text" 
                class="form-control" 
                placeholder="Buscar por nombre, email o ID..." 
                v-model="searchQuery"
                @input="debounceSearch"
              >
              <button 
                class="btn btn-outline-secondary" 
                type="button"
                @click="clearSearch"
                v-if="searchQuery"
              >
                <i class="fas fa-times"></i>
              </button>
            </div>
          </div>
          
          <div class="col-md-3">
            <select class="form-select" v-model="roleFilter">
              <option value="">Todos los roles</option>
              <option value="user">Usuario normal</option>
              <option value="premium">Usuario premium</option>
              <option value="admin">Administrador</option>
            </select>
          </div>
          
          <div class="col-md-3">
            <select class="form-select" v-model="sortBy">
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
    </div>

    <!-- Tabla de usuarios -->
    <div class="card mb-4">
      <div class="table-responsive">
        <table class="table table-hover table-striped align-middle mb-0">
          <thead class="table-light">
            <tr>
              <th scope="col" style="width: 60px">#</th>
              <th scope="col">Usuario</th>
              <th scope="col">Email</th>
              <th scope="col">Rol</th>
              <th scope="col">Registro</th>
              <th scope="col">Último acceso</th>
              <th scope="col">Colección</th>
              <th scope="col">Estado</th>
              <th scope="col" class="text-end">Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="9" class="text-center py-4">
                <div class="spinner-border text-primary" role="status">
                  <span class="visually-hidden">Cargando...</span>
                </div>
                <p class="mt-2 text-muted">Cargando usuarios...</p>
              </td>
            </tr>
            
            <tr v-else-if="!users.length">
              <td colspan="9" class="text-center py-4">
                <p class="mb-0" v-if="searchQuery || roleFilter">
                  <i class="fas fa-search me-2"></i>No se encontraron usuarios con los filtros aplicados.
                </p>
                <p class="mb-0" v-else>
                  <i class="fas fa-users-slash me-2"></i>No hay usuarios registrados en el sistema.
                </p>
              </td>
            </tr>
            
            <tr v-for="(user, index) in users" :key="user.id">
              <td class="text-muted">{{ (currentPage - 1) * pageSize + index + 1 }}</td>
              
              <td>
                <div class="d-flex align-items-center">
                  <div class="flex-shrink-0 me-2">
                    <div class="user-avatar">
                      <img 
                        :src="user.photoURL || '/assets/default-avatar.png'" 
                        :alt="user.displayName || 'Usuario'" 
                        class="rounded-circle"
                      >
                    </div>
                  </div>
                  <div class="flex-grow-1">
                    <div class="fw-medium">{{ user.displayName || 'Usuario sin nombre' }}</div>
                    <small class="text-muted">ID: {{ user.id }}</small>
                  </div>
                </div>
              </td>
              
              <td>
                <div>{{ user.email }}</div>
                <small v-if="user.emailVerified" class="text-success">
                  <i class="fas fa-check-circle me-1"></i>Verificado
                </small>
                <small v-else class="text-warning">
                  <i class="fas fa-exclamation-circle me-1"></i>Sin verificar
                </small>
              </td>
              
              <td>
                <span 
                  class="badge rounded-pill"
                  :class="{
                    'bg-info': user.role === 'admin',
                    'bg-success': user.role === 'premium',
                    'bg-secondary': user.role === 'user' || !user.role
                  }"
                >
                  {{ getRoleName(user.role) }}
                </span>
              </td>
              
              <td>
                <div>{{ formatDate(user.registrationDate) }}</div>
                <small class="text-muted">{{ formatTimeAgo(user.registrationDate) }}</small>
              </td>
              
              <td>
                <div>{{ formatDate(user.lastLogin) }}</div>
                <small class="text-muted">{{ formatTimeAgo(user.lastLogin) }}</small>
              </td>
              
              <td>
                <div class="d-flex align-items-center">
                  <i class="fas fa-layer-group me-2 text-muted"></i>
                  <div>
                    <div class="fw-medium">{{ user.stats?.cardsCount || 0 }} cartas</div>
                    <small class="text-muted">{{ user.stats?.packsOpened || 0 }} sobres</small>
                  </div>
                </div>
              </td>
              
              <td>
                <span 
                  class="badge"
                  :class="{
                    'bg-success': !user.disabled,
                    'bg-danger': user.disabled
                  }"
                >
                  {{ user.disabled ? 'Bloqueado' : 'Activo' }}
                </span>
              </td>
              
              <td class="text-end">
                <div class="btn-group">
                  <button 
                    class="btn btn-sm btn-outline-primary" 
                    @click="viewUserDetails(user.id)"
                    title="Ver detalles"
                  >
                    <i class="fas fa-eye"></i>
                  </button>
                  
                  <button 
                    class="btn btn-sm btn-outline-secondary" 
                    @click="editUserRole(user)"
                    title="Cambiar rol"
                  >
                    <i class="fas fa-user-tag"></i>
                  </button>
                  
                  <button 
                    class="btn btn-sm" 
                    :class="user.disabled ? 'btn-outline-success' : 'btn-outline-danger'"
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

    <!-- Paginación -->
    <nav aria-label="Paginación de usuarios" v-if="totalPages > 1">
      <ul class="pagination justify-content-center">
        <li class="page-item" :class="{ disabled: currentPage === 1 }">
          <a class="page-link" href="#" @click.prevent="changePage(currentPage - 1)">
            <i class="fas fa-chevron-left"></i>
          </a>
        </li>
        
        <li v-for="page in paginationNumbers" :key="page" class="page-item" :class="{ active: currentPage === page }">
          <a class="page-link" href="#" @click.prevent="changePage(page)">{{ page }}</a>
        </li>
        
        <li class="page-item" :class="{ disabled: currentPage === totalPages }">
          <a class="page-link" href="#" @click.prevent="changePage(currentPage + 1)">
            <i class="fas fa-chevron-right"></i>
          </a>
        </li>
      </ul>
      
      <div class="text-center mt-2">
        <small class="text-muted">
          Mostrando {{ (currentPage - 1) * pageSize + 1 }} - {{ Math.min(currentPage * pageSize, totalUsers) }} de {{ totalUsers }} usuarios
        </small>
      </div>
    </nav>

    <!-- Modal de cambio de rol -->
    <div class="modal fade" id="roleModal" tabindex="-1" aria-labelledby="roleModalLabel" aria-hidden="true" ref="roleModal">
      <div class="modal-dialog">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title" id="roleModalLabel">Cambiar rol de usuario</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
          </div>
          <div class="modal-body">
            <p>Estás cambiando el rol del usuario <strong>{{ selectedUser?.displayName || 'Usuario' }}</strong>.</p>
            
            <div class="form-group">
              <label for="userRole" class="form-label">Selecciona un rol:</label>
              <select class="form-select" id="userRole" v-model="selectedRole">
                <option value="user">Usuario normal</option>
                <option value="premium">Usuario premium</option>
                <option value="admin">Administrador</option>
              </select>
            </div>
            
            <div class="mt-3 alert alert-warning" v-if="selectedRole === 'admin'">
              <i class="fas fa-exclamation-triangle me-2"></i>
              <strong>Advertencia:</strong> Los administradores tienen acceso completo al panel de administración y a todas las funcionalidades del sistema.
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">
              <i class="fas fa-times me-2"></i>Cancelar
            </button>
            <button 
              type="button" 
              class="btn btn-primary d-flex align-items-center justify-content-center" 
              @click="saveUserRole" 
              :disabled="roleUpdateLoading"
              style="min-width: 140px;"
            >
              <span v-if="roleUpdateLoading" class="spinner-border spinner-border-sm me-2" role="status"></span>
              <i v-else class="fas fa-save me-2"></i>
              Guardar cambios
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal de detalles de usuario -->
    <div class="modal fade" id="userDetailsModal" tabindex="-1" aria-labelledby="userDetailsModalLabel" aria-hidden="true" ref="userDetailsModal">
      <div class="modal-dialog modal-lg">
        <div class="modal-content">
          <div class="modal-header">
            <h5 class="modal-title" id="userDetailsModalLabel">Detalles del usuario</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Cerrar"></button>
          </div>
          <div class="modal-body">
            <div class="text-center mb-4" v-if="userDetailsLoading">
              <div class="spinner-border text-primary" role="status">
                <span class="visually-hidden">Cargando...</span>
              </div>
              <p class="mt-2 text-muted">Cargando detalles del usuario...</p>
            </div>
            
            <div v-else-if="userDetails">
              <!-- Información básica -->
              <div class="d-flex mb-4">
                <div class="flex-shrink-0 me-3">
                  <img 
                    :src="userDetails.photoURL || '/assets/default-avatar.png'" 
                    :alt="userDetails.displayName || 'Usuario'" 
                    class="rounded-circle user-details-avatar"
                  >
                </div>
                <div class="flex-grow-1">
                  <h4 class="mb-1">{{ userDetails.displayName || 'Usuario sin nombre' }}</h4>
                  <p class="text-muted mb-1">{{ userDetails.email }}</p>
                  <div class="mb-2">
                    <span 
                      class="badge rounded-pill me-2"
                      :class="{
                        'bg-info': userDetails.role === 'admin',
                        'bg-success': userDetails.role === 'premium',
                        'bg-secondary': userDetails.role === 'user' || !userDetails.role
                      }"
                    >
                      {{ getRoleName(userDetails.role) }}
                    </span>
                    <span 
                      class="badge rounded-pill"
                      :class="{
                        'bg-success': !userDetails.disabled,
                        'bg-danger': userDetails.disabled
                      }"
                    >
                      {{ userDetails.disabled ? 'Bloqueado' : 'Activo' }}
                    </span>
                  </div>
                  <small class="text-muted">ID: {{ userDetails.id }}</small>
                </div>
              </div>
              
              <!-- Estadísticas y datos de juego -->
              <div class="row mb-4">
                <div class="col-md-6">
                  <div class="card h-100">
                    <div class="card-header">
                      <h6 class="mb-0">Información de cuenta</h6>
                    </div>
                    <div class="card-body">
                      <ul class="list-group list-group-flush">
                        <li class="list-group-item d-flex justify-content-between align-items-start">
                          <div>
                            <div class="fw-medium">Registro</div>
                            <small class="text-muted">{{ formatDate(userDetails.registrationDate, true) }}</small>
                          </div>
                          <span class="text-muted">{{ formatTimeAgo(userDetails.registrationDate) }}</span>
                        </li>
                        <li class="list-group-item d-flex justify-content-between align-items-start">
                          <div>
                            <div class="fw-medium">Último acceso</div>
                            <small class="text-muted">{{ formatDate(userDetails.lastLogin, true) }}</small>
                          </div>
                          <span class="text-muted">{{ formatTimeAgo(userDetails.lastLogin) }}</span>
                        </li>
                        <li class="list-group-item d-flex justify-content-between align-items-start">
                          <div class="fw-medium">Email verificado</div>
                          <span v-if="userDetails.emailVerified" class="text-success">
                            <i class="fas fa-check-circle me-1"></i>Sí
                          </span>
                          <span v-else class="text-warning">
                            <i class="fas fa-exclamation-circle me-1"></i>No
                          </span>
                        </li>
                        <li class="list-group-item d-flex justify-content-between align-items-start">
                          <div class="fw-medium">Dispositivo</div>
                          <span class="text-muted">{{ userDetails.deviceInfo || 'Desconocido' }}</span>
                        </li>
                      </ul>
                    </div>
                  </div>
                </div>
                
                <div class="col-md-6">
                  <div class="card h-100">
                    <div class="card-header">
                      <h6 class="mb-0">Estadísticas de juego</h6>
                    </div>
                    <div class="card-body">
                      <ul class="list-group list-group-flush">
                        <li class="list-group-item d-flex justify-content-between align-items-start">
                          <div class="fw-medium">Cartas coleccionadas</div>
                          <span class="badge bg-primary rounded-pill">{{ userDetails.stats?.cardsCount || 0 }}</span>
                        </li>
                        <li class="list-group-item d-flex justify-content-between align-items-center">
                          <div class="d-flex align-items-center">
                            <div class="icon-wrapper me-2" style="background-color: rgba(79, 70, 229, 0.1); padding: 8px; border-radius: 8px;">
                              <i class="fas fa-box-open" style="color: var(--primary); font-size: 14px;"></i>
                            </div>
                            <div class="fw-medium">Sobres abiertos</div>
                          </div>
                          <span class="badge bg-primary rounded-pill">{{ userDetails.stats?.packsOpened || 0 }}</span>
                        </li>
                        <li class="list-group-item d-flex justify-content-between align-items-center">
                          <div class="d-flex align-items-center">
                            <div class="icon-wrapper me-2" style="background-color: rgba(245, 158, 11, 0.1); padding: 8px; border-radius: 8px;">
                              <i class="fas fa-coins" style="color: var(--warning); font-size: 14px;"></i>
                            </div>
                            <div class="fw-medium">Monedas actuales</div>
                          </div>
                          <span class="badge bg-warning text-dark rounded-pill">{{ userDetails.stats?.coins || 0 }}</span>
                        </li>
                        <li class="list-group-item d-flex justify-content-between align-items-center">
                          <div class="d-flex align-items-center">
                            <div class="icon-wrapper me-2" style="background-color: rgba(239, 68, 68, 0.1); padding: 8px; border-radius: 8px;">
                              <i class="fas fa-crown" style="color: var(--danger); font-size: 14px;"></i>
                            </div>
                            <div class="fw-medium">Cartas legendarias</div>
                          </div>
                          <span class="badge bg-danger rounded-pill">{{ userDetails.stats?.legendaryCards || 0 }}</span>
                        </li>
                      </ul>
                    </div>
                  </div>
                </div>
              </div>
              
              <!-- Tabs con información adicional -->
              <ul class="nav nav-tabs" id="userDetailsTabs" role="tablist">
                <li class="nav-item" role="presentation">
                  <button 
                    class="nav-link active" 
                    id="cards-tab" 
                    data-bs-toggle="tab" 
                    data-bs-target="#cards-tab-pane" 
                    type="button" 
                    role="tab"
                  >
                    <i class="fas fa-layer-group me-2"></i>Colección
                  </button>
                </li>
                <li class="nav-item" role="presentation">
                  <button 
                    class="nav-link" 
                    id="activity-tab" 
                    data-bs-toggle="tab" 
                    data-bs-target="#activity-tab-pane" 
                    type="button" 
                    role="tab"
                  >
                    <i class="fas fa-history me-2"></i>Actividad
                  </button>
                </li>
                <li class="nav-item" role="presentation">
                  <button 
                    class="nav-link" 
                    id="notes-tab" 
                    data-bs-toggle="tab" 
                    data-bs-target="#notes-tab-pane" 
                    type="button" 
                    role="tab"
                  >
                    <i class="fas fa-sticky-note me-2"></i>Notas
                  </button>
                </li>
              </ul>
              
              <div class="tab-content mt-3" id="userDetailsTabContent">
                <!-- Pestaña de colección de cartas -->
                <div class="tab-pane fade show active" id="cards-tab-pane" role="tabpanel" aria-labelledby="cards-tab" tabindex="0">
                  <div v-if="userCards.length === 0" class="text-center py-4">
                    <p class="text-muted mb-0">
                      <i class="fas fa-layer-group me-2"></i>Este usuario no tiene cartas en su colección.
                    </p>
                  </div>
                  
                  <div v-else class="row row-cols-1 row-cols-md-4 g-3">
                    <div v-for="card in userCards" :key="card.id" class="col">
                      <div class="card h-100 user-card-item" :class="{'border-warning': card.rarity === 'legendary'}">
                        <div class="card-img-top user-card-image">
                          <img :src="card.imageUrl" :alt="card.name" class="img-fluid">
                          <span 
                            class="badge position-absolute top-0 end-0 m-2"
                            :class="{
                              'bg-secondary': card.rarity === 'common',
                              'bg-success': card.rarity === 'uncommon',
                              'bg-primary': card.rarity === 'rare',
                              'bg-info': card.rarity === 'superRare',
                              'bg-warning': card.rarity === 'ultraRare',
                              'bg-danger': card.rarity === 'legendary'
                            }"
                          >
                            {{ getRarityName(card.rarity) }}
                          </span>
                        </div>
                        <div class="card-body">
                          <h6 class="card-title">{{ card.name }}</h6>
                          <p class="card-text small text-muted">{{ card.series }}</p>
                        </div>
                        <div class="card-footer d-flex justify-content-between">
                          <small class="text-muted">ID: {{ card.id }}</small>
                          <small class="fw-medium">x{{ card.count }}</small>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                
                <!-- Pestaña de actividad reciente -->
                <div class="tab-pane fade" id="activity-tab-pane" role="tabpanel" aria-labelledby="activity-tab" tabindex="0">
                  <div v-if="userActivity.length === 0" class="text-center py-4">
                    <p class="text-muted mb-0">
                      <i class="fas fa-history me-2"></i>No hay registros de actividad para este usuario.
                    </p>
                  </div>
                  
                  <div v-else class="activity-timeline">
                    <div v-for="(activity, index) in userActivity" :key="index" class="activity-item">
                      <div class="activity-icon">
                        <i :class="getActivityIcon(activity.type)"></i>
                      </div>
                      <div class="activity-content">
                        <p class="mb-1">{{ getActivityDescription(activity) }}</p>
                        <small class="text-muted">{{ formatDate(activity.timestamp, true) }} ({{ formatTimeAgo(activity.timestamp) }})</small>
                      </div>
                    </div>
                  </div>
                </div>
                
                <!-- Pestaña de notas de administrador -->
                <div class="tab-pane fade" id="notes-tab-pane" role="tabpanel" aria-labelledby="notes-tab" tabindex="0">
                  <form @submit.prevent="saveAdminNotes">
                    <div class="form-group">
                      <label for="adminNotes" class="form-label">Notas internas (solo visible para administradores)</label>
                      <textarea 
                        class="form-control" 
                        id="adminNotes" 
                        v-model="userDetails.adminNotes" 
                        rows="4" 
                        placeholder="Añade notas sobre este usuario aquí..."
                      ></textarea>
                    </div>
                    <div class="text-end mt-3">
                      <button 
                        type="submit" 
                        class="btn btn-primary" 
                        :disabled="notesUpdateLoading"
                      >
                        <span v-if="notesUpdateLoading" class="spinner-border spinner-border-sm me-2" role="status"></span>
                        Guardar notas
                      </button>
                    </div>
                  </form>
                </div>
              </div>
            </div>
            
            <div v-else class="text-center py-4">
              <p class="text-muted mb-0">
                <i class="fas fa-exclamation-circle me-2"></i>No se pudieron cargar los detalles del usuario.
              </p>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cerrar</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { Modal } from 'bootstrap';

export default {
  name: 'UsersView',
  setup() {
    const store = useStore();
    
    // Estado
    const loading = ref(false);
    const users = ref([]);
    const totalUsers = ref(0);
    const searchQuery = ref('');
    const roleFilter = ref('');
    const sortBy = ref('registrationDate_desc');
    const currentPage = ref(1);
    const pageSize = ref(10);
    
    // Modal de rol
    const roleModal = ref(null);
    const selectedUser = ref(null);
    const selectedRole = ref('user');
    const roleUpdateLoading = ref(false);
    
    // Modal de detalles
    const userDetailsModal = ref(null);
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
      
      try {
        // Llamar a la acción fetchUsers sin esperar un retorno
        await store.dispatch('fetchUsers');
        
        // Obtener los usuarios directamente del estado
        users.value = store.state.users;
        totalUsers.value = store.state.users.length;
        
        // Si no hay datos, inicializar con valores seguros
        if (!users.value || !Array.isArray(users.value)) {
          console.warn('No se recibieron datos de usuarios en el formato esperado');
          users.value = [];
          totalUsers.value = 0;
        }
      } catch (err) {
        console.error('Error al cargar usuarios:', err);
        store.commit('SET_ERROR', 'Error al cargar la lista de usuarios');
        // En caso de error, inicializar con valores seguros
        users.value = [];
        totalUsers.value = 0;
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
      selectedRole.value = user.role || 'user';
      
      // Asegurarse de que el modal esté inicializado correctamente
      if (!roleModal.value) {
        const roleModalEl = document.getElementById('roleModal');
        if (roleModalEl) {
          roleModal.value = new Modal(roleModalEl);
        } else {
          console.error('No se pudo encontrar el elemento del modal de roles de usuario');
          return;
        }
      }
      
      // Mostrar el modal
      roleModal.value.show();
    };
    
    // Guardar cambio de rol
    const saveUserRole = async () => {
      if (!selectedUser.value) return;
      
      roleUpdateLoading.value = true;
      
      try {
        await store.dispatch('updateUserRole', {
          userId: selectedUser.value.id,
          role: selectedRole.value
        });
        
        // Actualizar en la lista local
        const userIndex = users.value.findIndex(u => u.id === selectedUser.value.id);
        if (userIndex >= 0) {
          users.value[userIndex].role = selectedRole.value;
        }
        
        if (roleModal.value) {
          roleModal.value.hide();
        }
      } catch (err) {
        console.error('Error al cambiar el rol del usuario:', err);
        store.commit('SET_ERROR', 'Error al actualizar el rol del usuario');
      } finally {
        roleUpdateLoading.value = false;
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
      userDetails.value = null;
      userCards.value = [];
      userActivity.value = [];
      
      // Asegurarse de que el modal esté inicializado correctamente
      if (!userDetailsModal.value) {
        const userDetailsModalEl = document.getElementById('userDetailsModal');
        if (userDetailsModalEl) {
          userDetailsModal.value = new Modal(userDetailsModalEl);
        } else {
          console.error('No se pudo encontrar el elemento del modal de detalles de usuario');
          return;
        }
      }
      
      // Mostrar el modal
      userDetailsModal.value.show();
      
      try {
        // Cargar detalles completos del usuario
        const userData = await store.dispatch('fetchUserDetails', userId);
        userDetails.value = userData;
        
        // Cargar colección de cartas
        userCards.value = await store.dispatch('fetchUserCards', userId);
        
        // Cargar historial de actividad
        userActivity.value = await store.dispatch('fetchUserActivity', userId);
      } catch (err) {
        console.error('Error al cargar detalles del usuario:', err);
        store.commit('SET_ERROR', 'Error al cargar los detalles del usuario');
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
      
      // Inicializar modales con un pequeño retraso para asegurar que el DOM esté listo
      setTimeout(() => {
        if (typeof document !== 'undefined') {
          const roleModalEl = document.getElementById('roleModal');
          if (roleModalEl) {
            roleModal.value = new Modal(roleModalEl);
          } else {
            console.warn('No se encontró el elemento roleModal en el DOM');
          }
          
          const userDetailsModalEl = document.getElementById('userDetailsModal');
          if (userDetailsModalEl) {
            userDetailsModal.value = new Modal(userDetailsModalEl);
          } else {
            console.warn('No se encontró el elemento userDetailsModal en el DOM');
          }
        }
      }, 200); // Pequeño retraso para garantizar que el DOM esté completamente cargado
    });
    
    // Observar cambios en filtros
    watch([roleFilter, sortBy], () => {
      currentPage.value = 1; // Resetear a la primera página
      loadUsers();
    });
    
    return {
      // Estado
      loading,
      users,
      totalUsers,
      searchQuery,
      roleFilter,
      sortBy,
      currentPage,
      pageSize,
      totalPages,
      paginationNumbers,
      
      // Referencias a modales
      roleModal,
      userDetailsModal,
      
      // Datos de modales
      selectedUser,
      selectedRole,
      roleUpdateLoading,
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
      saveUserRole,
      toggleUserStatus,
      viewUserDetails,
      saveAdminNotes,
      
      // Helpers
      formatDate,
      formatTimeAgo,
      getRoleName,
      getRarityName,
      getActivityIcon,
      getActivityDescription
    };
  }
};
</script>

<style scoped>
.user-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #f8f9fa;
}

.user-avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.user-details-avatar {
  width: 100px;
  height: 100px;
  object-fit: cover;
}

.user-card-item {
  transition: transform 0.2s;
}

.user-card-item:hover {
  transform: translateY(-5px);
}

.user-card-image {
  height: 180px;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #f8f9fa;
}

.user-card-image img {
  max-height: 100%;
  object-fit: contain;
}

.activity-timeline {
  position: relative;
  padding-left: 30px;
}

.activity-timeline::before {
  content: '';
  position: absolute;
  top: 0;
  bottom: 0;
  left: 11px;
  width: 2px;
  background-color: #e9ecef;
}

.activity-item {
  position: relative;
  padding-bottom: 20px;
}

.activity-icon {
  position: absolute;
  left: -30px;
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background-color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1;
}

.activity-content {
  background-color: #f8f9fa;
  border-radius: 0.375rem;
  padding: 12px 15px;
}

.bg-info {
  background-color: #673AB7 !important;
  color: white;
}

.bg-warning {
  background-color: #FF9800 !important;
}

.btn-primary {
  background-color: #FF5722;
  border-color: #FF5722;
}

.btn-primary:hover, .btn-primary:focus {
  background-color: #E64A19;
  border-color: #E64A19;
}
</style>