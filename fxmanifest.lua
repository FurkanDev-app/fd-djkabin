fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'fd-djkabin'
author 'FurkanDev'
description 'Synced DJ booth system - YouTube/MP3 playback, playlists, queue, effects (QBCore / ESX / Qbox / Standalone)'
version '1.0.0'

shared_scripts {
    'shared/config.lua',
    'shared/locale.lua',
}

client_scripts {
    'bridge/client.lua',
    'client/streamer.lua',
    'client/audio.lua',
    'client/effects.lua',
    'client/main.lua',
    'client/admin.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server.lua',
    'server/permissions.lua',
    'server/booth.lua',
    'server/playlist.lua',
    'server/queue.lua',
    'server/main.lua',
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*',
    'locales/*.json',
}

dependency 'oxmysql'
