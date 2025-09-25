-- Real Error Handler for nvim-zelda
-- Production-ready error boundaries following MLRSA-NG principles

local M = {}
local logger = require('nvim-zelda.logger')

-- Wrap function in error boundary
function M.wrap(fn_name, fn)
    return function(...)
        local args = {...}
        local ok, result = xpcall(function()
            return fn(unpack(args))
        end, function(err)
            -- Log the error with full stack trace
            logger.error("ErrorBoundary", string.format("Error in %s", fn_name), {
                error = err,
                stack_trace = debug.traceback(),
                args = vim.inspect(args)
            })

            -- Show user-friendly error message
            vim.notify(string.format("Game error in %s. Check :ZeldaLogs for details", fn_name), vim.log.levels.ERROR)

            -- Try to recover game state if possible
            M.attempt_recovery(fn_name, err)

            return nil
        end)

        if ok then
            return result
        else
            return nil
        end
    end
end

-- Attempt to recover from error
function M.attempt_recovery(fn_name, error)
    logger.info("Recovery", "Attempting to recover from error", {
        function_name = fn_name,
        error = error
    })

    local game = require('nvim-zelda')

    -- Different recovery strategies based on where error occurred
    if fn_name:match("render") then
        -- Rendering error - try to reset display
        logger.info("Recovery", "Attempting render recovery")
        if game.state and game.state.buf then
            pcall(function()
                vim.api.nvim_buf_set_lines(game.state.buf, 0, -1, false, {
                    "=== RENDER ERROR ===",
                    "Game encountered a rendering issue.",
                    "Press 'q' to quit or ':ZeldaStart' to restart.",
                    "",
                    "Error: " .. tostring(error),
                    "",
                    "Check :ZeldaLogs for details"
                })
            end)
        end
    elseif fn_name:match("move") or fn_name:match("command") then
        -- Movement error - reset player position
        logger.info("Recovery", "Attempting movement recovery")
        if game.state and game.state.player then
            game.state.player.x = math.min(math.max(2, game.state.player.x), game.state.map_width - 2)
            game.state.player.y = math.min(math.max(2, game.state.player.y), game.state.map_height - 2)
        end
    elseif fn_name:match("enemy") or fn_name:match("ai") then
        -- AI error - disable problematic enemy
        logger.info("Recovery", "Attempting AI recovery")
        -- Mark enemies without behavior for removal
        if game.state and game.state.enemies then
            for i, enemy in ipairs(game.state.enemies) do
                if not enemy.behavior then
                    logger.warn("Recovery", "Removing invalid enemy", { index = i })
                    table.remove(game.state.enemies, i)
                end
            end
        end
    end

    -- Try to render current state
    if game.render then
        local render_ok = pcall(game.render)
        if render_ok then
            logger.info("Recovery", "Recovery successful")
        else
            logger.error("Recovery", "Recovery failed - game may be unstable")
        end
    end
end

-- Validate game state
function M.validate_state(state)
    local issues = {}

    if not state then
        table.insert(issues, "State is nil")
        return false, issues
    end

    -- Check player
    if not state.player then
        table.insert(issues, "Player is nil")
    else
        if not state.player.x or not state.player.y then
            table.insert(issues, "Player position invalid")
        end
        if not state.player.hp then
            table.insert(issues, "Player HP is nil")
        end
    end

    -- Check buffer/window
    if state.buf and not vim.api.nvim_buf_is_valid(state.buf) then
        table.insert(issues, "Buffer is invalid")
    end
    if state.win and not vim.api.nvim_win_is_valid(state.win) then
        table.insert(issues, "Window is invalid")
    end

    -- Check map dimensions
    if not state.map_width or not state.map_height then
        table.insert(issues, "Map dimensions invalid")
    end

    if #issues > 0 then
        logger.warn("StateValidation", "State validation failed", { issues = issues })
        return false, issues
    end

    return true, {}
end

-- Safe execute with automatic error logging
function M.safe_execute(component, operation, fn)
    local start_time = vim.loop.hrtime()

    local ok, result = xpcall(fn, function(err)
        local execution_time = (vim.loop.hrtime() - start_time) / 1e9

        logger.error(component, string.format("Operation failed: %s", operation), {
            error = err,
            stack_trace = debug.traceback(),
            execution_time = execution_time
        })

        return err
    end)

    if ok then
        local execution_time = (vim.loop.hrtime() - start_time) / 1e9
        if execution_time > 0.1 then  -- Log slow operations
            logger.warn(component, string.format("Slow operation: %s", operation), {
                execution_time = execution_time
            })
        end
        return result
    else
        return nil
    end
end

-- Create protected version of game module
function M.protect_game_module(game)
    local protected = {}

    -- Wrap all functions in error boundaries
    for key, value in pairs(game) do
        if type(value) == "function" then
            protected[key] = M.wrap(key, value)
        else
            protected[key] = value
        end
    end

    return protected
end

-- Global error handler for uncaught errors
function M.setup_global_handler()
    local original_error = vim.api.nvim_err_writeln

    vim.api.nvim_err_writeln = function(msg)
        logger.fatal("GlobalError", "Uncaught error", {
            message = msg,
            stack_trace = debug.traceback()
        })

        -- Show user-friendly message
        vim.notify("Game encountered an unexpected error. Saved to crash log.", vim.log.levels.ERROR)

        -- Call original handler
        return original_error(msg)
    end
end

return M