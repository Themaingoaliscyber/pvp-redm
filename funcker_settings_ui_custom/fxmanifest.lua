fx_version 'cerulean'
game 'rdr3'

author 'RedM VORP Assistant'
description 'UI pentru toggle HUD și Notificări'
version '1.0.0'

client_script 'client.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua', -- asta e cheia
    'server.lua'              -- scriptul tău cu cod SQL
}


ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js',
    'assets/*.*'
}

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
