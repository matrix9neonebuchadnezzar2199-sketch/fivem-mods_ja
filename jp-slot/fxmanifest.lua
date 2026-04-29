fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'jp-slot'
author 'JP-Mods'
version '1.0.0'
description 'JP-Slot - VTuber Casino Slot Machine'

shared_script 'config_shared.lua'

server_scripts {
    'config_server.lua',
    'server/framework.lua',
    'server/locales.lua',
    'vendor/sha2.lua',
    'server/util.lua',
    'server/admin_auth.lua',
    'server/rng.lua',
    'server/theme.lua',
    'server/ui_size.lua',
    'server/dynamic_machines.lua',
    'server/admin.lua',
    'server/main.lua',
    'server/commands.lua',
}

client_scripts {
    'client/machines.lua',
    'client/admin.lua',
    'client/commands.lua',
    'client/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/admin.html',
    'html/css/**/*.css',
    'html/js/**/*.js',
    'html/assets/characters/*/manifest.json',
    'html/assets/characters/**/*.png',
    'html/assets/characters/**/*.jpg',
    'html/assets/characters/**/*.jpeg',
    'html/assets/characters/**/*.webp',
    'html/assets/characters/**/*.webm',
    'html/assets/characters/**/*.mp4',
    'html/assets/characters/**/*.mp3',
    'html/assets/characters/**/*.wav',
    'html/assets/characters/**/*.ogg',
    'html/assets/symbols/*.png',
    'html/assets/frames/*.png',
    'html/assets/shared/**/*',
    'locales/*.json',
}
