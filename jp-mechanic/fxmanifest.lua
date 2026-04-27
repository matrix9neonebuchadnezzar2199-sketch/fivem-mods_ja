fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'JP-Mods'
description '整備工場 伝票整理内職（NUI：症状→部品・作業）'
version '1.0.1'

-- 出題庫はサーバーのみ（jp-hospital と同様。クライアントは config のみ要）
shared_script 'config.lua'
client_script 'client/main.lua'
server_script {
    'data/slips_easy.lua',
    'data/slips_medium.lua',
    'data/slips_hard.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

dependencies {
    'ox_lib',
    'ox_target',
    'qbx_core',
}
