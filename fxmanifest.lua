fx_version 'cerulean'
game 'gta5'
author 'piotreq'
description 'Hudzik leeeaaan dzi dzi'
lua54 'yes'

client_scripts {
    'client/*.lua'
}

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
    'web/img/*.png'
}