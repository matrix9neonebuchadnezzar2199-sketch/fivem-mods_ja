fx_version 'cerulean'
game 'gta5'

name 'jp-taxijob'
description 'Japanese-style Taxi Job for Qbox'
author 'JP-Mods'
version '1.0.0'
repository 'https://github.com/jp-mods/jp-taxijob'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/main.lua',
}

server_script 'server/main.lua'

ui_page 'html/hud.html'

files {
    'html/hud.html',
    'html/hud.css',
    'html/hud.js',
    'config/client.lua',
    'config/shared.lua',
    'locales/*.json',
}

provide 'qb-taxijob'

lua54 'yes'
use_experimental_fxv2_oal 'yes'
ox_lib 'locale'

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_target',
}
