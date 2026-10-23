fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'Numele Tau'
description 'Safezone System for VORP'
version '1.0.0'

shared_script 'config.lua'
client_script 'client.lua'
server_scripts {
    '@oxmysql/lib/MySQL.lua', -- Folosește OX MySQL
    'server.lua' -- Numele fișierului tău unde ai pus codul
}

