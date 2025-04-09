<template>
  <div id="app" class="min-h-screen bg-gray-50">
    <!-- Alerta de estado de conexión -->
    <div v-if="!isOnline" class="connection-alert">
      <i class="fas fa-wifi"></i> Sin conexión a Internet. La aplicación está funcionando en modo offline.
    </div>
    <!-- Layout para rutas autenticadas -->
    <div v-if="$route.meta.requiresAuth" class="flex min-h-screen">
      <!-- Sidebar -->
      <div class="fixed inset-y-0 left-0 z-10 flex flex-col text-white transition-all duration-300 ease-in-out" 
           :class="{ 'w-16': sidebarCollapsed, 'w-64': !sidebarCollapsed }" 
           style="background: linear-gradient(180deg, #1a1a1a 0%, #2d2d2d 100%);">
        <div class="flex items-center justify-between p-4 border-b border-gray-700">
          <router-link class="flex items-center text-white font-bold no-underline" to="/dashboard">
            <div class="flex items-center justify-center w-10 h-10 rounded-lg" 
                 style="background: linear-gradient(135deg, #FF7F00 0%, #FF5722 100%);">
              <i class="fas fa-dragon text-white text-xl"></i>
            </div>
            <span v-if="!sidebarCollapsed" class="truncate ml-3 text-lg font-bold">Admin Panel</span>
          </router-link>
          <button @click="toggleSidebar" 
                  class="text-white hover:bg-gray-700 p-2 rounded-full transition-all hover:rotate-180">
            <i class="fas" :class="sidebarCollapsed ? 'fa-angle-right' : 'fa-angle-left'"></i>
          </button>
        </div>
        <div class="flex-1 overflow-y-auto py-4">
          <ul class="space-y-2 px-2">
            <li>
              <router-link class="flex items-center px-4 py-3 text-gray-300 rounded-lg hover:bg-orange-500/50 hover:text-white transition-all" 
                :class="{ 'justify-center': sidebarCollapsed, 'bg-gradient-to-r from-orange-500/20 to-orange-500/10 text-white': $route.path === '/dashboard' }" 
                to="/dashboard" 
                :title="sidebarCollapsed ? 'Dashboard' : ''">
                <i class="fas fa-tachometer-alt"></i>
                <span v-if="!sidebarCollapsed" class="ml-3">Dashboard</span>
              </router-link>
            </li>
            <li>
              <router-link class="flex items-center px-4 py-3 text-gray-300 rounded-lg hover:bg-orange-500/50 hover:text-white transition-all" 
                :class="{ 'justify-center': sidebarCollapsed, 'bg-gradient-to-r from-orange-500/20 to-orange-500/10 text-white': $route.path.includes('/cards') }" 
                to="/cards" 
                :title="sidebarCollapsed ? 'Cartas' : ''">
                <i class="fas fa-id-card"></i>
                <span v-if="!sidebarCollapsed" class="ml-3">Cartas</span>
              </router-link>
            </li>
            <li>
              <router-link class="flex items-center px-4 py-3 text-gray-300 rounded-lg hover:bg-orange-500/50 hover:text-white transition-all" 
                :class="{ 'justify-center': sidebarCollapsed, 'bg-gradient-to-r from-orange-500/20 to-orange-500/10 text-white': $route.path.includes('/packs') }" 
                to="/packs" 
                :title="sidebarCollapsed ? 'Sobres' : ''">
                <i class="fas fa-box-open"></i>
                <span v-if="!sidebarCollapsed" class="ml-3">Sobres</span>
              </router-link>
            </li>
            <li>
              <router-link class="flex items-center px-4 py-3 text-gray-300 rounded-lg hover:bg-orange-500/50 hover:text-white transition-all" 
                :class="{ 'justify-center': sidebarCollapsed, 'bg-gradient-to-r from-orange-500/20 to-orange-500/10 text-white': $route.path.includes('/users') }" 
                to="/users" 
                :title="sidebarCollapsed ? 'Usuarios' : ''">
                <i class="fas fa-users"></i>
                <span v-if="!sidebarCollapsed" class="ml-3">Usuarios</span>
              </router-link>
            </li>
            <li >
              <router-link class="flex items-center px-4 py-3 text-gray-300 rounded-lg hover:bg-orange-500/50 hover:text-white transition-all" 
                :class="{ 'justify-center': sidebarCollapsed, 'bg-gradient-to-r from-orange-500/20 to-orange-500/10 text-white': $route.path.includes('/categories') }" 
                to="/categories" 
                :title="sidebarCollapsed ? 'Categorias' : ''">               
                <i class="fas fa-tags"></i>
                <span v-if="!sidebarCollapsed" class="ml-3">Categorias</span>
              </router-link>
            </li>
          </ul>
        </div>
        <div class="p-4 border-t border-gray-700">
          <button @click="logout" 
                  class="w-full flex items-center px-4 py-3 text-gray-300 rounded-lg hover:bg-red-500/10 hover:text-red-400 transition-all" 
                  :class="{ 'justify-center': sidebarCollapsed }" 
                  :title="sidebarCollapsed ? 'Cerrar sesión' : ''">
            <i class="fas fa-sign-out-alt"></i>
            <span v-if="!sidebarCollapsed" class="ml-3">Cerrar sesión</span>
          </button>
        </div>
      </div>
      
      <!-- Contenido principal -->
      <div class="main-content" :class="{ 'expanded': sidebarCollapsed }">
        <!-- Navbar superior -->
        <nav class="flex items-center justify-between px-6 py-4 bg-white shadow-sm">
          <div class="flex items-center">
            <h5 class="text-gray-800 font-semibold mb-0">{{ pageTitle }}</h5>
          </div>
          <div class="flex items-center space-x-4">
            <div class="flex items-center space-x-3">
              <span class="text-gray-600">{{ currentUser?.email }}</span>
              <div class="relative">
                <button class="flex items-center space-x-2 text-gray-600 hover:text-gray-800">
                  <i class="fas fa-user-circle text-xl"></i>
                  <i class="fas fa-chevron-down text-xs"></i>
                </button>
              </div>
            </div>
          </div>
        </nav>
        
        <!-- Contenido de la página -->
        <main class="container mx-auto px-6 py-6">
          <div class="bg-white rounded-lg shadow-sm p-6">
            <router-view />
          </div>
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
  background: linear-gradient(90deg, #f44336 0%, #e53935 100%);
  color: white;
  text-align: center;
  padding: 12px 16px;
  z-index: 9999;
  font-weight: 500;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
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
  background: linear-gradient(180deg, #1a1a1a 0%, #2d2d2d 100%);
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
  width: 64px;
}

/* Contenido principal */
.main-content {
  flex: 1;
  margin-left: 250px;
  transition: margin-left 0.3s ease;
}

.main-content.expanded {
  margin-left: 64px;
}

/* Navbar */
.navbar {
  background: linear-gradient(90deg, #FF7F00 0%, #FF5722 100%);
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

/* Tarjetas */
.card {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
  transition: all 0.3s ease;
}

.card:hover {
  box-shadow: 0 4px 8px rgba(0,0,0,0.1);
}

/* Botones */
.btn-primary {
  background: linear-gradient(90deg, #FF7F00 0%, #FF5722 100%);
  border: none;
  color: white;
  padding: 8px 16px;
  border-radius: 6px;
  transition: all 0.3s ease;
}

.btn-primary:hover {
  background: linear-gradient(90deg, #FF5722 0%, #FF7F00 100%);
  transform: translateY(-1px);
}

/* Tablas */
.table {
  width: 100%;
  border-collapse: separate;
  border-spacing: 0;
}

.table th {
  background: #f8f9fa;
  padding: 12px;
  text-align: left;
  font-weight: 600;
  color: #495057;
}

.table td {
  padding: 12px;
  border-bottom: 1px solid #e9ecef;
}

/* Formularios */
.form-control {
  border: 1px solid #ced4da;
  border-radius: 6px;
  padding: 8px 12px;
  transition: all 0.3s ease;
}

.form-control:focus {
  border-color: #FF7F00;
  box-shadow: 0 0 0 0.2rem rgba(255, 127, 0, 0.25);
}

/* Animaciones */
@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

.fade-in {
  animation: fadeIn 0.3s ease-in-out;
}
</style>