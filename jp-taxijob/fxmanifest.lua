fx_version 'cerulean'
game 'gta5'

name 'jp-taxijob'
description 'Japanese-style Taxi Job for Qbox'
author 'JP-Mods'
version '1.0.0'
repository 'https://github.com/jp-mods/jp-taxijob'

-- 重要: shared_script は常に client より先に走る。ここで失敗すると bootstrap まで届かない。
-- なので lib は client/server に分け、bootstrap を「本当の先頭」にする。
client_scripts {
    'client/bootstrap.lua',
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    '@qbx_core/modules/playerdata.lua',
    'client/main.lua',
}

server_scripts {
    'server/bootstrap.lua',
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
    'server/main.lua',
}

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
