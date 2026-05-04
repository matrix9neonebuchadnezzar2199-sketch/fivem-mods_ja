fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'

name 'jp-mbt_emote_menu'
author 'Malibù Tech Team (JP localization by matrix9neonebuchadnezzar2199-sketch)'
version      '1.0.0-ja'
description '日本語対応 - rpemotes 系（reborn / 旧版等）用 NUI。依存はランタイム検出（原作: Malibu Tech Team）'

-- rpemotes はフォルダ名がサーバーごとに異なるため hard dependency にしない。
-- 未起動時は core/server.lua の検出ログを参照し、server.cfg で先に ensure すること。
dependencies {
    '/server:6116',
    '/onesync',
}

shared_scripts {
    'modules/locales.lua',
    'locales/*.lua',
    'config.lua',
}

server_scripts {
    'modules/utils/server.lua',
    'core/server.lua',
    'modules/bridges/esx.lua',
    'modules/bridges/qbcore.lua',
    'modules/bridges/qbox.lua',
}

client_scripts {
    'modules/utils/client.lua',
    'modules/storage/client.lua',
    'modules/preview/client.lua',
    'modules/playlist/client.lua',
    'modules/partner/client.lua',
    'core/client.lua',
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/**',
    'web/ja_patch.js',
}
