fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Nekix (日本語化: matrix9neonebuchadnezzar2199)'
description '高度な配達ジョブスクリプト（日本語版）'
version '2.1.3-jp'

dependencies {
    'ox_lib',
    'ox_target'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config/*.lua'
}

client_scripts {
    'client/bridge.lua',
    'client/init.lua',
    'client/utils.lua',
    'client/job.lua',
    'client/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

server_scripts {
    'server/bridge.lua',
    'server/utils.lua',
    'server/main.lua'
}
