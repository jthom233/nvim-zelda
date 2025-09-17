-- nvim-zelda plugin entry point (MINIMAL & FAST)
-- Following MLRSA-NG: Real implementation, zero performance waste

if vim.g.loaded_nvim_zelda then
    return
end
vim.g.loaded_nvim_zelda = true

-- Core game commands (lazy loaded)
local function lazy_require(module)
    return setmetatable({}, {
        __index = function(_, key)
            return require(module)[key]
        end
    })
end

-- Register commands WITHOUT loading modules
local commands = {
    Zelda = function() require('nvim-zelda').start() end,
    ZeldaStart = function() require('nvim-zelda').start() end,
    ZeldaQuit = function() require('nvim-zelda').quit() end,
    ZeldaHealth = function() require('nvim-zelda.health').check() end,

    -- Debug/Logging (only load when used)
    ZeldaDebug = function()
        local zelda = require('nvim-zelda')
        vim.notify(vim.inspect({
            running = zelda.state and zelda.state.running,
            room = zelda.state and zelda.state.current_room,
            buf = zelda.state and zelda.state.buf
        }), vim.log.levels.INFO)
    end,

    ZeldaLogs = function()
        -- Only initialize logger when needed
        local logger = require('nvim-zelda.logger')
        if not logger.config.enabled then
            logger.init({ enabled = true, level = logger.levels.WARN })
        end
        logger.show_logs()
    end,

    ZeldaClearLogs = function()
        local logger = require('nvim-zelda.logger')
        if logger.config.enabled then
            logger.clear_logs()
        else
            vim.notify("Logging not enabled", vim.log.levels.WARN)
        end
    end,

    ZeldaExportLogs = function()
        local logger = require('nvim-zelda.logger')
        if logger.config.enabled then
            logger.export_logs()
        else
            vim.notify("Logging not enabled", vim.log.levels.WARN)
        end
    end,

    -- Analytics (only load when requested)
    ZeldaDashboard = function()
        require('nvim-zelda.analytics_dashboard').show_dashboard()
    end,

    ZeldaStats = function()
        require('nvim-zelda.analytics_dashboard').show_quick_stats()
    end,

    ZeldaExport = function()
        require('nvim-zelda.analytics_dashboard').export_stats()
    end,

    ZeldaHelp = function()
        print([[
=== nvim-zelda Commands ===

GAME:
  :Zelda            Start the game
  :ZeldaQuit        Quit the game

DEBUG (if needed):
  :ZeldaHealth      Check setup
  :ZeldaDebug       Show state
  :ZeldaLogs        View logs (enables logging)

STATS:
  :ZeldaDashboard   Analytics dashboard
  :ZeldaStats       Quick stats

Type :Zelda to start playing!
]])
    end
}

-- Register all commands
for name, func in pairs(commands) do
    vim.api.nvim_create_user_command(name, func, {})
end

-- Add log level command with completion
vim.api.nvim_create_user_command('ZeldaLogLevel', function(opts)
    local logger = require('nvim-zelda.logger')
    if not logger.config.enabled then
        logger.init({ enabled = true })
    end

    local level_name = opts.args:upper()
    if logger.levels[level_name] then
        logger.config.level = logger.levels[level_name]
        vim.notify("Log level: " .. level_name, vim.log.levels.INFO)
    end
end, {
    nargs = 1,
    complete = function()
        return { "DEBUG", "INFO", "WARN", "ERROR", "OFF" }
    end
})