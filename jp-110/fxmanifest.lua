fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'jp-mods'
description '110番通報システム - 警察無線通知'
version '1.0.0'

shared_script 'config.lua'
client_script 'client/main.lua'
server_script 'server/main.lua'

ui_page 'html/index.html'
files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}
