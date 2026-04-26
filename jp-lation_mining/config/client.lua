return {

    ----------------------------------------------
    --     💃 Customize animations & props
    ----------------------------------------------

    anims = {
        mining = {
            label = '採掘中…',
            description = '地中から鉱石を採掘しています',
            icon = 'fa-solid fa-hammer',
            position = 'bottom',
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true, combat = true },
            anim = { dict = 'melee@hatchet@streamed_core', clip = 'plyr_rear_takedown_b', flag = 1 },
            prop = { bone = 28422, model = 'prop_tool_pickaxe', pos = vec3(0.09, -0.05, -0.02), rot = vec3(-78.0, 13.0, 28.0) }
        },
        smelting = {
            scenario = 'WORLD_HUMAN_STAND_FIRE'
        }
    },

    ----------------------------------------------
    --     📊 Customize stats & leaderboard
    ----------------------------------------------

    -- Don't want to show the stats menu option at all?
    -- Set all stats below to false!
    stats = {
        -- Do you want to show the ores mined stat?
        mined = true,
        -- Do you want to show the ingots smelted stat?
        smelted = true,
        -- Do you want to show the money earned stat?
        earned = true
    },

    -- Do you want to display the leaderboard?
    -- This shows the top 10 miners by XP
    -- 🗒️ Note: the leaderboard is not updated constantly
    -- It is only updated on server restarts & player logouts
    leaderboard = true,

    ----------------------------------------------
    --     画面（UI）の大きさ — ox_lib 採用時
    --     採掘メニュー・精錬 TextUI・通知・数入力などが小さく感じる場合
    ----------------------------------------------
    ui = {
        -- 1.0 = 既定。2.0 なら文字含め感覚的に約2倍
        -- TextUI: CSS transform(scale)。通知: style 利用可なら同様
        -- ショップ等の「コンテキスト」: 見出し Markdown（# ）付与で大きく見せる
        scale = 2.0,
        -- true のとき、ox_lib コンテキストのタイトル行に # / ## を付与（大きい見出し扱い）
        useLargeMarkdownInContext = true,
        -- true のとき、採掘プログレスの表示ラベル前に少し強調用の記号（※2倍専用マークアウトに追随）
        useLargeProgressLabel = true,
    },

}