fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'JP-Mods'
description '闇の指名手配 — 裏カジノ強盗とヤクザ側報復（ESX / QBCore / Qbox / Standalone）'
version '1.0.0'

shared_scripts {
  'shared/version.lua',
  'shared/constants.lua',
  'config/config.lua',
  'config/rewards.lua',
  'config/blacklist.lua',
  'config/retaliation.lua',
  'config/scenarios.lua',
  'config/locations.lua',
  'locales/ja.lua',
  'locales/en.lua',
  'shared/locale.lua',
  'bridge/_init.lua',
}

client_scripts {
  'bridge/cl_bridge.lua',
  'client/utils.lua',
  'client/notifications.lua',
  'client/ui.lua',
  'client/minigames.lua',
  'client/npc_manager.lua',
  'client/heist.lua',
  'client/retaliation.lua',
  'client/main.lua',
}

server_scripts {
  'bridge/sv_bridge.lua',
  'server/utils.lua',
  'server/scenario_loader.lua',
  'server/rewards.lua',
  'server/events.lua',
  'server/persistence.lua',
  'server/bounty.lua',
  'server/heist.lua',
  'server/main.lua',
}

ui_page 'ui/index.html'

files {
  'ui/index.html',
  'ui/css/style.css',
  'ui/js/app.js',
}
