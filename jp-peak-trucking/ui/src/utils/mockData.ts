import type { KeyBinds, Language, Mission, PlayerData, Truck, XpTable } from '../types/trucking'

export const mockLanguage: Language = {
  transportation_stage: '輸送ステージ',
  trailer_quality: 'トレーラー状態',
  truck_fuel: '燃料',
  detach_trailer: 'トレーラーを切り離す',
  mark_location: '地点をマーク',
  nts_main: 'NTS メイン',
  companies: '企業',
  leaderboard: 'ランキング',
  profile: 'プロフィール',
  unlocked: '解放済み',
  locked: 'ロック',
  trust_point: '信頼ポイント',
  select_route: 'ルートを選択',
  select_mission: 'ミッション選択',
  daily_missions: 'デイリーミッション',
  hour: '時間',
  completed: '完了',
  not_completed: '未完了',
  select_truck: 'トラックを選択',
  get_ready: '輸送の準備をしてください',
  select_your_truck: 'トラックを選んでください',
  select_mission_and_route: 'ミッションとルートを選択',
  start_the_job: '仕事を開始',
  stop_job: '仕事を中止',
  start_job: '仕事を開始',
  completed_jobs: '完了した仕事',
  total_missions_completed: 'NTSで完了したミッションの合計です。',
  total_earnings: '累計収入',
  total_earnings_desc: '完了したルートで稼いだ金額の合計です。',
  current_level: '現在のレベル',
  latest_works: '最近の仕事',
  earned: '獲得',
  not_enough_points: '信頼ポイントが足りません！',
  level_required: 'レベル %s が必要です',
  select_all_first: 'ミッション・ルート・トラックを先に選択してください。',
  dispatch_board: '配車ボード',
  no_route_selected: 'ルート未選択',
  routes_count: '%s ルート',
  nts_company: '国立転送・保管（NTS）',
  available_freight: '利用可能な貨物',
  route_options: 'ルート一覧',
  extra_payment: '追加報酬 +$%s',
  standard_payment: '通常報酬',
  choose_equipment: '車両を選択',
  trust_required: '信頼 %s',
  company_trust: '企業の信頼',
  driver: 'ドライバー',
  xp_until_next: '次のレベルまで %s XP',
  leaderboard_level: 'レベル %s',
  unknown_caller: '非通知',
  special_freight_call: '特別貨物の依頼',
  phone_accept_decline: 'Y 受ける / N 断る',
}

export const mockKeyBinds: KeyBinds = {
  mark_location: { label: 'G', key: 133 },
}

export const mockXp: XpTable = Array.from({ length: 100 }, (_, index) => (index + 1) * 1000)

export const mockTrucks: Truck[] = [
  { name: 'packer', image: 'truck-1.png', label: 'パッカー', level: 1 },
  { name: 'hauler', image: 'truck-2.png', label: 'ホーラー', level: 5 },
  { name: 'phantom3', image: 'truck-3.png', label: 'ファントム・クラシック', level: 10 },
  { name: 'mule3', image: 'truck-4.png', label: '装甲ミュール', level: 15 },
]

export const mockMissions: Mission[] = [
  {
    id: 1,
    image: 'map_1.png',
    small_image: 'map_1_small.png',
    header: 'パレト森林・サムウィル木材',
    companyIndex: 0,
    payment: 2500,
    reqPoint: 10,
    routes: [
      { label: 'LSドック → パレト', vehicle: ['hauler', 'packer', 'phantom3'], extraPayment: 0 },
      { label: 'グレープシード → パレト', vehicle: ['hauler', 'packer'], reqPoint: 5, extraPayment: 250 },
    ],
    requirementsLabel: [
      { label: '木材輸送', icon: 'supply-icon.svg' },
      { label: '報酬 $2,500', icon: 'profit-icon.svg' },
      { label: '異なるルート 2本', icon: 'route-icon.svg' },
      { label: '企業信頼 +1', icon: 'trust-icon.svg' },
    ],
  },
  {
    id: 2,
    image: 'map_2.png',
    small_image: 'map_2_small.png',
    header: 'Fame or Shame テレビ機材',
    companyIndex: 1,
    payment: 4200,
    reqPoint: 12,
    routes: [
      { label: 'LSドック → リチャード・マジェスティック', vehicle: ['packer', 'phantom3'], extraPayment: 350 },
      { label: 'グレープシード → パレト', vehicle: ['mule3', 'packer'], reqPoint: 3 },
    ],
    requirementsLabel: [
      { label: '梱包資材輸送', icon: 'supply-icon.svg' },
      { label: '報酬 $4,200', icon: 'profit-icon.svg' },
      { label: '異なるルート 2本', icon: 'route-icon.svg' },
      { label: '企業信頼 +1', icon: 'trust-icon.svg' },
    ],
  },
]

export const mockPlayerData: PlayerData = {
  name: '山田 太郎',
  avatar: './assets/images/test-pp.png',
  level: 12,
  xp: 3200,
  totalEarnings: 85600,
  completedJobs: 28,
  unlockedMissions: { '1': true, '2': true },
  points: { '0': 14, '1': 7, '2': 3, '3': 5, '4': 1, '5': 0, '6': 0, '7': 0 },
  dailymissions: {
    resetAt: Math.floor(Date.now() / 1000) + 21600,
    data: {
      complete_mission: { header: 'ミッションを1件完了', label: '配送を1件完了する。', max: 1, process: 0, xp: 2500 },
      on_the_roads: { header: '路上で働く', label: '合計30分間、貨物を輸送する。', max: 30, process: 18, xp: 2500 },
    },
  },
  history: [
    { label: 'パレト森林・サムウィル木材', supply: '木材輸送', earn: 2500, date: Math.floor(Date.now() / 1000) - 86400 },
    { label: 'Fame or Shame テレビ機材', supply: '梱包資材輸送', earn: 4200, date: Math.floor(Date.now() / 1000) - 172800 },
  ],
}
