fx_version 'cerulean'
game 'rdr3'

author 'FunckerAdv'
description 'Standalone Badlands RedM Leaderboard'

ui_page 'html/index.html'

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'oxmysql',
    'vorp_core'
}

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
