fx_version 'cerulean'
game 'gta5'
lua54 'yes'

--[[
    リソース名は Renewed-Banking のまま（exports['Renewed-Banking'] 互換のため変更禁止）
    原作: Renewed-Banking by uShifty — https://github.com/Renewed-Scripts/Renewed-Banking
    ライセンス: CC BY-NC-SA 4.0
    日本語化派生: jp-renewedbanking2（matrix9neonebuchadnezzar2199-sketch）
]]

author 'uShifty (原作) / matrix9neonebuchadnezzar2199-sketch (日本語版)'
description 'Renewed-Banking 日本語化版 — 銀行・ATM・口座管理（CC BY-NC-SA 4.0）'
version '2.1.4-ja.3'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/framework.lua',
    'client/main.lua',
    'client/menus.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/framework.lua',
    'server/main.lua'
}

ui_page 'web/public/index.html'

dependencies {
    'ox_lib',
    'oxmysql',
    'ox_target',
}

files {
  'Renewed-Banking.sql',
  'web/public/index.html',
  'web/public/**/*',
  'locales/*.json'
}

provide 'qb-management'
provide 'esx_society'
