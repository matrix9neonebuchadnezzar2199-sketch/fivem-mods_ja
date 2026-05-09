fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'JP-Mods'
description '拡張ポラロイドカメラ — 撮影・Discord Webhook 保存・NUI で落書きして再アップロード（ox_inventory / screenshot-basic）'
version '1.0.0'
license 'GPL-3.0'

dependency 'ox_inventory'
dependency 'screenshot-basic'

shared_scripts {
    'config.lua',
    'locales/ja.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}
