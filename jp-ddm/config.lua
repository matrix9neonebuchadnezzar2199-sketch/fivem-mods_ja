-- jp-DDM 共有設定（クライアントのみ読み込み）
-- 全項目に日本語コメント（運営が座標等を触る想定のため）

Config = {}

-- チャットコマンド（/ddm = 管理画面、/ddmstop = 停止）
Config.OpenCommand = 'ddm'
Config.StopCommand = 'ddmstop'

-- 本番（最小化）中: 再びマウスで管理する＝F12 または /ddm
-- キーは GTA5 設定の「キーボード＞五体（Custom）」で **jp-ddm 用** として差し替え可（ここはデフォルト）
Config.ReopenManagerKey = 'F12'

-- セットリスト1プリセットあたりの最大ステップ数
Config.MaxSlots = 64
-- カタログから追加したときのデフォルト秒数
Config.DefaultDuration = 10

-- 左ペイン「カタログ」に出すアニメ一覧（name / category / dict / clip / 初期秒数）
-- category: dance | emote | pose | other
Config.Catalog = {
    { name = 'ダンス（クラブ男性）', category = 'dance', dict = 'anim@amb@nightclub@dancers@podium_dancers@', clip = 'hi_dance_facedj_17_v2_male^5', defaultDuration = 15 },
    { name = 'エアギター',           category = 'emote', dict = 'anim@mp_player_intcelebrationfemale@air_guitar', clip = 'air_guitar',                defaultDuration = 8  },
    { name = 'ダンス（激しい女性）', category = 'dance', dict = 'anim@amb@nightclub@mini@dance@dance_solo@female@var_a@', clip = 'high_center',  defaultDuration = 20 },
    { name = '待機ポーズ（男性）',  category = 'pose',  dict = 'anim@heists@heist_corona@team_idles@male_a',       clip = 'idle',            defaultDuration = 5  },
    { name = 'ダンス（アゲ男性）',  category = 'dance', dict = 'anim@amb@nightclub@mini@dance@dance_solo@male@var_b@', clip = 'high_center_up',  defaultDuration = 25 },
    { name = 'お辞儀',             category = 'emote', dict = 'anim@mp_player_intcelebrationfemale@curtsy',          clip = 'curtsy', defaultDuration = 5  },
    { name = 'ダンス（ゆったり）',  category = 'dance', dict = 'anim@amb@nightclub@mini@dance@dance_solo@male@var_b@', clip = 'low_center', defaultDuration = 30 },
    { name = '投げキッス',         category = 'emote', dict = 'anim@mp_player_intcelebrationfemale@blow_kiss',       clip = 'blow_kiss', defaultDuration = 7  },
    { name = '拍手',               category = 'emote', dict = 'anim@mp_player_intupperair_guitar',                 clip = 'mp_air_guitar',   defaultDuration = 6  },
    { name = 'ポーズ B',           category = 'pose',  dict = 'anim@amb@nightclub@peds@',                        clip = 'rcmme_amanda1_stand_loop_cop', defaultDuration = 3 },
    { name = 'ダンス ソロ（女性）', category = 'dance', dict = 'anim@amb@nightclub@dancers@solomun@',             clip = 'mi_dance_facedj_17_v1_female^1', defaultDuration = 12 },
}

-- デバッグログ（F8）
Config.Debug = false
