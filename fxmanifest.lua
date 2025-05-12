fx_version 'cerulean'
game 'gta5'

author 'Claude'
description 'Advanced shop system for ESX with player owned shops'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'locales/*.lua',
    'config.lua'
}

client_scripts {
    'compat.lua',
    'client/utils.lua',
    'client/main.lua',
    'client/shop_menu.lua',
    'client/owner_menu.lua',
    'client/robbery.lua'
}

server_scripts {
    'compat.lua',
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/inventory.lua',
    'server/shop_management.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/*.js',
    'html/img/*.png'
}

dependencies {
    'es_extended',
    'oxmysql'
}

lua54 'yes'