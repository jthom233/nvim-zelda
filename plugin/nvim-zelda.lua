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

-- Logger commands
vim.api.nvim_create_user_command('ZeldaLogs', function()
    require('nvim-zelda.logger').show_logs()
end, {})

vim.api.nvim_create_user_command('ZeldaClearLogs', function()
    require('nvim-zelda.logger').clear_logs()
end, {})

vim.api.nvim_create_user_command('ZeldaExportLogs', function()
    require('nvim-zelda.logger').export_logs()
end, {})

vim.api.nvim_create_user_command('ZeldaLogLevel', function(opts)
    local logger = require('nvim-zelda.logger')
    local level_name = opts.args:upper()
    if logger.levels[level_name] then
        logger.config.level = logger.levels[level_name]
        vim.notify("Log level set to: " .. level_name, vim.log.levels.INFO)
    else
        vim.notify("Invalid log level. Use: DEBUG, INFO, WARN, ERROR, or FATAL", vim.log.levels.ERROR)
    end
end, {
    nargs = 1,
    complete = function()
        return { "DEBUG", "INFO", "WARN", "ERROR", "FATAL" }
    end
})

-- Analytics dashboard commands
vim.api.nvim_create_user_command('ZeldaDashboard', function()
    require('nvim-zelda.analytics_dashboard').show_dashboard()
end, {})

vim.api.nvim_create_user_command('ZeldaStats', function()
    require('nvim-zelda.analytics_dashboard').show_quick_stats()
end, {})

vim.api.nvim_create_user_command('ZeldaExport', function()
    require('nvim-zelda.analytics_dashboard').export_stats()
end, {})

-- Help command to list all available commands
vim.api.nvim_create_user_command('ZeldaHelp', function()
    local commands = {
        { cmd = ":Zelda", desc = "Start the game" },
        { cmd = ":ZeldaStart", desc = "Start the game (alias)" },
        { cmd = ":ZeldaQuit", desc = "Quit the game" },
        { cmd = ":ZeldaHealth", desc = "Run health check" },
        { cmd = ":ZeldaDebug", desc = "Show debug information" },
        { cmd = ":ZeldaLogs", desc = "View game logs" },
        { cmd = ":ZeldaClearLogs", desc = "Clear log file" },
        { cmd = ":ZeldaExportLogs", desc = "Export logs with timestamp" },
        { cmd = ":ZeldaLogLevel [LEVEL]", desc = "Set log level (DEBUG/INFO/WARN/ERROR/FATAL)" },
        { cmd = ":ZeldaDashboard", desc = "Show analytics dashboard" },
        { cmd = ":ZeldaStats", desc = "Show quick stats" },
        { cmd = ":ZeldaExport", desc = "Export stats to JSON" },
        { cmd = ":ZeldaHelp", desc = "Show this help" }
    }

    print("=== nvim-zelda Commands ===\n")
    for _, command in ipairs(commands) do
        print(string.format("  %-25s %s", command.cmd, command.desc))
    end
    print("\n=== In-Game Controls ===")
    print("  h/j/k/l               Move (left/down/up/right)")
    print("  w/b                   Jump forward/backward by word")
    print("  gg/G                  Jump to top/bottom")
    print("  x/dd                  Attack enemies")
    print("  /                     Search for enemies")
    print("  ?                     Show in-game help")
    print("  q                     Quit game")
end, {})