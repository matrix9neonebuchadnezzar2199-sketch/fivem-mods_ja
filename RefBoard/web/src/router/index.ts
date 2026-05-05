import { createRouter, createWebHashHistory } from 'vue-router'
import Launcher from '../views/Launcher.vue'
import MainLayout from '../views/MainLayout.vue'

export const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: '/', name: 'launcher', component: Launcher },
    { path: '/main', name: 'main', component: MainLayout },
  ],
})
