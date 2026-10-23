author "JUMP ON studios : shop.jumpon-studios.com"
documentation "https://docs.jumpon-studios.com"
version "1.0.2"
package_id "7224894"
dependencies_version_min "jo_clothingstore:4.0.7"

fx_version "cerulean"

rdr3_warning "I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships."

game "rdr3"
lua54 "yes"

escrow_ignore {
  "config/**",
}

shared_script {
  "@jo_libs/init.lua",
  "config/**.lua",
  "shared/filters.lua",
}

jo_libs {
  "version-checker",
  "player"
}

client_scripts {
  "client/data/npcComponents.lua",
  "client/data/iconsMapping.lua",
  "client/*.lua",
}

dependencies {
  "jo_libs"
}



ui_page "nui://jo_libs/nui/index.html"

dependency '/assetpacks'