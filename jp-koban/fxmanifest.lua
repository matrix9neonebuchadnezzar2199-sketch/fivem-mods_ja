fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name 'jp-koban'
author 'jp-mods'
version '1.0.0'
description '警察官の住宅地巡回パトロールジョブ'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
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
    'html/script.js',
}

dependencies {
    'ox_lib',
    'ox_target',
    'qbx_core',
}
