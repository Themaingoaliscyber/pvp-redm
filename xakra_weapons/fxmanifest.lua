author 'Xakra <Discord:Xakra#8145:https://discord.gg/kmsqB6xQjH>'
version '1.5'
description 'xakra_weapons'

fx_version 'adamant'
lua54 'on'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

game 'rdr3'

shared_scripts {
	'locale.lua',
    'languages/*.lua',
	'config/ammo.lua',
	'config/config.lua',
	'client/functions.lua',
	'@vorp_inventory/config/weapons.lua',
	'@vorp_inventory/config/ammo.lua',
}

client_scripts {
	'config/craft.lua',
	'config/stores.lua',
	'client/client.lua',
	'client/comps.lua',
}

server_scripts {
	'server/server.lua',
}

escrow_ignore {
	'config/*.lua',
	'config/ammo.sql',
	'languages/*.lua',
}
dependency '/assetpacks'
dependency '/assetpacks-redm'