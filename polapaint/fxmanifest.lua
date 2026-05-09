fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'JP-Mods'
description 'polapaint — 拡張ポラロイドカメラ（撮影・Discord Webhook・NUI 編集 / ox_inventory + screenshot-basic）'
version '1.0.7'
license 'GPL-3.0'

dependency 'ox_inventory'
--[[ screenshot-basic はリポ同梱（ルートの screenshot-basic/）。撮影前に未起動ならクライアントが通知。 ]]
dependency 'screenshot-basic'

shared_scripts {
    'config.lua',
    'locales/ja.lua',
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
    'html/app.js',
    'html/images/polaroid_camera.png',
    'html/images/polaroid_photo.png',
}
