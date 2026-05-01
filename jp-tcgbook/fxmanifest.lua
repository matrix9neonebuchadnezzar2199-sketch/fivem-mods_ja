fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'JP-Mods'
description 'トレーディングカードゲーム（BOOK・コレクション・デッキ編成・対戦予定）'
version '0.1.0'

-- フェーズ1-2以降: @oxmysql、server/*.lua、client/*.lua、ui_page、files { 'html/**' } を追加
shared_scripts {
    'config.lua',
    'shared/identity.lua',
    'shared/cards.lua',
}
