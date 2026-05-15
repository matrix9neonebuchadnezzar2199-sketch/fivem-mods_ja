fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'JP-Mods'
description 'MERIDIAN-9 / Project JANUS - 次元探査エクストラクション型ミッション MOD'
version '0.1.0-jp'
license 'MIT'
repository 'https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/utils.lua',
    'locales/ja.lua',
    'config.lua',
}

client_scripts {
    'client/hud.lua',
    'client/main.lua',
    'client/arena.lua',
    'client/npc.lua',
    'client/dialogue.lua',
    'client/party.lua',
    'client/loot.lua',
    'client/extract.lua',
    'client/transition.lua',
    'client/effects.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/framework.lua',
    'server/contract.lua',
    'server/stats.lua',
    'server/session.lua',
    'server/loot.lua',
    'server/extract.lua',
    'server/arena/wave.lua',
    'server/arena/spawn.lua',
    'server/arena/arena.lua',
    'server/survival.lua',
    'server/hud.lua',
    'server/party.lua',
    'server/main.lua',
    'server/mission.lua',
    'server/reward.lua',
}

dependencies {
    'oxmysql',
    'ox_lib',
    'ox_target',
    -- INSTRUCTION-020 v7: bob74_ipl は撤去（mnr_cayo と重複ロードで GTA V クラッシュ）
    -- 旧 v2 北ヤンクトン互換コードは bob74_ipl 未起動でも no-op で動作する
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/assets/logo_light.png',
    'html/assets/logo_dark.png',
    'html/assets/icons/*.png',
}
