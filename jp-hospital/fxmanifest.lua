fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'JP-Mods'
description '病院カルテ整理・薬梱包ミニゲーム（NUI内職）'
version '1.0.0'

shared_script 'config.lua'
client_script 'client/main.lua'
server_script 'server/main.lua'

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
