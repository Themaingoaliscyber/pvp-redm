author "JUMP ON studios : https://jumpon-studios.com"
documentation "https://docs.jumpon-studios.com"
version "1.2.1"
package_id "6012568"
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
  "config/**.lua",
  "shared/*.lua"
}

jo_libs {
  "hook",
  "prompt",
  "table",
  "version-checker",
  "notif",
  "menu",
  "framework-bridge"
}

client_scripts {
  "client/*.lua",
}

ui_page "nui://jo_libs/nui/index.html"

dependency '/assetpacks'
dependency '/assetpacks-redm'