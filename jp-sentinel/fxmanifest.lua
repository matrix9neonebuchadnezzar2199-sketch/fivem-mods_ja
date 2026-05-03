fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'eiho_tsukuyomi'
description 'JP-Sentinel - 警察用自律追尾ドローン投擲ガジェット'
version '1.0.0'

shared_scripts {
    'locales/en.lua',
    'locales/ja.lua',
    'config.lua',
    'bridge/job.lua',
}

client_scripts {
    'client/fx.lua',
    'client/blip.lua',
    'client/drone.lua',
    'client/impact.lua',
    'client/throw.lua',
    'client/main.lua',
}

server_scripts {
    'bridge/inventory.lua',
    'server/cooldown.lua',
    'server/tracker.lua',
    'server/main.lua',
}
