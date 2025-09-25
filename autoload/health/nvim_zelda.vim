" Health check for nvim-zelda plugin
function! health#nvim_zelda#check() abort
    lua require('nvim-zelda.health').check()
endfunction