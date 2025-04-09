<template>
  <div class="min-h-screen bg-gradient-to-br from-gray-900 to-gray-800 flex items-center justify-center p-4">
    <div class="w-full max-w-md">
      <!-- Logo y título -->
      <div class="text-center mb-8">
        <img 
          src="../assets/logo.png" 
          alt="Logo" 
          class="h-16 mx-auto mb-4"
          @error="$event.target.src = '/assets/logo-placeholder.png'"
        >
        <h1 class="text-3xl font-bold text-white mb-2">Panel de Administración</h1>
        <p class="text-gray-400">Inicia sesión para acceder al panel</p>
      </div>

      <!-- Formulario de login -->
      <div class="bg-white rounded-xl shadow-2xl p-8">
        <form @submit.prevent="login" class="space-y-6">
          <!-- Mensaje de error -->
          <div v-if="error" class="bg-red-50 border-l-4 border-red-500 p-4 rounded">
            <div class="flex">
              <div class="flex-shrink-0">
                <i class="fas fa-exclamation-circle text-red-500"></i>
              </div>
              <div class="ml-3">
                <p class="text-sm text-red-700">{{ error }}</p>
              </div>
            </div>
          </div>

          <!-- Email -->
          <div>
            <label for="email" class="block text-sm font-medium text-gray-700 mb-1">
              Correo electrónico
            </label>
            <div class="relative">
              <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <i class="fas fa-envelope text-gray-400"></i>
              </div>
              <input
                id="email"
                type="email"
                v-model="email"
                class="form-input pl-10"
                placeholder="tu@email.com"
                required
                :disabled="loading"
              >
            </div>
          </div>

          <!-- Contraseña -->
          <div>
            <label for="password" class="block text-sm font-medium text-gray-700 mb-1">
              Contraseña
            </label>
            <div class="relative">
              <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <i class="fas fa-lock text-gray-400"></i>
              </div>
              <input
                id="password"
                type="password"
                v-model="password"
                class="form-input pl-10"
                placeholder="••••••••"
                required
                :disabled="loading"
              >
              <button
                type="button"
                class="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-500"
                @click="togglePasswordVisibility"
              >
                <i :class="showPassword ? 'fas fa-eye-slash' : 'fas fa-eye'"></i>
              </button>
            </div>
          </div>

          <!-- Recordar sesión -->
          <div class="flex items-center justify-between">
            <div class="flex items-center">
              <input
                id="remember"
                type="checkbox"
                v-model="rememberMe"
                class="h-4 w-4 text-primary focus:ring-primary border-gray-300 rounded"
                :disabled="loading"
              >
              <label for="remember" class="ml-2 block text-sm text-gray-700">
                Recordar sesión
              </label>
            </div>
            <a href="#" class="text-sm text-primary hover:text-primary-dark">
              ¿Olvidaste tu contraseña?
            </a>
          </div>

          <!-- Botón de login -->
          <button
            type="submit"
            class="btn-login w-full"
            :disabled="loading"
          >
            <span v-if="loading" class="animate-spin mr-2">⌛</span>
            {{ loading ? 'Iniciando sesión...' : 'Iniciar sesión' }}
          </button>
        </form>
      </div>

      <!-- Footer -->
      <div class="mt-8 text-center">
        <p class="text-gray-400 text-sm">
          © {{ new Date().getFullYear() }} Card Game. Todos los derechos reservados.
        </p>
      </div>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';

export default {
  name: 'LoginView',
  setup() {
    const store = useStore();
    const router = useRouter();
    
    const email = ref('');
    const password = ref('');
    const rememberMe = ref(false);
    const loading = ref(false);
    const error = ref(null);
    const showPassword = ref(false);
    
    const togglePasswordVisibility = () => {
      showPassword.value = !showPassword.value;
      const passwordInput = document.getElementById('password');
      if (passwordInput) {
        passwordInput.type = showPassword.value ? 'text' : 'password';
      }
    };
    
    const login = async () => {
      if (!email.value || !password.value) {
        error.value = 'Por favor, completa todos los campos';
        return;
      }
      
      loading.value = true;
      error.value = null;
      
      try {
        await store.dispatch('auth/login', {
          email: email.value,
          password: password.value,
          remember: rememberMe.value
        });
        
        const redirect = router.currentRoute.value.query.redirect || '/';
        router.push(redirect);
      } catch (err) {
        console.error('Error al iniciar sesión:', err);
        error.value = err.message || 'Error al iniciar sesión. Por favor, intenta nuevamente.';
      } finally {
        loading.value = false;
      }
    };
    
    return {
      email,
      password,
      rememberMe,
      loading,
      error,
      showPassword,
      login,
      togglePasswordVisibility
    };
  }
};
</script>

<style scoped>
.form-input {
  @apply w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 
         focus:ring-primary focus:border-primary transition-all;
}

.btn-login {
  @apply px-4 py-3 bg-gradient-to-r from-primary to-primary-dark text-white 
         rounded-lg font-medium hover:from-primary-dark hover:to-primary 
         transition-all duration-300 disabled:opacity-50 disabled:cursor-not-allowed
         flex items-center justify-center;
}

/* Animación de fondo */
.bg-gradient-to-br {
  background-size: 400% 400%;
  animation: gradient 15s ease infinite;
}

@keyframes gradient {
  0% {
    background-position: 0% 50%;
  }
  50% {
    background-position: 100% 50%;
  }
  100% {
    background-position: 0% 50%;
  }
}
</style>