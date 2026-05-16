fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'JP-Mods'
description 'MERIDIAN-9 / Project JANUS - 次元探査エクストラクション型ミッション MOD'
version '0.1.0-jp'
license 'MIT'
repository 'https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/utils.lua',
    'locales/ja.lua',
    'locales/en.lua',
    'config.lua',
}

client_scripts {
    'client/hud.lua',
    'client/main.lua',
    'client/result.lua',
    'client/arena.lua',
    'client/npc.lua',
    'client/dialogue.lua',
    'client/party.lua',
    'client/loot.lua',
    'client/extract.lua',
    'client/transition.lua',
    'client/effects.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/framework.lua',
    'server/contract.lua',
    'server/stats.lua',
    'server/session.lua',
    'server/loot/roll.lua',
    'server/loot/grant.lua',
    'server/loot/fiction.lua',
    'server/loot.lua',
    'server/hud.lua',
    'server/result.lua',
    'server/extract.lua',
    'server/arena/wave.lua',
    'server/arena/spawn.lua',
    'server/arena/arena.lua',
    'server/survival.lua',
    'server/playarea.lua',
    'server/party.lua',
    'server/main.lua',
    'server/mission.lua',
    'server/reward.lua',
}

dependencies {
    'oxmysql',
    'ox_lib',
    'ox_target',
    -- INSTRUCTION-020 v7: bob74_ipl は撤去（mnr_cayo と重複ロードで GTA V クラッシュ）
    -- 旧 v2 北ヤンクトン互換コードは bob74_ipl 未起動でも no-op で動作する
}

-- NUI は ui_page を1つのみ（HUD）。リザルト B-b 以降は index から result を読み込む想定。
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    -- B-a: ブラウザ単体プレビュー用ページ（実機では index へ統合予定）
    'html/result.html',
    'html/result.css',
    'html/item-icon-map.js',
    'html/result.js',
    -- HUD 左カラム案: ブラウザ単体プレビュー（将来 index 統合時も files 列挙を維持）
    'html/hud_preview.html',
    'html/hud.css',
    'html/hud.js',
    'html/hud_preview.js',
    -- リザルト BGM 等（NUI から `html/sounds/*.mp3` を参照する想定。ファイル名は Linux 本番向けに小文字推奨）
    'html/sounds/*.mp3',
    'image/item/*.png',
    'html/assets/logo_light.png',
    'html/assets/logo_dark.png',
    'html/assets/icons/*.png',
}
