-- Health check for nvim-zelda
local M = {}

function M.check()
    local health = vim.health or require('health')
    local ok = health.ok or health.report_ok
    local warn = health.warn or health.report_warn
    local error = health.error or health.report_error
    local info = health.info or health.report_info
    local start = health.start or health.report_start

    start('nvim-zelda Health Check')

    -- Check Neovim version
    local nvim_version = vim.version()
    if nvim_version.major == 0 and nvim_version.minor < 8 then
        error(string.format('Neovim version 0.8+ required, found %d.%d.%d',
            nvim_version.major, nvim_version.minor, nvim_version.patch))
    else
        ok(string.format('Neovim version: %d.%d.%d',
            nvim_version.major, nvim_version.minor, nvim_version.patch))
    end

    -- Check if the plugin is loaded
    if vim.g.loaded_nvim_zelda then
        ok('Plugin is loaded')
    else
        warn('Plugin not marked as loaded (vim.g.loaded_nvim_zelda not set)')
    end

    -- Check if main module can be required
    local plugin_ok, plugin = pcall(require, 'nvim-zelda')
    if plugin_ok then
        ok('Main module can be required')

        -- Check if the module has expected functions
        if type(plugin.start) == 'function' then
            ok('start() function exists')
        else
            error('start() function not found')
        end

        if type(plugin.quit) == 'function' then
            ok('quit() function exists')
        else
            error('quit() function not found')
        end

        if type(plugin.setup) == 'function' then
            ok('setup() function exists')
        else
            error('setup() function not found')
        end

        -- Check game state
        if plugin.state then
            ok('Game state initialized')

            -- Check specific state properties
            local state_info = {
                'ns_id = ' .. tostring(plugin.state.ns_id),
                'running = ' .. tostring(plugin.state.running),
                'buf = ' .. tostring(plugin.state.buf),
                'win = ' .. tostring(plugin.state.win),
                'current_room = ' .. tostring(plugin.state.current_room),
            }
            info('State: ' .. table.concat(state_info, ', '))

            if not plugin.state.ns_id then
                warn('Namespace not initialized (ns_id is nil) - setup() may not have been called')
            end
        else
            error('Game state not found')
        end

        -- Check config
        if plugin.config then
            ok('Config initialized')
            info(string.format('Config: width=%d, height=%d, teach_mode=%s',
                plugin.config.width or 0,
                plugin.config.height or 0,
                tostring(plugin.config.teach_mode)))
        else
            error('Config not found')
        end

        -- Check room templates
        if plugin.room_templates and #plugin.room_templates > 0 then
            ok(string.format('Room templates loaded: %d rooms', #plugin.room_templates))
        else
            error('Room templates not found or empty')
        end
    else
        error('Failed to require nvim-zelda: ' .. tostring(plugin))
    end

    -- Check user commands
    local commands = vim.api.nvim_get_commands({})
    local zelda_commands = {}
    for name, _ in pairs(commands) do
        if name:match('^Zelda') then
            table.insert(zelda_commands, name)
        end
    end

    if #zelda_commands > 0 then
        ok('User commands registered: ' .. table.concat(zelda_commands, ', '))
    else
        error('No Zelda commands found')
    end

    -- Check for common issues
    start('Common Issues')

    -- Check if lazy.nvim is being used
    if vim.g.lazy_did_setup then
        info('Using lazy.nvim package manager')

        -- Check if the plugin path is correct
        local runtime_paths = vim.api.nvim_list_runtime_paths()
        local plugin_found = false
        for _, path in ipairs(runtime_paths) do
            if path:match('nvim%-zelda') then
                plugin_found = true
                info('Plugin path: ' .. path)
                break
            end
        end

        if not plugin_found then
            warn('Plugin path not found in runtime paths')
        end
    end

    -- Test creating a buffer and window (non-destructive test)
    start('API Tests')

    local test_ok, test_err = pcall(function()
        -- Test buffer creation
        local test_buf = vim.api.nvim_create_buf(false, true)
        if vim.api.nvim_buf_is_valid(test_buf) then
            ok('Buffer creation works')
            vim.api.nvim_buf_delete(test_buf, {force = true})
        else
            error('Failed to create valid buffer')
        end

        -- Test namespace creation
        local test_ns = vim.api.nvim_create_namespace('nvim_zelda_test')
        if test_ns and test_ns > 0 then
            ok('Namespace creation works (id: ' .. test_ns .. ')')
        else
            error('Failed to create namespace')
        end

        -- Test highlight groups
        vim.cmd('highlight ZeldaTest guifg=#ffffff')
        ok('Highlight group creation works')
    end)

    if not test_ok then
        error('API test failed: ' .. tostring(test_err))
    end

    -- Provide diagnostic suggestions
    start('Diagnostic Summary')

    if not plugin_ok then
        error('Plugin cannot be loaded. Try:')
        info('1. Restart Neovim')
        info('2. Run :Lazy sync (if using lazy.nvim)')
        info('3. Check plugin installation path')
    elseif plugin_ok and plugin.state and not plugin.state.ns_id then
        warn('Plugin loaded but not initialized. The game should auto-initialize on first start.')
        info('Try running :Zelda or :ZeldaStart')
    elseif plugin_ok and plugin.state and plugin.state.running then
        info('Game appears to be running. If you see errors, try:')
        info('1. :ZeldaQuit to stop the current game')
        info('2. :Zelda to start fresh')
    else
        ok('Plugin appears to be ready!')
        info('Start the game with :Zelda or :ZeldaStart')
    end
end

return M