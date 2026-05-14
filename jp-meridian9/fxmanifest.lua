fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'JP-Mods'
description 'MERIDIAN-9 / Project JANUS - 次元探査エクストラクション型ミッション MOD'
version '0.1.0-jp'
license 'MIT'
repository 'https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja'

shared_scripts {
    'shared/utils.lua',
    'locales/ja.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/npc.lua',
    'client/dialogue.lua',
    'client/party.lua',
    'client/hud.lua',
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
    'server/main.lua',
    'server/party.lua',
    'server/mission.lua',
    'server/loot.lua',
    'server/extract.lua',
    'server/reward.lua',
}

dependencies {
    'oxmysql',
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
