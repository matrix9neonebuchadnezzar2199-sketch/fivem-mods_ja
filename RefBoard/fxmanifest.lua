fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'RefBoard'
author 'matrix9neonebuchadnezzar2199-sketch'
version '0.4.0'
description 'RefBoard — 各監督が端末で目盛るサッカー試合管理（ローカル専用・通信なし）'

shared_scripts {
  'config.lua',
  'shared/constants.lua',
}

client_scripts {
  'client/main.lua',
}

ui_page 'web/dist/index.html'

files {
  'web/dist/index.html',
  'web/dist/**/*',
}
