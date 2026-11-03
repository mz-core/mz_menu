fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'MZ Core'
description 'MZ Menu - reusable in-game menu/input/alert wrapper with custom MZ NUI and optional ox_lib fallback'
version '0.4.0-test'

ui_page 'web/index.html'

files {
  'web/index.html',
  'web/style.css',
  'web/app.js'
}

shared_scripts {
  'shared/config.lua'
}

client_scripts {
  'client/main.lua'
}

server_scripts {
  'server/main.lua'
}

-- ox_lib is no longer a hard dependency.
-- If you want to force ox_lib backend/fallback, make sure ox_lib is started and add @ox_lib/init.lua here intentionally.
-- shared_script '@ox_lib/init.lua'
-- dependency 'ox_lib'
