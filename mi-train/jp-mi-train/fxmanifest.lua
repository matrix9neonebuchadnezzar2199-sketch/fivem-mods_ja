fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'JP-Mods'
description 'jp-mi-train — MI風走行中列車ヘイスト (Phase 2: DBuz747 attach + heli interior boarding)'
version '0.3.1'
license 'MIT'

-- 設計参考（コードは独立実装、API パターンのみ参考）:
--   TheNickoos/FiveM-Trains (CreateMissionTrain + SetTrainCruiseSpeed)
--   Blumlaut/FiveM-Trains (ホスト 1 人がスポーン)
--   VenomXNL/XNL-FiveM-Trains-U3 (SwitchTrainTrack / SetRandomTrains)
--   GTA-EXPLORE/exp_trainheist (ヘイストフロー設計)

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/blip.lua',
    'client/addon_carriage.lua',
    'client/train.lua',
    'client/heli_board.lua',
    'client/start_npc.lua',
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

dependencies {
    'ox_lib',
    'DBuz747',
}
