fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'JP-Mods'
description 'ガチャポン - NUI演出付きスタンドアロンガチャ'
version '1.0.0'

shared_script 'config.lua'

client_script 'client/main.lua'
server_script 'server/main.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/img/*.png',
    'html/sounds/*.mp3',
}
