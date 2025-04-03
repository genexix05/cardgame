<template>
  <div class="user-detail-view">
    <div class="d-flex justify-content-between align-items-center mb-4">
      <h1>Detalle de Usuario</h1>
      <router-link to="/users" class="btn btn-outline-secondary">
        <i class="fas fa-arrow-left me-2"></i>Volver
      </router-link>
    </div>
    
    <div v-if="loading" class="text-center py-5">
      <div class="spinner-border text-primary" role="status">
        <span class="visually-hidden">Cargando...</span>
      </div>
    </div>
    <div v-else-if="error" class="alert alert-danger">
      {{ error }}
      <button class="btn btn-sm btn-outline-danger ms-3" @click="loadUser">Reintentar</button>
    </div>
    <div v-else-if="!user" class="alert alert-warning">
      Usuario no encontrado
    </div>
    <div v-else>
      <!-- Información del usuario -->
      <div class="row">
        <div class="col-md-4 mb-4">
          <div class="card shadow-sm">
            <div class="card-body text-center">
              <div class="avatar-container mb-3">
                <div v-if="user.photoURL" class="avatar">
                  <img :src="user.photoURL" alt="Avatar" class="img-fluid rounded-circle">
                </div>
                <div v-else class="avatar-placeholder d-flex justify-content-center align-items-center bg-light rounded-circle">
                  <i class="fas fa-user text-secondary" style="font-size: 3rem;"></i>
                </div>
              </div>
              
              <h4 class="mb-1">{{ user.displayName || 'Sin nombre' }}</h4>
              <p class="text-muted">{{ user.email }}</p>
              
              <div class="d-flex justify-content-center mt-3">
                <span class="badge bg-primary me-2">{{ getRoleName(user.role) }}</span>
                <span class="badge" :class="user.isActive ? 'bg-success' : 'bg-danger'">
                  {{ user.isActive ? 'Activo' : 'Inactivo' }}
                </span>
              </div>
            </div>
          </div>
          
          <div class="card shadow-sm mt-4">
            <div class="card-header">
              <h5 class="card-title mb-0">Acciones</h5>
            </div>
            <div class="card-body">
              <div class="d-grid gap-2">
                <button 
                  class="btn btn-outline-primary" 
                  @click="toggleUserStatus"
                  :disabled="statusUpdating"
                >
                  <i class="fas" :class="user.isActive ? 'fa-user-slash' : 'fa-user-check'"></i>
                  {{ user.isActive ? 'Desactivar usuario' : 'Activar usuario' }}
                </button>
                
                <button 
                  class="btn btn-outline-secondary" 
                  @click="resetPassword"
                  :disabled="passwordResetting"
                >
                  <i class="fas fa-key me-2"></i>Enviar correo de restablecimiento
                </button>
                
                <button 
                  v-if="user.role !== 'admin'" 
                  class="btn btn-outline-warning d-flex align-items-center"
                  @click="updateRole('admin')"
                  :disabled="roleUpdating"
                  style="min-width: 220px; justify-content: center;"
                >
                  <div class="icon-wrapper me-2" style="background-color: rgba(245, 158, 11, 0.1); padding: 6px; border-radius: 6px;">
                    <i class="fas fa-user-shield" style="color: var(--warning);"></i>
                  </div>
                  Promover a administrador
                </button>
                
                <button 
                  v-if="user.role === 'admin'" 
                  class="btn btn-outline-warning d-flex align-items-center"
                  @click="updateRole('user')"
                  :disabled="roleUpdating"
                  style="min-width: 220px; justify-content: center;"
                >
                  <div class="icon-wrapper me-2" style="background-color: rgba(245, 158, 11, 0.1); padding: 6px; border-radius: 6px;">
                    <i class="fas fa-user" style="color: var(--warning);"></i>
                  </div>
                  Degradar a usuario normal
                </button>
                
                <button 
                  v-if="user.role === 'user'" 
                  class="btn btn-outline-info d-flex align-items-center"
                  @click="updateRole('premium')"
                  :disabled="roleUpdating"
                  style="min-width: 220px; justify-content: center;"
                >
                  <div class="icon-wrapper me-2" style="background-color: rgba(59, 130, 246, 0.1); padding: 6px; border-radius: 6px;">
                    <i class="fas fa-crown" style="color: var(--info);"></i>
                  </div>
                  Convertir en usuario premium
                </button>
                
                <button 
                  v-if="user.role === 'premium'" 
                  class="btn btn-outline-info d-flex align-items-center"
                  @click="updateRole('user')"
                  :disabled="roleUpdating"
                  style="min-width: 220px; justify-content: center;"
                >
                  <div class="icon-wrapper me-2" style="background-color: rgba(59, 130, 246, 0.1); padding: 6px; border-radius: 6px;">
                    <i class="fas fa-user" style="color: var(--info);"></i>
                  </div>
                  Convertir en usuario normal
                </button>
              </div>
            </div>
          </div>
        </div>
        
        <div class="col-md-8">
          <!-- Estadísticas del usuario -->
          <div class="card shadow-sm mb-4">
            <div class="card-header">
              <h5 class="card-title mb-0">Estadísticas</h5>
            </div>
            <div class="card-body">
              <div class="row g-4">
                <div class="col-md-4">
                  <div class="stat-item text-center">
                    <div class="stat-value display-6">{{ userStats.totalCards || 0 }}</div>
                    <div class="stat-label text-muted">Cartas coleccionadas</div>
                  </div>
                </div>
                
                <div class="col-md-4">
                  <div class="stat-item text-center">
                    <div class="stat-value display-6">{{ userStats.packsOpened || 0 }}</div>
                    <div class="stat-label text-muted">Sobres abiertos</div>
                  </div>
                </div>
                
                <div class="col-md-4">
                  <div class="stat-item text-center">
                    <div class="stat-value display-6">{{ userStats.loginCount || 0 }}</div>
                    <div class="stat-label text-muted">Inicios de sesión</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Información de la cuenta -->
          <div class="card shadow-sm mb-4">
            <div class="card-header">
              <h5 class="card-title mb-0">Información de la cuenta</h5>
            </div>
            <div class="card-body">
              <div class="row mb-3">
                <div class="col-md-4 fw-bold">ID de usuario:</div>
                <div class="col-md-8">
                  <code>{{ user.id }}</code>
                </div>
              </div>
              
              <div class="row mb-3">
                <div class="col-md-4 fw-bold">Fecha de registro:</div>
                <div class="col-md-8">
                  {{ formatDate(user.createdAt) }}
                </div>
              </div>
              
              <div class="row mb-3">
                <div class="col-md-4 fw-bold">Último acceso:</div>
                <div class="col-md-8">
                  {{ formatDate(user.lastLogin) }}
                </div>
              </div>
              
              <div class="row mb-3">
                <div class="col-md-4 fw-bold">Método de autenticación:</div>
                <div class="col-md-8">
                  {{ getAuthMethod(user.authProvider) }}
                </div>
              </div>
              
              <div class="row mb-3">
                <div class="col-md-4 fw-bold">Monedas:</div>
                <div class="col-md-8">
                  {{ user.coins || 0 }} <i class="fas fa-coins text-warning"></i>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Historial de actividad -->
          <div class="card shadow-sm">
            <div class="card-header d-flex justify-content-between align-items-center">
              <h5 class="card-title mb-0">Historial de actividad</h5>
              <button class="btn btn-sm btn-outline-primary" @click="loadActivity">
                <i class="fas fa-sync-alt me-1"></i> Actualizar
              </button>
            </div>
            <div class="card-body p-0">
              <div v-if="activityLoading" class="text-center py-4">
                <div class="spinner-border spinner-border-sm text-primary" role="status">
                  <span class="visually-hidden">Cargando...</span>
                </div>
              </div>
              <div v-else-if="activityError" class="alert alert-danger m-3">
                {{ activityError }}
              </div>
              <div v-else-if="!userActivity || userActivity.length === 0" class="text-center py-4 text-muted">
                No hay actividad registrada
              </div>
              <div v-else>
                <ul class="list-group list-group-flush">
                  <li v-for="(activity, index) in userActivity" :key="index" class="list-group-item">
                    <div class="d-flex justify-content-between align-items-start">
                      <div>
                        <div class="fw-bold">{{ getActivityTitle(activity) }}</div>
                        <small class="text-muted">{{ activity.details }}</small>
                      </div>
                      <small class="text-muted">{{ formatDate(activity.timestamp) }}</small>
                    </div>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState, mapActions } from 'vuex'
import { getAuth, sendPasswordResetEmail } from 'firebase/auth'

export default {
  name: 'UserDetail',
  data() {
    return {
      loading: true,
      error: null,
      user: null,
      userStats: {},
      userActivity: [],
      activityLoading: false,
      activityError: null,
      statusUpdating: false,
      roleUpdating: false,
      passwordResetting: false
    }
  },
  computed: {
    ...mapState(['users']),
    userId() {
      return this.$route.params.id
    }
  },
  created() {
    this.loadUser()
  },
  methods: {
    ...mapActions(['fetchUsers', 'updateUserStatus', 'updateUserRole']),
    
    async loadUser() {
      this.loading = true
      this.error = null
      
      try {
        // Si no hay usuarios cargados, los cargamos
        if (!this.users || this.users.length === 0) {
          await this.fetchUsers()
        }
        
        // Buscamos el usuario por ID
        this.user = this.users.find(u => u.id === this.userId)
        
        if (this.user) {
          // Cargamos estadísticas y actividad
          this.loadUserStats()
          this.loadActivity()
        } else {
          console.warn('Usuario no encontrado con ID:', this.userId)
        }
      } catch (error) {
        console.error('Error al cargar el usuario:', error)
        this.error = 'No se pudo cargar la información del usuario. Por favor, inténtalo de nuevo.'
      } finally {
        this.loading = false
      }
    },
    
    async loadUserStats() {
      // Simulación de carga de estadísticas
      // En una implementación real, esto vendría de Firestore
      this.userStats = {
        totalCards: Math.floor(Math.random() * 100),
        packsOpened: Math.floor(Math.random() * 30),
        loginCount: Math.floor(Math.random() * 50) + 1
      }
    },
    
    async loadActivity() {
      this.activityLoading = true
      this.activityError = null
      
      try {
        // Simulación de carga de actividad
        // En una implementación real, esto vendría de Firestore
        setTimeout(() => {
          const activities = [
            {
              type: 'login',
              timestamp: new Date(Date.now() - 1000 * 60 * 60 * 2),
              details: 'Inicio de sesión desde la aplicación móvil'
            },
            {
              type: 'pack_open',
              timestamp: new Date(Date.now() - 1000 * 60 * 60 * 24),
              details: 'Abrió un sobre Premium'
            },
            {
              type: 'card_collect',
              timestamp: new Date(Date.now() - 1000 * 60 * 60 * 24 * 2),
              details: 'Obtuvo la carta "Goku Ultra Instinto"'
            },
            {
              type: 'purchase',
              timestamp: new Date(Date.now() - 1000 * 60 * 60 * 24 * 3),
              details: 'Compró 500 monedas'
            }
          ]
          
          this.userActivity = activities
          this.activityLoading = false
        }, 800)
      } catch (error) {
        console.error('Error al cargar la actividad:', error)
        this.activityError = 'No se pudo cargar el historial de actividad.'
        this.activityLoading = false
      }
    },
    
    async toggleUserStatus() {
      if (!this.user) return
      
      this.statusUpdating = true
      
      try {
        await this.updateUserStatus({
          userId: this.user.id,
          isActive: !this.user.isActive
        })
        
        // Actualizamos el usuario local
        this.user.isActive = !this.user.isActive
      } catch (error) {
        console.error('Error al actualizar el estado del usuario:', error)
        alert('No se pudo actualizar el estado del usuario. Por favor, inténtalo de nuevo.')
      } finally {
        this.statusUpdating = false
      }
    },
    
    async updateRole(newRole) {
      if (!this.user) return
      
      this.roleUpdating = true
      
      try {
        await this.updateUserRole({
          userId: this.user.id,
          role: newRole
        })
        
        // Actualizamos el usuario local
        this.user.role = newRole
      } catch (error) {
        console.error('Error al actualizar el rol del usuario:', error)
        alert('No se pudo actualizar el rol del usuario. Por favor, inténtalo de nuevo.')
      } finally {
        this.roleUpdating = false
      }
    },
    
    async resetPassword() {
      if (!this.user || !this.user.email) return
      
      this.passwordResetting = true
      
      try {
        const auth = getAuth()
        await sendPasswordResetEmail(auth, this.user.email)
        alert(`Se ha enviado un correo de restablecimiento de contraseña a ${this.user.email}`)
      } catch (error) {
        console.error('Error al enviar correo de restablecimiento:', error)
        alert('No se pudo enviar el correo de restablecimiento. Por favor, inténtalo de nuevo.')
      } finally {
        this.passwordResetting = false
      }
    },
    
    getRoleName(role) {
      const roles = {
        'user': 'Usuario',
        'premium': 'Premium',
        'admin': 'Administrador'
      }
      return roles[role] || 'Desconocido'
    },
    
    getAuthMethod(provider) {
      const providers = {
        'password': 'Email y contraseña',
        'google.com': 'Google',
        'facebook.com': 'Facebook',
        'apple.com': 'Apple'
      }
      return providers[provider] || 'Desconocido'
    },
    
    getActivityTitle(activity) {
      const titles = {
        'login': 'Inicio de sesión',
        'logout': 'Cierre de sesión',
        'pack_open': 'Apertura de sobre',
        'card_collect': 'Carta obtenida',
        'purchase': 'Compra realizada',
        'profile_update': 'Perfil actualizado'
      }
      return titles[activity.type] || 'Actividad'
    },
    
    formatDate(timestamp) {
      if (!timestamp) return 'N/A'
      
      const date = timestamp instanceof Date ? timestamp : new Date(timestamp)
      return new Intl.DateTimeFormat('es-ES', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      }).format(date)
    }
  }
}
</script>

<style scoped>
.avatar-container {
  width: 120px;
  height: 120px;
  margin: 0 auto;
}

.avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.avatar-placeholder {
  width: 100%;
  height: 100%;
  border-radius: 50%;
}

.stat-item {
  padding: 1rem;
  border-radius: 0.5rem;
  background-color: rgba(0, 0, 0, 0.02);
}
</style>