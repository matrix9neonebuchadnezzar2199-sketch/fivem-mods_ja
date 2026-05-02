fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'JP-Mods'
description 'Standalone TCG BOOK for FiveM: collection, deck builder, CPU duel, peer PvP (server-authoritative), Elo, match history, leaderboard & rank tiers. oxmysql + optional QBCore/ESX display names.'
version '0.6.0'

dependency 'oxmysql'

shared_scripts {
    'config.lua',
    'shared/battle_rule.lua',
    'shared/battle_wire_log.lua',
    'shared/identity.lua',
    'shared/cards.lua',
    'shared/rank.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/battle_stats.lua',
    'server/battle_rewards.lua',
    'server/battle_finish_dryrun.lua',
    'server/collection.lua',
    'server/deck.lua',
    'server/debug.lua',
    'server/admin.lua',
    'server/battle_lobby.lua',
    'server/battle_debug.lua',
    'server/battle_pvp.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
    'client/nui_callbacks.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js',
    'html/admin/index.html',
    'html/admin/css/*.css',
    'html/admin/js/*.js',
    'html/assets/cards/**/*.png',
    'html/assets/cards/asset_manifest.json',
    'html/assets/duel_back.png',
    -- 段位徽章（M6）。ワイルドカード可だが欠け検知のため 9 枚明示（ファイル名は Linux 本番で厳密一致）
    'html/assets/ranc/Wood.png',
    'html/assets/ranc/Bronze.png',
    'html/assets/ranc/Iron.png',
    'html/assets/ranc/Silver.png',
    'html/assets/ranc/Gold.png',
    'html/assets/ranc/Platinum.png',
    'html/assets/ranc/Astral.png',
    'html/assets/ranc/Dragon.png',
    'html/assets/ranc/Mythology.png',
}
