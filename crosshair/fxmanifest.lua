fx_version 'cerulean'
game 'rdr3'

author 'Level5 Dev'
version '1.0-release'

lua54 'yes'

-- Client scripts
client_scripts {
    'client/client.lua',
}

-- Server scripts (momentan gol)
server_scripts {
    -- 'server/server.lua', -- Poți adăuga aici scripturi server când ai nevoie
}

-- UI setup
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js',
}

-- Escrow ignore
escrow_ignore {
    'client/client.lua',
}

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'