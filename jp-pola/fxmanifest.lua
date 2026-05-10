fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Project Sloth Team (JP fork by JP-Mods)'
description 'カメラ・写真撮影 MOD（ps-camera 日本語版）'
version '1.1.0-jp.1'

-- オリジナル: https://github.com/Project-Sloth/ps-camera
-- ライセンス: CC BY-NC-SA 4.0（LICENSE 参照）

-- 必須リソース（standalone ではない。フォーク／ローカライズ配布扱い）
dependencies {
    'qb-core',
    'screenshot-basic',
}

shared_scripts {
    'config.lua',
    'locales/ja.lua',
}

client_scripts {
    'client/cl_*.lua',
    'client/cl_*.js',
}

server_scripts {
    'server/sv_*.lua',
}

ui_page 'client/nui/index.html'

files {
    'client/nui/index.html',
    'client/nui/app.js',
    'client/nui/main.css',
}

data_file 'DLC_ITYP_REQUEST' 'stream/ps_camera.ytyp'
