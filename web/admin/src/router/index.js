import { createRouter, createWebHistory } from 'vue-router'
import { getAuth } from 'firebase/auth'

// Componentes de página
const Login = () => import('../views/Login.vue')
const Dashboard = () => import('../views/Dashboard.vue')
const Cards = () => import('../views/Cards.vue')
const CardEditor = () => import('../views/CardEditor.vue')
const Packs = () => import('../views/Packs.vue')
const PackEditor = () => import('../views/PackEditor.vue')
const Users = () => import('../views/Users.vue')
const UserDetail = () => import('../views/UserDetail.vue')

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
    meta: { requiresAuth: true }
  },
  {
    path: '/cards',
    name: 'Cards',
    component: Cards,
    meta: { requiresAuth: true }
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
    meta: { requiresAuth: true }
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
    meta: { requiresAuth: true }
  },
  {
    path: '/users/:id',
    name: 'UserDetail',
    component: UserDetail,
    meta: { requiresAuth: true }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// Navegación protegida
router.beforeEach((to, from, next) => {
  const requiresAuth = to.matched.some(record => record.meta.requiresAuth)
  const auth = getAuth()
  
  if (requiresAuth && !auth.currentUser) {
    next('/login')
  } else if (to.path === '/login' && auth.currentUser) {
    next('/dashboard')
  } else {
    next()
  }
})

export default router