fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'YourName'
description 'DVD recording and playback system for FiveM'
version '1.0.0'
license 'MIT'

shared_script 'config.lua'
client_script 'client/main.lua'
server_script 'server/main.lua'

ui_page 'html/index.html'
files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/README.txt',
    'html/img/*.png',
}

dependency 'ox_inventory'
