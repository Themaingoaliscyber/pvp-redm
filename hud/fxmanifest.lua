rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

fx_version 'adamant'
game 'rdr3'

author 'HUD RedM System'
description 'HUD cu statistici si sistem de rank integrat'
version '2.0'

dependencies {
    'vorp_core',
    'pvp'
}

shared_scripts {
    'config.lua',
    '@vorp_core/init.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/core.lua',
    'server/stats.lua',
    'server/rank.lua'
}

client_scripts {
    'client/core.lua',
    'client/stats.lua',
    'client/rank.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js',
    'ui/fonts/*.ttf',
    'ui/icons/*.png',
    'assets/*.*'
}

lua54 'yes'
