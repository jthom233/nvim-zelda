" Script to reload the nvim-zelda plugin
" Run this in Neovim with :source reload_plugin.vim

" Clear any existing game state
if exists('g:loaded_nvim_zelda')
    unlet g:loaded_nvim_zelda
endif

" Reload the Lua module
lua << EOF
-- Clear the module from cache
package.loaded['nvim-zelda'] = nil
package.loaded['nvim-zelda.init'] = nil

-- Reload the module
require('nvim-zelda').setup()
EOF

echo "Plugin reloaded! Try :Zelda or :ZeldaStart now"