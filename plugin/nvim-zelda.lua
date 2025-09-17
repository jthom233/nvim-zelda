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

-- Health check command
vim.api.nvim_create_user_command('ZeldaHealth', function()
    require('nvim-zelda.health').check()
end, {})

-- Debug command
vim.api.nvim_create_user_command('ZeldaDebug', function()
    local zelda = require('nvim-zelda')
    print('=== nvim-zelda Debug Info ===')
    print('Plugin loaded:', vim.g.loaded_nvim_zelda and 'yes' or 'no')
    print('State.ns_id:', zelda.state and zelda.state.ns_id or 'nil')
    print('State.running:', zelda.state and zelda.state.running or 'nil')
    print('State.buf:', zelda.state and zelda.state.buf or 'nil')
    print('State.win:', zelda.state and zelda.state.win or 'nil')
    print('Config.width:', zelda.config and zelda.config.width or 'nil')
    print('Config.height:', zelda.config and zelda.config.height or 'nil')
end, {})