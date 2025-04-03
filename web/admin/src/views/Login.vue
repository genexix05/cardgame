<template>
  <div class="login-container d-flex justify-content-center align-items-center">
    <div class="login-card card">
      <div class="card-body p-5">
        <div class="text-center mb-5">
          <div class="icon-container mb-3" style="background-color: rgba(79, 70, 229, 0.1); width: 80px; height: 80px; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto;">
            <i class="fas fa-dragon" style="font-size: 40px; color: var(--primary);"></i>
          </div>
          <h2 class="fw-bold">Panel de Administración</h2>
          <p class="text-muted">Dragon Ball Card Game</p>
        </div>

        <form @submit.prevent="login">
          <div class="mb-4">
            <label for="email" class="form-label">Correo electrónico</label>
            <div class="input-group">
              <span class="input-group-text" style="background-color: transparent;">
                <i class="fas fa-envelope text-muted"></i>
              </span>
              <input
                type="email"
                class="form-control ps-2"
                id="email"
                v-model="email"
                placeholder="admin@example.com"
                required
              />
            </div>
          </div>
          <div class="mb-5">
            <label for="password" class="form-label">Contraseña</label>
            <div class="input-group">
              <span class="input-group-text" style="background-color: transparent;">
                <i class="fas fa-lock text-muted"></i>
              </span>
              <input
                type="password"
                class="form-control ps-2"
                id="password"
                v-model="password"
                placeholder="••••••••"
                required
              />
            </div>
          </div>
          <div class="d-grid">
            <button 
              type="submit" 
              class="btn btn-primary btn-lg py-3" 
              :disabled="loading"
            >
              <span v-if="loading" class="spinner-border spinner-border-sm me-2" role="status"></span>
              Iniciar sesión
            </button>
          </div>
        </form>

        <div class="alert alert-danger mt-3" v-if="error">
          {{ error }}
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue';
import { getAuth, signInWithEmailAndPassword } from 'firebase/auth';
import { useRouter } from 'vue-router';

export default {
  name: 'LoginView',
  setup() {
    const email = ref('');
    const password = ref('');
    const error = ref('');
    const loading = ref(false);
    const router = useRouter();

    const login = async () => {
      loading.value = true;
      error.value = '';
      
      try {
        const auth = getAuth();
        await signInWithEmailAndPassword(auth, email.value, password.value);
        router.push('/dashboard');
      } catch (e) {
        console.error('Error de inicio de sesión:', e);
        
        // Mensajes de error personalizados
        if (e.code === 'auth/invalid-credential') {
          error.value = 'Credenciales inválidas. Verifica tu correo y contraseña.';
        } else if (e.code === 'auth/user-not-found') {
          error.value = 'Usuario no encontrado. Verifica tu correo electrónico.';
        } else if (e.code === 'auth/wrong-password') {
          error.value = 'Contraseña incorrecta. Inténtalo de nuevo.';
        } else {
          error.value = 'Error al iniciar sesión. Por favor, inténtalo de nuevo.';
        }
      } finally {
        loading.value = false;
      }
    };

    return {
      email,
      password,
      login,
      error,
      loading
    };
  }
};
</script>

<style scoped>
.login-container {
  min-height: 100vh;
  background-color: #f5f5f5;
}

.login-card {
  width: 100%;
  max-width: 420px;
  border-radius: 1rem;
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
</style>