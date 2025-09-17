-- Comprehensive Logging System for nvim-zelda
-- Real logging with timestamps, stack traces, and error capture

local M = {}

-- Log levels
M.levels = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4,
    FATAL = 5
}

M.level_names = {
    [1] = "DEBUG",
    [2] = "INFO",
    [3] = "WARN",
    [4] = "ERROR",
    [5] = "FATAL"
}

-- Configuration
M.config = {
    enabled = true,
    level = M.levels.DEBUG,  -- Log everything during development
    file_path = vim.fn.stdpath('data') .. '/nvim-zelda.log',
    max_file_size = 1024 * 1024 * 5,  -- 5MB max
    include_timestamp = true,
    include_stack_trace = true,
    buffer_size = 100,  -- Keep last 100 messages in memory
    auto_open_on_error = true
}

-- In-memory buffer for recent logs
M.buffer = {}
M.session_start = os.date("%Y-%m-%d %H:%M:%S")

-- Initialize logger
function M.init(config)
    if config then
        M.config = vim.tbl_extend("force", M.config, config)
    end

    -- Create or clear log file
    if M.config.enabled then
        M.write_header()
    end

    -- Set up error handler
    M.setup_error_handler()

    M.log(M.levels.INFO, "Logger", "Logging system initialized", {
        log_file = M.config.file_path,
        level = M.level_names[M.config.level]
    })
end

-- Write log header
function M.write_header()
    local header = string.format([[
================================================================================
NVIM-ZELDA LOG SESSION
Started: %s
Neovim: %s
OS: %s
User: %s
================================================================================

]], M.session_start, vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
    vim.loop.os_uname().sysname .. " " .. vim.loop.os_uname().release,
    vim.fn.expand('$USER'))

    local file = io.open(M.config.file_path, 'w')
    if file then
        file:write(header)
        file:close()
    end
end

-- Core logging function
function M.log(level, component, message, data)
    if not M.config.enabled or level < M.config.level then
        return
    end

    -- Create log entry
    local entry = {
        timestamp = os.date("%Y-%m-%d %H:%M:%S.%f"):sub(1, -4),
        level = M.level_names[level],
        component = component,
        message = message,
        data = data
    }

    -- Add to buffer
    table.insert(M.buffer, entry)
    if #M.buffer > M.config.buffer_size then
        table.remove(M.buffer, 1)
    end

    -- Format log line
    local log_line = M.format_entry(entry)

    -- Write to file
    M.write_to_file(log_line)

    -- Show in Neovim if error or fatal
    if level >= M.levels.ERROR and M.config.auto_open_on_error then
        vim.notify(string.format("[%s] %s: %s", entry.level, component, message), vim.log.levels.ERROR)
    end
end

-- Format log entry
function M.format_entry(entry)
    local parts = {}

    -- Timestamp
    if M.config.include_timestamp then
        table.insert(parts, string.format("[%s]", entry.timestamp))
    end

    -- Level and component
    table.insert(parts, string.format("[%s][%s]", entry.level, entry.component))

    -- Message
    table.insert(parts, entry.message)

    -- Data (if any)
    if entry.data then
        local ok, json = pcall(vim.json.encode, entry.data)
        if ok then
            table.insert(parts, "| Data: " .. json)
        else
            table.insert(parts, "| Data: <encoding error>")
        end
    end

    return table.concat(parts, " ")
end

-- Write to log file
function M.write_to_file(log_line)
    local file = io.open(M.config.file_path, 'a')
    if file then
        file:write(log_line .. "\n")
        file:close()
    end

    -- Check file size and rotate if needed
    local stat = vim.loop.fs_stat(M.config.file_path)
    if stat and stat.size > M.config.max_file_size then
        M.rotate_log()
    end
end

-- Rotate log file
function M.rotate_log()
    local backup_path = M.config.file_path .. ".old"

    -- Remove old backup
    vim.fn.delete(backup_path)

    -- Rename current to backup
    vim.fn.rename(M.config.file_path, backup_path)

    -- Write new header
    M.write_header()

    M.log(M.levels.INFO, "Logger", "Log file rotated", {
        old_file = backup_path
    })
end

-- Convenience methods
function M.debug(component, message, data)
    M.log(M.levels.DEBUG, component, message, data)
end

function M.info(component, message, data)
    M.log(M.levels.INFO, component, message, data)
end

function M.warn(component, message, data)
    M.log(M.levels.WARN, component, message, data)
end

function M.error(component, message, data)
    -- Include stack trace for errors
    if M.config.include_stack_trace then
        local trace = debug.traceback("", 2)
        data = data or {}
        data.stack_trace = trace
    end
    M.log(M.levels.ERROR, component, message, data)
end

function M.fatal(component, message, data)
    -- Include full stack trace for fatal errors
    local trace = debug.traceback("", 2)
    data = data or {}
    data.stack_trace = trace

    M.log(M.levels.FATAL, component, message, data)

    -- Also save a crash dump
    M.save_crash_dump(component, message, data)
end

-- Save crash dump
function M.save_crash_dump(component, message, data)
    local crash_file = M.config.file_path .. ".crash"
    local file = io.open(crash_file, 'w')

    if file then
        file:write(string.format([[
================================================================================
CRASH DUMP - NVIM-ZELDA
Time: %s
Component: %s
Message: %s
================================================================================

DATA:
%s

STACK TRACE:
%s

NEOVIM INFO:
%s

GAME STATE:
%s

RECENT LOGS:
%s

================================================================================
]], os.date("%Y-%m-%d %H:%M:%S"),
    component,
    message,
    vim.inspect(data),
    data.stack_trace or "Not available",
    vim.inspect(vim.version()),
    M.get_game_state(),
    M.get_recent_logs()))

        file:close()
        vim.notify("Crash dump saved to: " .. crash_file, vim.log.levels.ERROR)
    end
end

-- Get game state for debugging
function M.get_game_state()
    local ok, game = pcall(require, 'nvim-zelda')
    if ok and game.state then
        return vim.inspect({
            running = game.state.running,
            room = game.state.current_room,
            player = {
                x = game.state.player.x,
                y = game.state.player.y,
                hp = game.state.player.hp,
                level = game.state.player.level
            },
            enemies = #(game.state.enemies or {}),
            items = #(game.state.items or {}),
            last_command = game.state.last_command
        })
    end
    return "Game state not available"
end

-- Get recent logs from buffer
function M.get_recent_logs()
    local lines = {}
    for _, entry in ipairs(M.buffer) do
        table.insert(lines, M.format_entry(entry))
    end
    return table.concat(lines, "\n")
end

-- Setup error handler
function M.setup_error_handler()
    local original_handler = vim.lsp.handlers["window/showMessage"]

    -- Wrap vim.notify to catch errors
    local original_notify = vim.notify
    vim.notify = function(msg, level, opts)
        if level == vim.log.levels.ERROR then
            M.error("VimNotify", tostring(msg), { opts = opts })
        end
        return original_notify(msg, level, opts)
    end
end

-- Log game events
function M.log_game_event(event_type, details)
    M.debug("GameEvent", event_type, details)
end

-- Log command execution
function M.log_command(command, success, execution_time)
    M.debug("Command", string.format("Executed '%s'", command), {
        success = success,
        execution_time = execution_time
    })
end

-- Log AI decision
function M.log_ai(enemy_id, decision, state)
    if M.config.level <= M.levels.DEBUG then
        M.debug("AI", string.format("Enemy %d decision", enemy_id), {
            decision = decision,
            state = state
        })
    end
end

-- Show log viewer
function M.show_logs()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_name(buf, 'nvim-zelda.log')

    -- Read log file
    local lines = {}
    local file = io.open(M.config.file_path, 'r')
    if file then
        for line in file:lines() do
            table.insert(lines, line)
        end
        file:close()
    else
        lines = { "No log file found at: " .. M.config.file_path }
    end

    -- Show last 500 lines
    local start_line = math.max(1, #lines - 500)
    local display_lines = {}
    for i = start_line, #lines do
        table.insert(display_lines, lines[i])
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, display_lines)

    -- Open in split
    vim.cmd('split')
    vim.api.nvim_set_current_buf(buf)

    -- Syntax highlighting
    vim.cmd([[
        syntax match ZeldaLogDebug /\[DEBUG\]/
        syntax match ZeldaLogInfo /\[INFO\]/
        syntax match ZeldaLogWarn /\[WARN\]/
        syntax match ZeldaLogError /\[ERROR\]/
        syntax match ZeldaLogFatal /\[FATAL\]/
        syntax match ZeldaLogTimestamp /\[\d\{4\}-\d\{2\}-\d\{2\} \d\{2\}:\d\{2\}:\d\{2\}\.\d\+\]/

        highlight ZeldaLogDebug guifg=#888888 ctermfg=Gray
        highlight ZeldaLogInfo guifg=#00ff00 ctermfg=Green
        highlight ZeldaLogWarn guifg=#ffff00 ctermfg=Yellow
        highlight ZeldaLogError guifg=#ff0000 ctermfg=Red
        highlight ZeldaLogFatal guifg=#ff00ff ctermfg=Magenta
        highlight ZeldaLogTimestamp guifg=#00ffff ctermfg=Cyan
    ]])

    -- Auto-scroll to bottom
    vim.cmd('normal! G')

    -- Set up auto-refresh
    local timer = vim.loop.new_timer()
    timer:start(1000, 1000, vim.schedule_wrap(function()
        if vim.api.nvim_buf_is_valid(buf) then
            -- Read new lines
            local new_lines = {}
            local file = io.open(M.config.file_path, 'r')
            if file then
                for line in file:lines() do
                    table.insert(new_lines, line)
                end
                file:close()

                local new_start = math.max(1, #new_lines - 500)
                local new_display = {}
                for i = new_start, #new_lines do
                    table.insert(new_display, new_lines[i])
                end

                vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_display)
            end
        else
            timer:stop()
        end
    end))
end

-- Clear logs
function M.clear_logs()
    M.buffer = {}
    M.write_header()
    M.info("Logger", "Logs cleared")
    vim.notify("Logs cleared", vim.log.levels.INFO)
end

-- Export logs
function M.export_logs()
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local export_path = vim.fn.stdpath('data') .. string.format('/nvim-zelda-export-%s.log', timestamp)

    -- Copy log file
    local input = io.open(M.config.file_path, 'r')
    local output = io.open(export_path, 'w')

    if input and output then
        output:write(input:read('*a'))
        input:close()
        output:close()

        vim.notify("Logs exported to: " .. export_path, vim.log.levels.INFO)
        return export_path
    else
        vim.notify("Failed to export logs", vim.log.levels.ERROR)
        return nil
    end
end

-- Commands are registered in plugin/nvim-zelda.lua to ensure availability

return M