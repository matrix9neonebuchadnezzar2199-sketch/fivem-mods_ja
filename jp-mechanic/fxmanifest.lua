fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'JP-Mods'
description '整備工場 伝票整理内職（NUI：症状→部品・作業）'
version '1.0.2'

shared_script 'config.lua'
shared_script 'data/slips_easy.lua'
shared_script 'data/slips_medium.lua'
shared_script 'data/slips_hard.lua'
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
