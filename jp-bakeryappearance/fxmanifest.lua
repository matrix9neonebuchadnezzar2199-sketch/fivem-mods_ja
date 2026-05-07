fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'
lua54 'yes'

author 'TechJess#0 (jp fork: JP-Mods locale/i18n)'
description '外見カスタムメニュー（日本語ロケール・i18next 同梱）。原作: Bakery Appearance / bl_appearance 系'
repository 'https://github.com/BakeryDevelopments/bakery_appearance'

shared_scripts {'@ox_lib/init.lua', 'shared/*.lua'}

client_scripts {
  'client/**/*.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/**/*.lua'
}

ui_page 'web/build/index.html'
-- ui_page 'http://localhost:5173/' --for dev

files {
  'modules/*.lua',
  'web/build/index.html',
  'web/build/**/*',
  'shared/locale/*.json',
  'shared/data/*.json',
}

-- provide {
--   'esx_skin',
--   'skinchanger'
-- }