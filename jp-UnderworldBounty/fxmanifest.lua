-- ============================================================
-- jp-UnderworldBounty — 闇の指名手配
-- Repository: https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja
-- License: MIT — see LICENSE
--
-- Greenfield 向け完全版マニフェスト例: fxmanifest.full.lua.template
-- References:
--   docs/DESIGN.md             — アーキテクチャ・PHASE 計画
--   docs/PLAYER_FLOW.md        — プレイヤー体験シーン
--   docs/RETALIATION_FSM.md    — 報復 FSM（§13 transitionTo）
--   docs/SEQUENCE_DIAGRAMS.md   — サーバー↔クライアント messaging
--   docs/EVENT_HOOKS.md        — 公開イベント API（jp-UnderworldBounty:on*）
-- ============================================================

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
  'config/contract.lua',
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
  'client/contract.lua',
  'client/retaliation.lua',
  'client/_stub.lua',
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
  'server/contract.lua',
  'server/main.lua',
}

ui_page 'ui/index.html'

files {
  'ui/index.html',
  'ui/css/style.css',
  'ui/js/app.js',
}
