fx_version 'cerulean'
game 'rdr3'

author 'MyName'
description 'Custom respawn script for RedM without affecting PvP or rsg-medic'
version '1.0.0'

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

client_scripts {
    'client.lua',
    'disabledebug/dbg_client.lua'
}

server_scripts {
    'server.lua'
}

-- Death screen UI
ui_page 'html/death.html'

files {
    'html/death.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'vorp_core',
    'pvp'
}
