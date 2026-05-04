fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'JP-Mods'
description 'jp-mch: 日本語 ミニマル HUD（ESX / QBCore / Qbox / standalone 対応）'
version '1.0.0'

shared_scripts {
    'config.lua',
    'locales/ja.lua',
}

client_scripts {
    'bridge/framework.lua',
    'client/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
}
