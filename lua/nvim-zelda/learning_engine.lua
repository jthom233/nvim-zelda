-- Real Vim Learning Engine for nvim-zelda
-- Comprehensive command progression system with zero mocks

local M = {}
local persistence = require('nvim-zelda.persistence')

-- Real comprehensive vim command tree with actual progression
M.command_tree = {
    -- Level 1: Basic Navigation
    basic_motion = {
        name = "Basic Motion",
        commands = {
            h = { desc = "Move left", weight = 1.0 },
            j = { desc = "Move down", weight = 1.0 },
            k = { desc = "Move up", weight = 1.0 },
            l = { desc = "Move right", weight = 1.0 }
        },
        mastery_threshold = 0.95,
        next_levels = { "word_motion", "line_motion" },
        challenges = {
            { type = "navigate_maze", difficulty = 1 },
            { type = "reach_target", time_limit = 10 }
        }
    },

    -- Level 2: Word Motion
    word_motion = {
        name = "Word Navigation",
        commands = {
            w = { desc = "Next word start", weight = 1.0 },
            b = { desc = "Previous word start", weight = 1.0 },
            e = { desc = "Word end", weight = 0.9 },
            W = { desc = "Next WORD start", weight = 0.8 },
            B = { desc = "Previous WORD start", weight = 0.8 },
            E = { desc = "WORD end", weight = 0.7 }
        },
        mastery_threshold = 0.90,
        next_levels = { "line_motion", "search_motion" },
        challenges = {
            { type = "word_jumping", targets = 10 },
            { type = "speed_navigation", wpm_target = 30 }
        }
    },

    -- Level 3: Line Motion
    line_motion = {
        name = "Line Navigation",
        commands = {
            ["0"] = { desc = "Start of line", weight = 1.0 },
            ["$"] = { desc = "End of line", weight = 1.0 },
            ["^"] = { desc = "First non-blank", weight = 0.9 },
            gg = { desc = "First line", weight = 1.0 },
            G = { desc = "Last line", weight = 1.0 },
            ["{"] = { desc = "Previous paragraph", weight = 0.8 },
            ["}"] = { desc = "Next paragraph", weight = 0.8 }
        },
        mastery_threshold = 0.85,
        next_levels = { "search_motion", "marks_jumps" },
        challenges = {
            { type = "line_precision", accuracy_target = 0.95 },
            { type = "paragraph_navigation", time_limit = 15 }
        }
    },

    -- Level 4: Search Motion
    search_motion = {
        name = "Search Navigation",
        commands = {
            ["/"] = { desc = "Search forward", weight = 1.0 },
            ["?"] = { desc = "Search backward", weight = 0.9 },
            n = { desc = "Next match", weight = 1.0 },
            N = { desc = "Previous match", weight = 1.0 },
            ["*"] = { desc = "Search word forward", weight = 0.8 },
            ["#"] = { desc = "Search word backward", weight = 0.8 },
            f = { desc = "Find character", weight = 0.9 },
            F = { desc = "Find backward", weight = 0.8 },
            t = { desc = "Till character", weight = 0.8 },
            T = { desc = "Till backward", weight = 0.7 }
        },
        mastery_threshold = 0.85,
        next_levels = { "text_objects", "operators" },
        challenges = {
            { type = "search_and_destroy", targets = 15 },
            { type = "find_character", speed_target = 2 }
        }
    },

    -- Level 5: Text Objects
    text_objects = {
        name = "Text Objects",
        commands = {
            iw = { desc = "Inner word", weight = 1.0 },
            aw = { desc = "A word", weight = 1.0 },
            ["i'"] = { desc = "Inner single quotes", weight = 0.9 },
            ["a'"] = { desc = "A single quotes", weight = 0.9 },
            ['i"'] = { desc = "Inner double quotes", weight = 0.9 },
            ['a"'] = { desc = "A double quotes", weight = 0.9 },
            ["i("] = { desc = "Inner parentheses", weight = 0.8 },
            ["a("] = { desc = "A parentheses", weight = 0.8 },
            ["i{"] = { desc = "Inner braces", weight = 0.8 },
            ["a{"] = { desc = "A braces", weight = 0.8 },
            it = { desc = "Inner tag", weight = 0.7 },
            at = { desc = "A tag", weight = 0.7 }
        },
        mastery_threshold = 0.80,
        next_levels = { "operators", "visual_mode" },
        challenges = {
            { type = "text_object_selection", accuracy = 0.90 },
            { type = "nested_objects", complexity = 3 }
        }
    },

    -- Level 6: Operators
    operators = {
        name = "Operators",
        commands = {
            d = { desc = "Delete", weight = 1.0 },
            c = { desc = "Change", weight = 1.0 },
            y = { desc = "Yank", weight = 1.0 },
            ["="] = { desc = "Format", weight = 0.8 },
            ["<"] = { desc = "Indent left", weight = 0.7 },
            [">"] = { desc = "Indent right", weight = 0.7 },
            ["!"] = { desc = "Filter", weight = 0.6 },
            gU = { desc = "Uppercase", weight = 0.6 },
            gu = { desc = "Lowercase", weight = 0.6 },
            ["~"] = { desc = "Toggle case", weight = 0.5 }
        },
        mastery_threshold = 0.80,
        next_levels = { "visual_mode", "registers" },
        challenges = {
            { type = "operator_combos", combinations = 20 },
            { type = "efficiency_test", operations_limit = 5 }
        }
    },

    -- Level 7: Visual Mode
    visual_mode = {
        name = "Visual Mode",
        commands = {
            v = { desc = "Character visual", weight = 1.0 },
            V = { desc = "Line visual", weight = 1.0 },
            ["<C-v>"] = { desc = "Block visual", weight = 0.9 },
            gv = { desc = "Reselect", weight = 0.8 },
            o = { desc = "Other end", weight = 0.7 },
            O = { desc = "Other corner", weight = 0.6 }
        },
        mastery_threshold = 0.80,
        next_levels = { "registers", "macros" },
        challenges = {
            { type = "visual_selection", precision = 0.95 },
            { type = "block_editing", operations = 10 }
        }
    },

    -- Level 8: Registers
    registers = {
        name = "Registers",
        commands = {
            ['"a'] = { desc = "Register a", weight = 1.0 },
            ['"0'] = { desc = "Yank register", weight = 0.9 },
            ['"+'] = { desc = "System clipboard", weight = 1.0 },
            ['"*'] = { desc = "Selection clipboard", weight = 0.8 },
            [':reg'] = { desc = "View registers", weight = 0.7 },
            ["<C-r>"] = { desc = "Insert register", weight = 0.8 }
        },
        mastery_threshold = 0.75,
        next_levels = { "macros", "advanced_editing" },
        challenges = {
            { type = "register_juggling", registers = 5 },
            { type = "clipboard_integration", operations = 10 }
        }
    },

    -- Level 9: Macros
    macros = {
        name = "Macros",
        commands = {
            qa = { desc = "Record macro a", weight = 1.0 },
            q = { desc = "Stop recording", weight = 1.0 },
            ["@a"] = { desc = "Play macro a", weight = 1.0 },
            ["@@"] = { desc = "Repeat macro", weight = 0.9 },
            [":normal @a"] = { desc = "Run macro on lines", weight = 0.7 }
        },
        mastery_threshold = 0.75,
        next_levels = { "advanced_editing", "window_management" },
        challenges = {
            { type = "macro_recording", complexity = 3 },
            { type = "bulk_editing", items = 50 }
        }
    },

    -- Level 10: Advanced Editing
    advanced_editing = {
        name = "Advanced Editing",
        commands = {
            ["<C-a>"] = { desc = "Increment number", weight = 0.8 },
            ["<C-x>"] = { desc = "Decrement number", weight = 0.8 },
            J = { desc = "Join lines", weight = 0.9 },
            gJ = { desc = "Join without space", weight = 0.7 },
            [":s"] = { desc = "Substitute", weight = 1.0 },
            [":g"] = { desc = "Global command", weight = 0.8 },
            [":.!"] = { desc = "Filter line", weight = 0.6 }
        },
        mastery_threshold = 0.70,
        next_levels = { "window_management", "expert_mode" },
        challenges = {
            { type = "bulk_substitution", patterns = 10 },
            { type = "number_sequences", count = 20 }
        }
    }
}

-- Track real command execution
function M.track_command(command, success, execution_time, context)
    -- Get current timestamp
    local timestamp = vim.fn.localtime()

    -- Track in database
    persistence.track_command(command, success, execution_time, context)

    -- Update in-memory stats
    if not M.session_stats then
        M.session_stats = {
            commands = {},
            start_time = timestamp,
            total_commands = 0,
            successful_commands = 0
        }
    end

    M.session_stats.total_commands = M.session_stats.total_commands + 1
    if success then
        M.session_stats.successful_commands = M.session_stats.successful_commands + 1
    end

    -- Track per-command stats
    if not M.session_stats.commands[command] then
        M.session_stats.commands[command] = {
            count = 0,
            successes = 0,
            total_time = 0,
            fastest = math.huge,
            slowest = 0
        }
    end

    local cmd_stats = M.session_stats.commands[command]
    cmd_stats.count = cmd_stats.count + 1
    if success then cmd_stats.successes = cmd_stats.successes + 1 end
    cmd_stats.total_time = cmd_stats.total_time + execution_time
    cmd_stats.fastest = math.min(cmd_stats.fastest, execution_time)
    cmd_stats.slowest = math.max(cmd_stats.slowest, execution_time)

    -- Check for achievements
    M.check_achievements(command, execution_time)

    -- Check for level progression
    M.check_progression()
end

-- Calculate real mastery level
function M.calculate_mastery(level_key)
    local level = M.command_tree[level_key]
    if not level then return 0 end

    local total_weight = 0
    local weighted_mastery = 0

    for command, info in pairs(level.commands) do
        local cmd_stats = M.get_command_stats(command)
        local mastery = 0

        if cmd_stats.count > 0 then
            -- Calculate mastery based on success rate and speed
            local success_rate = cmd_stats.successes / cmd_stats.count
            local avg_time = cmd_stats.total_time / cmd_stats.count

            -- Speed bonus (faster execution = higher mastery)
            local speed_bonus = math.max(0, 1 - (avg_time / 2.0)) * 0.3

            mastery = math.min(1.0, success_rate * 0.7 + speed_bonus)
        end

        weighted_mastery = weighted_mastery + (mastery * info.weight)
        total_weight = total_weight + info.weight
    end

    return total_weight > 0 and (weighted_mastery / total_weight) or 0
end

-- Get command statistics
function M.get_command_stats(command)
    if M.session_stats and M.session_stats.commands[command] then
        return M.session_stats.commands[command]
    end

    return {
        count = 0,
        successes = 0,
        total_time = 0,
        fastest = 0,
        slowest = 0
    }
end

-- Check for achievement unlocks
function M.check_achievements(command, execution_time)
    -- Speed demon achievement
    if execution_time < 0.1 then
        if not M.speed_commands then M.speed_commands = 0 end
        M.speed_commands = M.speed_commands + 1

        if M.speed_commands >= 10 then
            persistence.unlock_achievement("speed_demon", {
                commands = M.speed_commands,
                avg_time = execution_time
            })
        end
    end

    -- Command master achievements
    local cmd_stats = M.get_command_stats(command)
    if cmd_stats.count == 100 and cmd_stats.successes >= 95 then
        persistence.unlock_achievement("master_" .. command, {
            command = command,
            success_rate = cmd_stats.successes / cmd_stats.count
        })
    end

    -- Combo achievements
    if M.last_command and M.last_command ~= command then
        if not M.combo_count then M.combo_count = 0 end
        M.combo_count = M.combo_count + 1

        if M.combo_count >= 10 then
            persistence.unlock_achievement("combo_master", {
                combo_length = M.combo_count
            })
        end
    else
        M.combo_count = 0
    end

    M.last_command = command
end

-- Check progression to next level
function M.check_progression()
    if not M.current_level then
        M.current_level = "basic_motion"
    end

    local level = M.command_tree[M.current_level]
    if not level then return end

    local mastery = M.calculate_mastery(M.current_level)

    if mastery >= level.mastery_threshold then
        -- Unlock next levels
        for _, next_level_key in ipairs(level.next_levels or {}) do
            if M.command_tree[next_level_key] then
                vim.notify(string.format("🎯 Level Unlocked: %s!", M.command_tree[next_level_key].name), vim.log.levels.INFO)
                M.unlocked_levels = M.unlocked_levels or {}
                M.unlocked_levels[next_level_key] = true
            end
        end
    end
end

-- Generate real challenge based on player skill
function M.generate_challenge(difficulty)
    local challenges = {}

    -- Get player's weak areas
    local weak_commands = M.get_weak_commands()

    -- Create targeted challenges
    for _, cmd in ipairs(weak_commands) do
        table.insert(challenges, {
            type = "practice",
            command = cmd,
            repetitions = 10,
            time_limit = 30
        })
    end

    -- Add level-appropriate challenges
    if M.current_level then
        local level = M.command_tree[M.current_level]
        if level and level.challenges then
            for _, challenge in ipairs(level.challenges) do
                local adjusted = vim.tbl_deep_extend("force", challenge, {
                    difficulty = difficulty
                })
                table.insert(challenges, adjusted)
            end
        end
    end

    return challenges
end

-- Get commands that need more practice
function M.get_weak_commands()
    local weak = {}

    for level_key, level in pairs(M.command_tree) do
        for command, info in pairs(level.commands) do
            local stats = M.get_command_stats(command)
            if stats.count > 0 then
                local success_rate = stats.successes / stats.count
                if success_rate < 0.8 then
                    table.insert(weak, {
                        command = command,
                        success_rate = success_rate,
                        description = info.desc
                    })
                end
            elseif M.unlocked_levels and M.unlocked_levels[level_key] then
                -- Never practiced but level is unlocked
                table.insert(weak, {
                    command = command,
                    success_rate = 0,
                    description = info.desc
                })
            end
        end
    end

    -- Sort by success rate (weakest first)
    table.sort(weak, function(a, b)
        return a.success_rate < b.success_rate
    end)

    return weak
end

-- Get learning recommendations
function M.get_recommendations()
    local recommendations = {}

    -- Check current level mastery
    local current_mastery = M.calculate_mastery(M.current_level)

    if current_mastery < 0.5 then
        table.insert(recommendations, {
            priority = "high",
            message = "Focus on mastering " .. M.command_tree[M.current_level].name,
            action = "practice_level",
            level = M.current_level
        })
    end

    -- Check for unpracticed commands
    local unpracticed = {}
    for command, _ in pairs(M.command_tree[M.current_level].commands) do
        local stats = M.get_command_stats(command)
        if stats.count < 10 then
            table.insert(unpracticed, command)
        end
    end

    if #unpracticed > 0 then
        table.insert(recommendations, {
            priority = "medium",
            message = "Practice these commands: " .. table.concat(unpracticed, ", "),
            action = "practice_commands",
            commands = unpracticed
        })
    end

    -- Suggest speed improvements
    for command, _ in pairs(M.command_tree[M.current_level].commands) do
        local stats = M.get_command_stats(command)
        if stats.count > 20 and stats.successes / stats.count > 0.9 then
            local avg_time = stats.total_time / stats.count
            if avg_time > 1.0 then
                table.insert(recommendations, {
                    priority = "low",
                    message = string.format("Improve speed for %s (current: %.2fs)", command, avg_time),
                    action = "speed_practice",
                    command = command
                })
            end
        end
    end

    return recommendations
end

return M