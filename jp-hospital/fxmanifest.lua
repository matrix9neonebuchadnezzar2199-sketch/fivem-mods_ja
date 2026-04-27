fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'JP-Mods'
description '病院カルテ整理・薬梱包ミニゲーム（NUI内職）'
version '1.2.1'

-- 出題庫はサーバーのみで読み込み（Config[kartesKey] が空になる不具合を防ぐ。クライアントは config のみ要）
shared_script 'config.lua'
client_script 'client/main.lua'
server_script {
    'data/kartes_easy.lua',
    'data/kartes_medium.lua',
    'data/kartes_hard.lua',
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
