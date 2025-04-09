import { createRouter, createWebHistory } from 'vue-router'
import { useStore } from 'vuex'

// Componentes de página
const Login = () => import('../views/Login.vue')
const Dashboard = () => import('../views/Dashboard.vue')
const Cards = () => import('../views/Cards.vue')
const CardEditor = () => import('../views/CardEditor.vue')
const Packs = () => import('../views/Packs.vue')
const PackEditor = () => import('../views/PackEditor.vue')
const Users = () => import('../views/Users.vue')
const UserDetail = () => import('../views/UserDetail.vue')
const Categories = () => import('../views/Categories.vue')

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: Login,
    meta: { requiresAuth: false }
  },
  {
    path: '/',
    redirect: '/dashboard'
  },
  {
    path: '/dashboard',
    name: 'Dashboard',
    component: Dashboard,
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/cards',
    name: 'Cards',
    component: Cards,
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/cards/new',
    name: 'NewCard',
    component: CardEditor,
    meta: { requiresAuth: true }
  },
  {
    path: '/cards/edit/:id',
    name: 'EditCard',
    component: CardEditor,
    meta: { requiresAuth: true }
  },
  {
    path: '/packs',
    name: 'Packs',
    component: Packs,
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/packs/new',
    name: 'NewPack',
    component: PackEditor,
    meta: { requiresAuth: true }
  },
  {
    path: '/packs/edit/:id',
    name: 'EditPack',
    component: PackEditor,
    meta: { requiresAuth: true }
  },
  {
    path: '/users',
    name: 'Users',
    component: Users,
    meta: { requiresAuth: true, requiresAdmin: true }
  },
  {
    path: '/users/:id',
    name: 'UserDetail',
    component: UserDetail,
    meta: { requiresAuth: true }
  },
  {
    path: '/categories',
    name: 'Categories',
    component: Categories,
    meta: {
      requiresAuth: true
    }
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/'
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// Guardia de navegación
router.beforeEach(async (to, from, next) => {
  const store = useStore()
  
  // Verificar autenticación
  if (to.meta.requiresAuth) {
    // Si no está verificado el estado de autenticación, esperar
    if (store.state.auth.loading) {
      await store.dispatch('auth/checkAuth')
    }
    
    // Si no está autenticado, redirigir a login
    if (!store.getters['auth/isAuthenticated']) {
      next({ name: 'Login', query: { redirect: to.fullPath } })
      return
    }
    
    // Si requiere admin y no es admin, redirigir a login
    if (to.meta.requiresAdmin && !store.getters['auth/isAdmin']) {
      next({ name: 'Login', query: { redirect: to.fullPath } })
      return
    }
  }
  
  // Si está autenticado y va a login, redirigir a dashboard
  if (to.name === 'Login' && store.getters['auth/isAuthenticated']) {
    next('/')
    return
  }
  
  next()
})

export default router