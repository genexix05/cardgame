<template>
  <div id="app" class="min-h-screen bg-gray-100">
    <!-- Alerta de estado de conexión -->
    <div v-if="!isOnline" class="connection-alert">
      <i class="fas fa-wifi"></i> Sin conexión a Internet. La aplicación está funcionando en modo offline.
    </div>
    <!-- Layout para rutas autenticadas -->
    <div v-if="$route.meta.requiresAuth" class="flex min-h-screen">
      <!-- Sidebar -->
      <div class="fixed inset-y-0 left-0 z-10 flex flex-col text-white transition-all duration-300 ease-in-out" :class="{ 'w-16': sidebarCollapsed, 'w-64': !sidebarCollapsed }" style="background-color: var(--gray-900);">
        <div class="flex items-center justify-between p-4 border-b border-gray-700">
          <router-link class="flex items-center text-white font-bold no-underline" to="/dashboard">
            <div class="flex items-center justify-center w-8 h-8 rounded-lg" style="background-color: var(--primary);">
              <i class="fas fa-dragon text-white"></i>
            </div>
            <span v-if="!sidebarCollapsed" class="truncate ml-3 text-lg">Admin Panel</span>
          </router-link>
          <button @click="toggleSidebar" class="text-white hover:bg-gray-700 p-2 rounded-full transition-all hover:rotate-180">
            <i class="fas" :class="sidebarCollapsed ? 'fa-angle-right' : 'fa-angle-left'"></i>
          </button>
        </div>
        <div class="flex-1 overflow-y-auto py-4">
          <ul class="space-y-2 px-2">
            <li>
              <router-link class="flex items-center px-4 py-3 text-gray-300 rounded-lg hover:bg-gray-800 hover:text-white transition-all" 
                :class="{ 'justify-center': sidebarCollapsed, 'bg-gray-800 text-white': $route.path === '/dashboard' }" 
                to="/dashboard" 
                :title="sidebarCollapsed ? 'Dashboard' : ''">
                <i class="fas fa-tachometer-alt"></i>
                <span v-if="!sidebarCollapsed" class="ml-3">Dashboard</span>
              </router-link>
            </li>
            <li>
              <router-link class="flex items-center px-4 py-3 text-gray-300 rounded-lg hover:bg-gray-800 hover:text-white transition-all" 
                :class="{ 'justify-center': sidebarCollapsed, 'bg-gray-800 text-white': $route.path.includes('/cards') }" 
                to="/cards" 
                :title="sidebarCollapsed ? 'Cartas' : ''">
                <i class="fas fa-id-card"></i>
                <span v-if="!sidebarCollapsed" class="ml-3">Cartas</span>
              </router-link>
            </li>
            <li>
              <router-link class="flex items-center px-4 py-3 text-gray-300 rounded-lg hover:bg-gray-800 hover:text-white transition-all" 
                :class="{ 'justify-center': sidebarCollapsed, 'bg-gray-800 text-white': $route.path.includes('/packs') }" 
                to="/packs" 
                :title="sidebarCollapsed ? 'Sobres' : ''">
                <i class="fas fa-box-open"></i>
                <span v-if="!sidebarCollapsed" class="ml-3">Sobres</span>
              </router-link>
            </li>
            <li>
              <router-link class="flex items-center px-4 py-3 text-gray-300 rounded-lg hover:bg-gray-800 hover:text-white transition-all" 
                :class="{ 'justify-center': sidebarCollapsed, 'bg-gray-800 text-white': $route.path.includes('/users') }" 
                to="/users" 
                :title="sidebarCollapsed ? 'Usuarios' : ''">
                <i class="fas fa-users"></i>
                <span v-if="!sidebarCollapsed" class="ml-3">Usuarios</span>
              </router-link>
            </li>
          </ul>
        </div>
        <div class="p-4 border-t border-gray-700">
          <button @click="logout" class="w-full flex items-center px-4 py-3 text-gray-300 rounded-lg hover:bg-red-500/10 hover:text-red-400 transition-all" :class="{ 'justify-center': sidebarCollapsed }" :title="sidebarCollapsed ? 'Cerrar sesión' : ''">
            <i class="fas fa-sign-out-alt"></i>
            <span v-if="!sidebarCollapsed" class="ml-3">Cerrar sesión</span>
          </button>
        </div>
      </div>
      
      <!-- Contenido principal -->
      <div class="main-content" :class="{ 'expanded': sidebarCollapsed }">
        <!-- Navbar superior -->
        <nav class="flex items-center justify-between px-4 py-3 bg-primary text-white shadow-md">
          <div class="container-fluid">
            <div class="d-flex align-items-center">
              <h5 class="text-white mb-0">{{ pageTitle }}</h5>
            </div>
            <div class="d-flex align-items-center">
              <span class="text-white me-3">{{ currentUser?.email }}</span>
              <div class="dropdown">
                <button class="btn btn-outline-light btn-sm dropdown-toggle" type="button" id="userDropdown" data-bs-toggle="dropdown">
                  <i class="fas fa-user-circle"></i>
                </button>
                <ul class="dropdown-menu dropdown-menu-end">
                  <li><button class="dropdown-item" @click="logout"><i class="fas fa-sign-out-alt me-2"></i>Cerrar sesión</button></li>
                </ul>
              </div>
            </div>
          </div>
        </nav>
        
        <!-- Contenido de la página -->
        <main class="container-fluid py-4">
          <router-view />
        </main>
      </div>
    </div>
    
    <!-- Layout para rutas no autenticadas -->
    <div v-else>
      <router-view />
    </div>
  </div>
</template>

<script>
import { getAuth, signOut, onAuthStateChanged } from 'firebase/auth'
import { computed, ref, watch, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import { checkFirestoreConnection } from './firebase'

export default {
  name: 'App',
  setup() {
    const sidebarCollapsed = ref(false)
    const currentUser = ref(null)
    const route = useRoute()
    const isOnline = ref(navigator.onLine)
    const firestoreConnected = ref(true)
    
    // Obtener el título de la página actual
    const pageTitle = computed(() => {
      switch(route.name) {
        case 'Dashboard': return 'Dashboard'
        case 'Cards': return 'Gestión de Cartas'
        case 'NewCard': return 'Nueva Carta'
        case 'EditCard': return 'Editar Carta'
        case 'Packs': return 'Gestión de Sobres'
        case 'NewPack': return 'Nuevo Sobre'
        case 'EditPack': return 'Editar Sobre'
        case 'Users': return 'Gestión de Usuarios'
        case 'UserDetail': return 'Detalle de Usuario'
        default: return 'Panel de Administración'
      }
    })
    
    // Escuchar cambios en la autenticación
    const auth = getAuth()
    onAuthStateChanged(auth, (user) => {
      currentUser.value = user
    })
    
    // Alternar el estado del sidebar
    const toggleSidebar = () => {
      sidebarCollapsed.value = !sidebarCollapsed.value
      // Guardar preferencia en localStorage
      localStorage.setItem('sidebarCollapsed', sidebarCollapsed.value)
    }
    
    // Cargar preferencia del sidebar al iniciar
    const savedState = localStorage.getItem('sidebarCollapsed')
    if (savedState !== null) {
      sidebarCollapsed.value = savedState === 'true'
    }
    
    // Monitorear el estado de la conexión
    const updateOnlineStatus = () => {
      isOnline.value = navigator.onLine
      if (isOnline.value) {
        // Verificar conexión con Firestore cuando recuperamos Internet
        checkFirestoreConnection().then(connected => {
          firestoreConnected.value = connected
        })
      }
    }
    
    // Configurar event listeners para cambios de conexión
    onMounted(() => {
      window.addEventListener('online', updateOnlineStatus)
      window.addEventListener('offline', updateOnlineStatus)
      
      // Verificar conexión inicial con Firestore
      checkFirestoreConnection().then(connected => {
        firestoreConnected.value = connected
      })
    })
    
    // Limpiar event listeners al desmontar
    onUnmounted(() => {
      window.removeEventListener('online', updateOnlineStatus)
      window.removeEventListener('offline', updateOnlineStatus)
    })
    
    // Método para cerrar sesión
    const logout = () => {
      signOut(auth).then(() => {
        window.location.href = '/login'
      })
    }
    
    return {
      sidebarCollapsed,
      currentUser,
      pageTitle,
      toggleSidebar,
      logout,
      isOnline,
      firestoreConnected
    }
  }
}
</script>

<style>
/* Alerta de conexión */
.connection-alert {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  background-color: #f44336;
  color: white;
  text-align: center;
  padding: 8px 16px;
  z-index: 9999;
  font-weight: 500;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

/* Estilos globales */
body {
  background-color: #f8f9fa;
  overflow-x: hidden;
}

/* Layout de administración */
.admin-layout {
  min-height: 100vh;
  display: flex;
}

/* Sidebar */
.sidebar {
  width: 250px;
  background-color: #343a40;
  color: #fff;
  height: 100vh;
  position: fixed;
  left: 0;
  top: 0;
  z-index: 1000;
  transition: all 0.3s ease;
  display: flex;
  flex-direction: column;
}

.sidebar.collapsed {
  width: 70px;
}

.sidebar-header {
  padding: 1rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.sidebar-brand {
  color: #fff;
  text-decoration: none;
  font-weight: bold;
  font-size: 1.2rem;
  display: flex;
  align-items: center;
  white-space: nowrap;
  overflow: hidden;
}

.sidebar-toggle {
  color: #fff;
  background: transparent;
  border: none;
}

.sidebar-menu {
  flex: 1;
  overflow-y: auto;
  padding-top: 1rem;
}

.sidebar-menu .nav-link {
  color: rgba(255, 255, 255, 0.8);
  padding: 0.8rem 1rem;
  display: flex;
  align-items: center;
  transition: all 0.3s;
}

.sidebar-menu .nav-link:hover,
.sidebar-menu .nav-link.router-link-active {
  color: #fff;
  background-color: rgba(255, 255, 255, 0.1);
}

.sidebar-menu .nav-link i {
  margin-right: 10px;
  width: 20px;
  text-align: center;
}

.sidebar.collapsed .nav-link span {
  display: none;
}

.sidebar-footer {
  padding: 1rem;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
}

.btn-logout {
  width: 100%;
  color: rgba(255, 255, 255, 0.8);
  background-color: transparent;
  border: 1px solid rgba(255, 255, 255, 0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0.5rem;
  transition: all 0.3s;
}

.btn-logout:hover {
  color: #fff;
  background-color: rgba(255, 255, 255, 0.1);
}

.btn-logout i {
  margin-right: 10px;
}

.sidebar.collapsed .btn-logout span {
  display: none;
}

.sidebar.collapsed .btn-logout i {
  margin-right: 0;
}

/* Contenido principal */
.main-content {
  flex: 1;
  margin-left: 250px;
  transition: all 0.3s ease;
  width: calc(100% - 250px);
}

.main-content.expanded {
  margin-left: 70px;
  width: calc(100% - 70px);
}

.main-content main {
  min-height: calc(100vh - 56px);
}

/* Estilos para las tarjetas */
.card {
  border-radius: 0.5rem;
  border: none;
  box-shadow: 0 0.125rem 0.25rem rgba(0, 0, 0, 0.075);
  transition: all 0.3s ease;
}

.card:hover {
  box-shadow: 0 0.5rem 1rem rgba(0, 0, 0, 0.15);
}

.card-header {
  background-color: rgba(0, 0, 0, 0.03);
  border-bottom: 1px solid rgba(0, 0, 0, 0.125);
  font-weight: 500;
}

/* Estilos para la página de login */
.login-container {
  min-height: 100vh;
  background-color: #f8f9fa;
  background-image: linear-gradient(135deg, #ff9d6c 10%, #bb4e75 100%);
  display: flex;
  justify-content: center;
  align-items: center;
}

.login-card {
  width: 100%;
  max-width: 400px;
  border-radius: 1rem;
  box-shadow: 0 0.5rem 1rem rgba(0, 0, 0, 0.15);
  background-color: rgba(255, 255, 255, 0.9);
  backdrop-filter: blur(10px);
}

/* Estilos para tablas */
.table-responsive {
  border-radius: 0.5rem;
  overflow: hidden;
}

.table {
  margin-bottom: 0;
}

.table thead th {
  background-color: #f8f9fa;
  border-bottom: 2px solid #dee2e6;
  font-weight: 600;
}

/* Estilos para botones */
.btn {
  border-radius: 0.25rem;
  padding: 0.375rem 0.75rem;
  font-weight: 500;
  transition: all 0.2s;
}

.btn-primary {
  background-color: var(--primary-color);
  border-color: var(--primary-color);
}

.btn-primary:hover {
  background-color: var(--primary-dark);
  border-color: var(--primary-dark);
}

/* Estilos para formularios */
.form-control {
  border-radius: 0.25rem;
  padding: 0.5rem 0.75rem;
}

.form-control:focus {
  box-shadow: 0 0 0 0.25rem rgba(255, 87, 34, 0.25);
  border-color: var(--primary-color);
}

/* Estilos para miniaturas de cartas */
.card-thumbnail {
  width: 40px;
  height: 40px;
  object-fit: cover;
  border-radius: 4px;
}

.card-img-container {
  width: 40px;
  height: 40px;
  border-radius: 4px;
  overflow: hidden;
  background-color: #e9ecef;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Animaciones */
@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

.fade-in {
  animation: fadeIn 0.3s ease-in-out;
}

/* Responsive */
@media (max-width: 768px) {
  .sidebar {
    width: 70px;
  }
  
  .sidebar:not(.collapsed) {
    width: 250px;
  }
  
  .main-content {
    margin-left: 70px;
    width: calc(100% - 70px);
  }
  
  .main-content.expanded {
    margin-left: 250px;
    width: calc(100% - 250px);
  }
  
  .sidebar-menu .nav-link span,
  .sidebar-brand span,
  .btn-logout span {
    display: none;
  }
  
  .sidebar:not(.collapsed) .sidebar-menu .nav-link span,
  .sidebar:not(.collapsed) .sidebar-brand span,
  .sidebar:not(.collapsed) .btn-logout span {
    display: inline;
  }
  
  .sidebar-menu .nav-link i {
    margin-right: 0;
  }
  
  .sidebar:not(.collapsed) .sidebar-menu .nav-link i {
    margin-right: 10px;
  }
}
</style>