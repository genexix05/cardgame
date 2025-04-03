// Utilidades para la autenticación
import { getAuth, onAuthStateChanged } from 'firebase/auth'
import { ref } from 'vue'

// Estado reactivo para el usuario actual
export const currentUser = ref(null)

// Función para verificar si el usuario está autenticado
export function useAuth() {
  const auth = getAuth()
  
  // Actualizar el estado del usuario cuando cambie
  onAuthStateChanged(auth, (user) => {
    currentUser.value = user
  })
  
  // Verificar si el usuario está autenticado
  const isAuthenticated = () => {
    return currentUser.value !== null
  }
  
  // Obtener el ID del usuario actual
  const getUserId = () => {
    return currentUser.value ? currentUser.value.uid : null
  }
  
  // Obtener el email del usuario actual
  const getUserEmail = () => {
    return currentUser.value ? currentUser.value.email : null
  }
  
  return {
    currentUser,
    isAuthenticated,
    getUserId,
    getUserEmail
  }
}