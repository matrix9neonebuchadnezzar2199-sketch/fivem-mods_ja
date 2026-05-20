Locales = {}

local currentLocale = 'ja'

local translations = {
    en = {
        ['open_menu']                = 'PRESS E TO OPEN MENU',
        ['load_box']                 = 'E - Load Box',
        ['take_box']                 = 'E - Take Box',
        ['deliver']                  = 'E - Deliver',
        ['finish_job']               = 'E - Finish Job',
        ['take_illegal']             = 'E - Take Illegal Job',
        ['go_to_pickup']             = 'Go to the pickup point and load the goods.',
        ['box_progress']             = 'Cargo Progress',
        ['get_trailer']              = 'Get the trailer from the location marked on your map...',
        ['deliver_trailer']          = 'Deliver the trailer to the location marked on your map...',
        ['return_veh']               = 'Return the vehicle to finish job and get payment...',
        ['wait_call']                = 'Wait for the call...',
        ['get_ready']                = 'Get Ready For Transport!',
        ['cant_select_truck']        = "You can't select this truck in this mission!",
        ['mission_locked']           = 'Mission is locked!',
        ['not_enough_points']        = "You don't have enough points!",
        ['already_unlocked']         = 'This mission is already unlocked',
        ['you_charged']              = 'You were charged $%s for vehicle damage',
        ['not_enough_illegal_box']   = "You don't have enough illegal box. REQUIRED : 10",
        ['trailer_doesnt_match']     = "Trailer doesn't match!",
        ['in_vehicle']               = "You can't take the box in vehicle!",
        ['spawn_location_full']      = 'Spawn Locations are full!',
        ['leave_vehicle']            = 'Leave the vehicle!',
        ['stop_vehicle']             = 'Stop vehicle to deliver!',
        ['notaccessjob']             = "You don't have access to this job!",
        ['transportation_stage']     = 'Transportation Stage',
        ['trailer_quality']          = 'Trailer Quality',
        ['truck_fuel']               = 'Truck Fuel',
        ['detach_trailer']           = 'Detach Trailer',
        ['mark_location']            = 'Mark Location',
        ['nts_main']                 = 'NTS MAIN',
        ['companies']                = 'COMPANIES',
        ['leaderboard']              = 'LEADERBOARD',
        ['profile']                  = 'PROFILE',
        ['unlocked']                 = 'UNLOCKED',
        ['locked']                   = 'LOCKED',
        ['trust_point']              = 'Trust Point',
        ['select_route']             = 'Select A Route',
        ['select_mission']           = 'SELECT MISSION',
        ['daily_missions']           = 'Daily Missions',
        ['hour']                     = 'hr',
        ['completed']                = 'Completed',
        ['not_completed']            = 'Not Completed',
        ['select_truck']             = 'Select A Truck',
        ['select_your_truck']        = 'Select Your Truck!',
        ['select_mission_and_route'] = 'Select a mission and a route!',
        ['start_the_job']            = 'Start the Job!',
        ['stop_job']                 = 'CANCEL JOB',
        ['start_job']                = 'START JOB',
        ['completed_jobs']           = 'Completed Jobs',
        ['total_missions_completed'] = 'Total missions completed on National Transfer & Storage Company.',
        ['total_earnings']           = 'Total Earnings',
        ['total_earnings_desc']      = 'Total money earned on National Transfer & Storage Company.',
        ['current_level']            = 'Current Level',
        ['latest_works']             = 'Latest Works',
        ['earned']                   = 'Earned',
        ['illegal_validation_failed'] = 'Illegal cargo verification failed.',
        ['must_have_job']            = 'You need an active trucker mission to deal with me.',
        ['already_illegal']          = 'You are already doing an illegal delivery or waiting for a call.',
        ['too_far']                  = 'You wandered too far, the deal is off.',
        ['edit_hud_hint']            = 'HUD Edit Mode: Drag to move. Press ESC or run /truckhud again to save.',
        ['level_required']           = 'Level %s required',
        ['select_all_first']         = 'Select a mission, route, and truck first.',
        ['xp_until_next']            = '%s XP until next level',
        ['driver']                   = 'Driver',
        ['dispatch_board']           = 'Dispatch board',
        ['no_route_selected']        = 'No route selected',
        ['routes_count']             = '%s routes',
        ['nts_company']              = 'National Transfer & Storage',
        ['available_freight']        = 'Available Freight',
        ['route_options']            = 'Route options',
        ['extra_payment']            = '+$%s bonus payment',
        ['standard_payment']         = 'Standard payment',
        ['choose_equipment']         = 'Choose equipment',
        ['trust_required']           = '%s trust',
        ['company_trust']            = 'Company trust',
        ['routes_payment']           = '%s routes / $%s',
        ['leaderboard_level']        = 'Level %s',
        ['unknown_caller']           = 'Unknown Caller',
        ['special_freight_call']     = 'Special freight request',
        ['phone_accept_decline']     = 'Y accept / N decline',
        ['talk_to_dealer']           = 'Talk to Dealer',
    },
    ja = {
        -- インタラクション
        ['open_menu']                = 'Eキーでメニューを開く',
        ['load_box']                 = 'E - 荷物を積む',
        ['take_box']                 = 'E - 荷物を受け取る',
        ['deliver']                  = 'E - 配達する',
        ['finish_job']               = 'E - 仕事を完了する',
        ['take_illegal']             = 'E - 闇仕事を受ける',
        ['go_to_pickup']             = '集荷地点へ行き、荷物を積み込んでください。',
        ['box_progress']             = '積載進捗',

        -- ジョブ進行
        ['get_trailer']              = 'マップの印からトレーラーを取得してください…',
        ['deliver_trailer']          = 'マップの印へトレーラーを届けてください…',
        ['return_veh']               = '車両を返却すると仕事が完了し、報酬を受け取れます…',
        ['wait_call']                = '連絡を待っています…',
        ['get_ready']                = '輸送の準備をしてください！',

        -- エラー・検証
        ['cant_select_truck']        = 'このミッションではこのトラックは選べません！',
        ['mission_locked']           = 'ミッションはロックされています！',
        ['not_enough_points']        = '信頼ポイントが足りません！',
        ['already_unlocked']         = 'このミッションはすでに解放済みです',
        ['you_charged']              = '車両損傷により $%s が請求されました',
        ['not_enough_illegal_box']   = '闇荷物の箱が足りません。必要数: 10',
        ['trailer_doesnt_match']     = 'トレーラーが一致しません！',
        ['in_vehicle']               = '車内では荷物を受け取れません！',
        ['spawn_location_full']      = 'スポーン地点がいっぱいです！',
        ['leave_vehicle']            = '車両から降りてください！',
        ['stop_vehicle']             = '配達するには車両を停止してください！',
        ['notaccessjob']             = 'この仕事を行う権限がありません！',

        -- UI
        ['transportation_stage']     = '輸送ステージ',
        ['trailer_quality']          = 'トレーラー状態',
        ['truck_fuel']               = '燃料',
        ['detach_trailer']           = 'トレーラーを切り離す',
        ['mark_location']            = '地点をマーク',
        ['nts_main']                 = 'NTS メイン',
        ['companies']                = '企業',
        ['leaderboard']              = 'ランキング',
        ['profile']                  = 'プロフィール',
        ['unlocked']                 = '解放済み',
        ['locked']                   = 'ロック',
        ['trust_point']              = '信頼ポイント',
        ['select_route']             = 'ルートを選択',
        ['select_mission']           = 'ミッション選択',
        ['daily_missions']           = 'デイリーミッション',
        ['hour']                     = '時間',
        ['completed']                = '完了',
        ['not_completed']            = '未完了',
        ['select_truck']             = 'トラックを選択',
        ['select_your_truck']        = 'トラックを選んでください！',
        ['select_mission_and_route'] = 'ミッションとルートを選択してください！',
        ['start_the_job']            = '仕事を開始！',
        ['stop_job']                 = '仕事を中止',
        ['start_job']                = '仕事を開始',

        -- プロフィール
        ['completed_jobs']           = '完了した仕事',
        ['total_missions_completed'] = '国立転送・保管（NTS）で完了したミッションの合計です。',
        ['total_earnings']           = '累計収入',
        ['total_earnings_desc']      = '国立転送・保管（NTS）で稼いだ金額の合計です。',
        ['current_level']            = '現在のレベル',
        ['latest_works']             = '最近の仕事',
        ['earned']                   = '獲得',

        -- 闇・その他
        ['illegal_validation_failed'] = '闇荷物の検証に失敗しました。',
        ['must_have_job']            = '取引には進行中のトラック仕事が必要です。',
        ['already_illegal']          = 'すでに闇配送中か、連絡待ちです。',
        ['too_far']                  = '離れすぎたため、取引はキャンセルされました。',
        ['edit_hud_hint']            = 'HUD編集: ドラッグで移動。ESC または /truckhud で保存。',
        ['level_required']           = 'レベル %s が必要です',
        ['select_all_first']         = 'ミッション・ルート・トラックを先に選択してください。',
        ['xp_until_next']            = '次のレベルまで %s XP',
        ['driver']                   = 'ドライバー',
        ['dispatch_board']           = '配車ボード',
        ['no_route_selected']        = 'ルート未選択',
        ['routes_count']             = '%s ルート',
        ['nts_company']              = '国立転送・保管（NTS）',
        ['available_freight']        = '利用可能な貨物',
        ['route_options']            = 'ルート一覧',
        ['extra_payment']            = '追加報酬 +$%s',
        ['standard_payment']         = '通常報酬',
        ['choose_equipment']         = '車両を選択',
        ['trust_required']           = '信頼 %s',
        ['company_trust']            = '企業の信頼',
        ['routes_payment']           = '%s ルート / $%s',
        ['leaderboard_level']        = 'レベル %s',
        ['unknown_caller']           = '非通知',
        ['special_freight_call']     = '特別貨物の依頼',
        ['phone_accept_decline']     = 'Y 受ける / N 断る',
        ['talk_to_dealer']           = 'E - 闇の仲介人と話す',
    },
}

function Locales.Get(key, ...)
    local str = translations[currentLocale] and translations[currentLocale][key]
    if not str then
        str = translations['en'] and translations['en'][key]
    end
    if not str then
        return key
    end
    if ... then
        return string.format(str, ...)
    end
    return str
end

function Locales.SetLocale(locale)
    currentLocale = locale
end

function Locales.AddLocale(locale, strings)
    translations[locale] = strings
end

L = Locales.Get

Config = Config or {}
Config.Language = (function()
    local out = {}
    for k, v in pairs(translations['ja'] or translations['en'] or {}) do
        out[k] = v
    end
    return out
end)()
