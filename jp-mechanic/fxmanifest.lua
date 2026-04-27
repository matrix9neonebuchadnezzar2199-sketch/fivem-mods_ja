fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'JP-Mods'
description '整備工場 伝票整理内職（NUI：症状→部品・作業）'
version '1.0.2'

-- 出題庫は server_scripts で列挙（server_script{単数} より互換性が高い）
shared_scripts {
    'config.lua',
}
client_scripts {
    'client/main.lua',
}
server_scripts {
    'data/slips_easy.lua',
    'data/slips_medium.lua',
    'data/slips_hard.lua',
    'server/main.lua',
}

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
