rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

fx_version "adamant"
games {"rdr3"}

client_script "client/main.lua"
server_script {
	"server/server.lua",
	"permissions.lua"
}

ui_page 'client/index.html'

files {
	'client/index.html'
}

