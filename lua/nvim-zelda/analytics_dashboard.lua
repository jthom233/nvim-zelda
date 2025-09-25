-- Real Analytics Dashboard for nvim-zelda
-- Production-ready metrics and visualizations with zero mocks

local M = {}
local persistence = require('nvim-zelda.persistence')
local learning = require('nvim-zelda.learning_engine')

-- Create analytics dashboard window
function M.show_dashboard()
    -- Get real player statistics
    local stats = persistence.get_player_stats()
    local recommendations = learning.get_recommendations()
    local leaderboard = persistence.get_leaderboard(5)

    -- Create buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)

    -- Calculate window size
    local width = 80
    local height = 35
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    -- Create window
    local win = vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        row = row,
        col = col,
        width = width,
        height = height,
        style = 'minimal',
        border = 'double',
        title = ' 📊 Vim Mastery Analytics Dashboard 📊 ',
        title_pos = 'center'
    })

    -- Generate dashboard content
    local lines = {}

    -- Header
    table.insert(lines, string.rep("═", 78))
    table.insert(lines, "                        VIM TRAINING PROGRESS REPORT")
    table.insert(lines, string.rep("═", 78))
    table.insert(lines, "")

    -- Player Overview
    table.insert(lines, "👤 PLAYER STATISTICS")
    table.insert(lines, string.rep("-", 40))
    table.insert(lines, string.format("  Level:        %d", stats.level or 1))
    table.insert(lines, string.format("  Total Score:  %d", stats.score or 0))
    table.insert(lines, string.format("  Play Time:    %d minutes", (stats.playtime or 0) / 60))
    table.insert(lines, string.format("  Achievements: %d unlocked", stats.achievements or 0))
    table.insert(lines, "")

    -- Command Mastery Chart
    table.insert(lines, "📈 COMMAND MASTERY")
    table.insert(lines, string.rep("-", 40))

    if stats.top_commands and #stats.top_commands > 0 then
        for _, cmd in ipairs(stats.top_commands) do
            local bar_length = math.floor((cmd.mastery_level or 0) / 100 * 30)
            local bar = string.rep("█", bar_length) .. string.rep("░", 30 - bar_length)
            table.insert(lines, string.format("  %-10s %s %3d%% (%d uses)",
                cmd.command,
                bar,
                cmd.mastery_level or 0,
                cmd.practice_count or 0))
        end
    else
        table.insert(lines, "  No command data yet. Start playing to track progress!")
    end
    table.insert(lines, "")

    -- Learning Recommendations
    table.insert(lines, "💡 RECOMMENDATIONS")
    table.insert(lines, string.rep("-", 40))

    if recommendations and #recommendations > 0 then
        for i, rec in ipairs(recommendations) do
            if i <= 3 then -- Show top 3 recommendations
                local priority_icon = rec.priority == "high" and "🔴" or
                                     rec.priority == "medium" and "🟡" or "🟢"
                table.insert(lines, string.format("  %s %s", priority_icon, rec.message))
            end
        end
    else
        table.insert(lines, "  Great job! Keep practicing to unlock new levels.")
    end
    table.insert(lines, "")

    -- Weak Areas Analysis
    local weak_commands = learning.get_weak_commands()
    if weak_commands and #weak_commands > 0 then
        table.insert(lines, "⚠️  NEEDS PRACTICE")
        table.insert(lines, string.rep("-", 40))
        for i = 1, math.min(3, #weak_commands) do
            local cmd = weak_commands[i]
            table.insert(lines, string.format("  %s: %s (%.0f%% success)",
                cmd.command,
                cmd.description,
                cmd.success_rate * 100))
        end
        table.insert(lines, "")
    end

    -- Leaderboard
    table.insert(lines, "🏆 LEADERBOARD")
    table.insert(lines, string.rep("-", 40))

    if leaderboard and #leaderboard > 0 then
        table.insert(lines, "  Rank  Player          Score   Level  Commands")
        table.insert(lines, "  " .. string.rep("-", 46))
        for i, entry in ipairs(leaderboard) do
            table.insert(lines, string.format("  %2d.   %-15s %5d    %3d     %3d",
                i,
                entry.username or "Unknown",
                entry.score or 0,
                entry.level or 1,
                entry.commands_mastered or 0))
        end
    else
        table.insert(lines, "  No leaderboard entries yet. Be the first!")
    end
    table.insert(lines, "")

    -- Progress Visualization
    table.insert(lines, "📊 LEARNING CURVE")
    table.insert(lines, string.rep("-", 40))

    -- Calculate current level mastery
    local current_level = learning.current_level or "basic_motion"
    local mastery = learning.calculate_mastery(current_level) * 100

    local progress_bar_length = math.floor(mastery / 100 * 50)
    local progress_bar = string.rep("█", progress_bar_length) .. string.rep("░", 50 - progress_bar_length)

    table.insert(lines, string.format("  Current Level: %s",
        learning.command_tree[current_level] and learning.command_tree[current_level].name or current_level))
    table.insert(lines, string.format("  Progress: %s %.1f%%", progress_bar, mastery))
    table.insert(lines, "")

    -- Footer
    table.insert(lines, string.rep("═", 78))
    table.insert(lines, "Press 'q' to close | ':ZeldaStats' for quick stats | ':Zelda' to play")

    -- Set buffer content
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)

    -- Add keybinding to close
    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '', {
        callback = function()
            vim.api.nvim_win_close(win, true)
        end,
        noremap = true,
        silent = true
    })

    -- Add syntax highlighting
    vim.api.nvim_win_set_option(win, 'winhl', 'Normal:Normal,FloatBorder:FloatBorder')

    -- Apply custom highlights
    local ns_id = vim.api.nvim_create_namespace('zelda_dashboard')

    -- Highlight headers
    for i, line in ipairs(lines) do
        if line:match("^👤") or line:match("^📈") or line:match("^💡") or
           line:match("^⚠️") or line:match("^🏆") or line:match("^📊") then
            vim.api.nvim_buf_add_highlight(buf, ns_id, 'Title', i-1, 0, -1)
        elseif line:match("^═") then
            vim.api.nvim_buf_add_highlight(buf, ns_id, 'Comment', i-1, 0, -1)
        elseif line:match("^%-%-%-") then
            vim.api.nvim_buf_add_highlight(buf, ns_id, 'Comment', i-1, 0, -1)
        elseif line:match("█") then
            -- Find bar positions and highlight
            local bar_start = line:find("█")
            if bar_start then
                local bar_end = bar_start
                while bar_end <= #line and line:sub(bar_end, bar_end) == "█" do
                    bar_end = bar_end + 1
                end
                vim.api.nvim_buf_add_highlight(buf, ns_id, 'String', i-1, bar_start-1, bar_end-1)
            end
        end
    end

    return buf, win
end

-- Show quick stats (mini dashboard)
function M.show_quick_stats()
    local stats = persistence.get_player_stats()
    local current_level = learning.current_level or "basic_motion"
    local mastery = learning.calculate_mastery(current_level) * 100

    local message = string.format(
        "📊 Quick Stats: Level %d | Score %d | %s %.0f%% | %d Achievements",
        stats.level or 1,
        stats.score or 0,
        learning.command_tree[current_level] and learning.command_tree[current_level].name or "Basic",
        mastery,
        stats.achievements or 0
    )

    vim.notify(message, vim.log.levels.INFO)
end

-- Export stats to JSON
function M.export_stats()
    local stats = persistence.get_player_stats()
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local filename = string.format("nvim-zelda-stats-%s.json", timestamp)
    local filepath = vim.fn.stdpath('data') .. '/' .. filename

    local data = {
        exported_at = os.date("%Y-%m-%d %H:%M:%S"),
        player_stats = stats,
        command_mastery = {},
        weak_areas = learning.get_weak_commands(),
        recommendations = learning.get_recommendations(),
        session_stats = learning.session_stats
    }

    -- Add command mastery for all levels
    for level_key, level in pairs(learning.command_tree) do
        data.command_mastery[level_key] = {
            name = level.name,
            mastery = learning.calculate_mastery(level_key)
        }
    end

    -- Write to file
    local file = io.open(filepath, "w")
    if file then
        file:write(vim.json.encode(data))
        file:close()
        vim.notify("📊 Stats exported to: " .. filepath, vim.log.levels.INFO)
    else
        vim.notify("Failed to export stats", vim.log.levels.ERROR)
    end
end

-- Commands are registered in plugin/nvim-zelda.lua to ensure availability

return M