fx_version 'cerulean'
games { 'rdr3' }

ui_page 'html/index.html'

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'pvp',
    'RespawnSys'
}

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/bg.jpg',
    'assets/*.*'
}

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
