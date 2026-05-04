fx_version 'cerulean'
game 'gta5'

author 'CocoDeee (original) / matrix9 (JP localization)'
description 'In-game book writer & reader (JP localized, ESX/QB/QBox compatible)'
version '2.0.0-ja.1'

shared_scripts {
    'config.lua',
    'locales/*.lua',
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/js/i18n.js',
    'html/uvbookfront.jpg',
    'html/uvbookback.jpg',
    'html/uvbookpage.jpg',
    'html/images/*.png',

    -- 和文フォント（SIL OFL 1.1）
    'html/fonts/OFL.txt',
    'html/fonts/NotoSerifJP-Regular.woff2',
    'html/fonts/NotoSerifJP-Bold.woff2',
    'html/fonts/NotoSansJP-Regular.woff2',
    'html/fonts/NotoSansJP-Bold.woff2',
    'html/fonts/ShipporiMincho-Regular.woff2',
    'html/fonts/ShipporiMincho-Bold.woff2',
    'html/fonts/KleeOne-Regular.woff2',
    'html/fonts/KleeOne-SemiBold.woff2',
    'html/fonts/YujiSyuku-Regular.woff2',
    'html/fonts/YujiMai-Regular.woff2',
    'html/fonts/YujiBoku-Regular.woff2',
    'html/fonts/HinaMincho-Regular.woff2',
    'html/fonts/ZenKurenaido-Regular.woff2',
    'html/fonts/YuseiMagic-Regular.woff2',
    'html/fonts/ReggaeOne-Regular.woff2',
}

lua54 'yes'