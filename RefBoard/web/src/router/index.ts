import { createRouter, createWebHashHistory } from 'vue-router'
import Launcher from '../views/Launcher.vue'
import MainLayout from '../views/MainLayout.vue'
import MatchList from '../views/MatchList.vue'
import MatchDetail from '../views/MatchDetail.vue'
import TeamManage from '../views/TeamManage.vue'
import DataManage from '../views/DataManage.vue'
import Settings from '../views/Settings.vue'

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
        { path: 'teams', name: 'teams', component: TeamManage },
        { path: 'data', name: 'data', component: DataManage },
        { path: 'settings', name: 'settings', component: Settings },
      ],
    },
  ],
})
