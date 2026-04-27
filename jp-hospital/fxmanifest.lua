fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'JP-Mods'
description '病院カルテ整理・薬梱包ミニゲーム（NUI内職）'
version '1.2.2'

-- 出題庫は server_scripts で列挙（server_script{単数}の { } 展開が環境で無視される例がある）
shared_scripts {
    'config.lua',
}
client_scripts {
    'client/main.lua',
}
server_scripts {
    'data/kartes_easy.lua',
    'data/kartes_medium.lua',
    'data/kartes_hard.lua',
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
