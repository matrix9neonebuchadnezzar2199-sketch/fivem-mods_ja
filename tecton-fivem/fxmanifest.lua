-- SPDX-License-Identifier: LGPL-3.0-or-later
fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'TECTON Contributors'
description 'TECTON - A builder''s toolkit for FiveM'
version '0.1.0'
repository 'https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja'
license 'LGPL-3.0-or-later'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/*.lua',
    'config/*.lua',
}

client_scripts { 'client/**/*.lua' }
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/db.lua',
    'server/history.lua',
    'server/autosave.lua',
    'server/recover.lua',
    'server/api.lua',
    'server/main.lua',
}

ui_page 'web/dist/index.html'
files {
    'web/dist/index.html',
    'web/dist/assets/*',
    'assets/thumbnails/*.webp',
    'docs/ja/reverse-index.json',
}

-- object_gizmo は配置・ギズモ用（M1-c 以降）。未導入でもリソースは起動する。導入時は object_gizmo を ensure してから使う。
dependencies { 'ox_lib', 'oxmysql' }
