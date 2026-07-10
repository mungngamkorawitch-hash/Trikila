fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'trikila-racing'
author 'Phongphira'
version '1.0.0'
shared_scripts {
    'config.lua',
}
server_scripts {
    'server/main.lua',
    'server/rewards.lua',
    'server/commands.lua',
}
client_scripts {
    'client/main.lua',
    'client/boost.lua',
    'client/nui.lua',
}
ui_page 'html/index.html'
files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'sounds/*.ogg',
}
dependencies {
    'es_extended',
}