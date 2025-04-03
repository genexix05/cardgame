import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import store from './store'

import 'bootstrap/dist/css/bootstrap.min.css'
import 'bootstrap/dist/js/bootstrap.bundle.min.js'
import './assets/css/admin-theme.css' // Importamos los nuevos estilos personalizados

// Importamos la configuración de Firebase desde el archivo centralizado
import './firebase'

// Crear la aplicación Vue
createApp(App)
  .use(store)
  .use(router)
  .mount('#app')