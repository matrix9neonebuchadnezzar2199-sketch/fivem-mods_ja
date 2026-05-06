fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'RefBoard'
author 'matrix9neonebuchadnezzar2199-sketch'
version '0.5.1'
description 'RefBoard — FiveM 向けサッカー試合管理（改ざん防止履歴・編集ロック・i18n）'

dependencies {
  'oxmysql',
  '/server:7290',
}

shared_scripts {
    'config.lua',
    'shared/constants.lua',
    'shared/error_codes.lua',
    'locales/*.lua',
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/util.lua',
  'server/db.lua',
  'server/permission.lua',
  'server/lock.lua',
  'server/autosave.lua',
  'server/team.lua',
  'server/data.lua',
  'server/match.lua',
  'server/player.lua',
  'server/score.lua',
  'server/clock.lua',
  'server/event.lua',
  'server/presence.lua',
  'server/health.lua',
  'server/test/transaction_test.lua',
  'server/main.lua',
}

client_scripts {
  'client/nui_callback.lua',
  'client/main.lua',
}

ui_page 'web/dist/index.html'

files {
  'web/dist/index.html',
  'web/dist/**/*',
}
