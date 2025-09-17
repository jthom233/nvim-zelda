-- nvim-zelda plugin entry point

if vim.g.loaded_nvim_zelda then
    return
end
vim.g.loaded_nvim_zelda = true

-- Create user commands
vim.api.nvim_create_user_command('ZeldaStart', function()
    require('nvim-zelda').start()
end, {})

vim.api.nvim_create_user_command('ZeldaQuit', function()
    require('nvim-zelda').quit()
end, {})

-- Optional: Create a shorter alias
vim.api.nvim_create_user_command('Zelda', function()
    require('nvim-zelda').start()
end, {})