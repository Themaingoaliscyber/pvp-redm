author "JUMP ON studios : https://jumpon-studios.com"
documentation "https://docs.jumpon-studios.com"
version "1.0.2"
package_id "7284107"
dependencies_version_min "jo_clothingstore:4.2.0"

fx_version "cerulean"

rdr3_warning "I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships."

game "rdr3"
lua54 "yes"

escrow_ignore {
  "config/**",
}

shared_script {
  "@jo_libs/init.lua",
  "shared/data/outfitsData.lua",
  "config/**.lua",
  "shared/filters.lua",
  "shared/functions.lua",
}

client_scripts {
  "client/*.lua",
  "client/menus/*.lua",
}

server_scripts {
  "@oxmysql/lib/MySQL.lua",
  "server/server.lua",
}

ui_page "nui://jo_libs/nui/index.html"


dependencies {
  "oxmysql",
  "jo_libs",
}

jo_libs {
  "version-checker",
  "player",
  "component",
  "prompt",
  "notification"
}

dependency '/assetpacks'
dependency '/assetpacks-redm'