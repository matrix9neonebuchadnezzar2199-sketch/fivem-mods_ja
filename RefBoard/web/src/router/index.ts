import { createRouter, createWebHashHistory } from 'vue-router'
import Launcher from '../views/Launcher.vue'
import MainLayout from '../views/MainLayout.vue'
import MatchList from '../views/MatchList.vue'
import MatchDetail from '../views/MatchDetail.vue'

export const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    { path: '/', name: 'launcher', component: Launcher },
    {
      path: '/workspace',
      component: MainLayout,
      children: [
        { path: '', redirect: { name: 'matches' } },
        { path: 'matches', name: 'matches', component: MatchList },
        { path: 'matches/:id', name: 'match-detail', component: MatchDetail, props: true },
      ],
    },
  ],
})
