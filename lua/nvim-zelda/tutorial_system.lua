-- Tutorial System for nvim-zelda
-- Progressive Neovim teaching with interactive lessons

local M = {}

-- Comprehensive Vim/Neovim lessons organized by difficulty
M.lessons = {
    -- BEGINNER (Levels 1-5)
    {
        id = "basic_movement",
        name = "Basic Movement",
        commands = {"h", "j", "k", "l"},
        description = "Master the fundamental movement keys",
        practice_text = "Move to each corner of the room using hjkl",
        success_criteria = function(state)
            return state.corners_visited and state.corners_visited == 4
        end
    },
    {
        id = "word_movement",
        name = "Word Navigation",
        commands = {"w", "b", "e", "W", "B", "E"},
        description = "Jump between words efficiently",
        practice_text = "Navigate to enemies using word jumps (w/b/e)",
        success_criteria = function(state)
            return state.word_jumps and state.word_jumps >= 10
        end
    },
    {
        id = "line_movement",
        name = "Line Operations",
        commands = {"0", "$", "^", "g_"},
        description = "Navigate within lines",
        practice_text = "Move to line start (0), first char (^), and end ($)",
        success_criteria = function(state)
            return state.line_nav_complete
        end
    },
    {
        id = "vertical_movement",
        name = "Vertical Navigation",
        commands = {"gg", "G", "{", "}", "Ctrl-d", "Ctrl-u"},
        description = "Jump through the document vertically",
        practice_text = "Use gg for top, G for bottom, {} for paragraphs",
        success_criteria = function(state)
            return state.vertical_moves >= 5
        end
    },
    {
        id = "find_char",
        name = "Character Finding",
        commands = {"f", "F", "t", "T", ";", ","},
        description = "Find and move to specific characters",
        practice_text = "Use f<char> to find enemies by their first letter",
        success_criteria = function(state)
            return state.char_finds >= 3
        end
    },

    -- INTERMEDIATE (Levels 6-10)
    {
        id = "deletion",
        name = "Deletion Commands",
        commands = {"x", "X", "dd", "D", "dw", "d$"},
        description = "Delete text efficiently",
        practice_text = "Delete enemies using dd for lines, dw for words",
        success_criteria = function(state)
            return state.deletions >= 5
        end
    },
    {
        id = "visual_mode",
        name = "Visual Selection",
        commands = {"v", "V", "Ctrl-v", "gv"},
        description = "Select text in visual mode",
        practice_text = "Press v to select, V for line-select, Ctrl-v for block",
        success_criteria = function(state)
            return state.visual_selections >= 3
        end
    },
    {
        id = "yanking",
        name = "Copy and Paste",
        commands = {"y", "yy", "p", "P", "yiw", "yap"},
        description = "Copy and paste text objects",
        practice_text = "Yank enemies with yy, paste with p",
        success_criteria = function(state)
            return state.yanks >= 3 and state.pastes >= 3
        end
    },
    {
        id = "search",
        name = "Search and Replace",
        commands = {"/", "?", "n", "N", "*", "#"},
        description = "Search through the buffer",
        practice_text = "Search for enemies with /, next with n, previous with N",
        success_criteria = function(state)
            return state.searches >= 3
        end
    },
    {
        id = "undo_redo",
        name = "Undo and Redo",
        commands = {"u", "Ctrl-r", "U", "."},
        description = "Undo mistakes and repeat actions",
        practice_text = "Undo with u, redo with Ctrl-r, repeat with .",
        success_criteria = function(state)
            return state.undos >= 2 and state.repeats >= 2
        end
    },

    -- ADVANCED (Levels 11-15)
    {
        id = "text_objects",
        name = "Text Objects",
        commands = {"iw", "aw", "i(", "a(", "i\"", "a\"", "it", "at"},
        description = "Operate on text objects",
        practice_text = "Use diw to delete word, ci( to change in parens",
        success_criteria = function(state)
            return state.text_object_ops >= 5
        end
    },
    {
        id = "marks",
        name = "Marks and Jumps",
        commands = {"m", "'", "`", "''", "Ctrl-o", "Ctrl-i"},
        description = "Set marks and jump between locations",
        practice_text = "Mark with ma, jump with 'a, return with ''",
        success_criteria = function(state)
            return state.marks_set >= 2 and state.mark_jumps >= 2
        end
    },
    {
        id = "macros",
        name = "Recording Macros",
        commands = {"q", "@", "@@"},
        description = "Record and replay command sequences",
        practice_text = "Record with qa, stop with q, replay with @a",
        success_criteria = function(state)
            return state.macros_recorded >= 1 and state.macros_played >= 2
        end
    },
    {
        id = "registers",
        name = "Register Operations",
        commands = {"\"", ":reg", "\"ay", "\"ap", "\"+", "\"*"},
        description = "Use named registers and clipboard",
        practice_text = "Yank to register a with \"ay, paste with \"ap",
        success_criteria = function(state)
            return state.register_ops >= 3
        end
    },
    {
        id = "advanced_search",
        name = "Advanced Search",
        commands = {":s/", ":%s/", ":g/", ":v/", "&"},
        description = "Substitute and global commands",
        practice_text = "Replace enemies with :%s/enemy/friend/g",
        success_criteria = function(state)
            return state.substitutions >= 2
        end
    },

    -- EXPERT (Levels 16-20)
    {
        id = "window_management",
        name = "Window Control",
        commands = {"Ctrl-w s", "Ctrl-w v", "Ctrl-w h/j/k/l", "Ctrl-w ="},
        description = "Split and navigate windows",
        practice_text = "Split with Ctrl-w s/v, navigate with Ctrl-w hjkl",
        success_criteria = function(state)
            return state.window_ops >= 3
        end
    },
    {
        id = "folding",
        name = "Code Folding",
        commands = {"zf", "zo", "zc", "za", "zR", "zM"},
        description = "Fold and unfold code sections",
        practice_text = "Create fold with zf, toggle with za",
        success_criteria = function(state)
            return state.fold_ops >= 3
        end
    },
    {
        id = "completion",
        name = "Auto Completion",
        commands = {"Ctrl-n", "Ctrl-p", "Ctrl-x Ctrl-f", "Ctrl-x Ctrl-o"},
        description = "Use built-in completion",
        practice_text = "Complete with Ctrl-n/p, file paths with Ctrl-x Ctrl-f",
        success_criteria = function(state)
            return state.completions >= 3
        end
    },
    {
        id = "quickfix",
        name = "Quickfix Navigation",
        commands = {":cn", ":cp", ":copen", ":ccl", ":cope"},
        description = "Navigate errors and search results",
        practice_text = "Open quickfix with :copen, navigate with :cn/:cp",
        success_criteria = function(state)
            return state.quickfix_nav >= 3
        end
    },
    {
        id = "master_vim",
        name = "Vim Mastery",
        commands = {"All previous commands"},
        description = "Combine all skills in complex scenarios",
        practice_text = "Complete the final challenge using all your skills!",
        success_criteria = function(state)
            return state.final_boss_defeated
        end
    }
}

-- Track player progress
M.progress = {
    completed_lessons = {},
    current_lesson = 1,
    commands_used = {},
    practice_mode = false,
    hint_level = "normal", -- minimal, normal, detailed
    statistics = {
        total_commands = 0,
        correct_commands = 0,
        mistakes = 0,
        time_per_lesson = {}
    }
}

-- Get current lesson
function M.get_current_lesson()
    return M.lessons[M.progress.current_lesson] or M.lessons[1]
end

-- Check if command is part of current lesson
function M.is_lesson_command(cmd)
    local lesson = M.get_current_lesson()
    for _, allowed_cmd in ipairs(lesson.commands) do
        if cmd:match("^" .. vim.pesc(allowed_cmd)) then
            return true
        end
    end
    return false
end

-- Record command usage
function M.record_command(cmd)
    M.progress.statistics.total_commands = M.progress.statistics.total_commands + 1

    if not M.progress.commands_used[cmd] then
        M.progress.commands_used[cmd] = 0
    end
    M.progress.commands_used[cmd] = M.progress.commands_used[cmd] + 1

    if M.is_lesson_command(cmd) then
        M.progress.statistics.correct_commands = M.progress.statistics.correct_commands + 1
        return true
    else
        M.progress.statistics.mistakes = M.progress.statistics.mistakes + 1
        return false
    end
end

-- Get hint for current situation
function M.get_contextual_hint(game_state)
    local lesson = M.get_current_lesson()
    local hints = {}

    if M.progress.hint_level == "minimal" then
        return lesson.commands[1] .. " ..."
    elseif M.progress.hint_level == "normal" then
        table.insert(hints, "Current lesson: " .. lesson.name)
        table.insert(hints, "Commands: " .. table.concat(lesson.commands, ", "))
    else -- detailed
        table.insert(hints, "📚 " .. lesson.name)
        table.insert(hints, "📝 " .. lesson.description)
        table.insert(hints, "⌨️  Commands: " .. table.concat(lesson.commands, ", "))
        table.insert(hints, "🎯 " .. lesson.practice_text)
    end

    return table.concat(hints, "\n")
end

-- Check lesson completion
function M.check_completion(game_state)
    local lesson = M.get_current_lesson()
    if lesson.success_criteria and lesson.success_criteria(game_state) then
        M.complete_lesson()
        return true
    end
    return false
end

-- Complete current lesson
function M.complete_lesson()
    local lesson = M.get_current_lesson()
    M.progress.completed_lessons[lesson.id] = true

    vim.notify("🎉 Lesson Complete: " .. lesson.name, vim.log.levels.INFO)

    if M.progress.current_lesson < #M.lessons then
        M.progress.current_lesson = M.progress.current_lesson + 1
        local next_lesson = M.get_current_lesson()
        vim.notify("📖 Next Lesson: " .. next_lesson.name, vim.log.levels.INFO)
    else
        vim.notify("🏆 Congratulations! You've mastered all Vim commands!", vim.log.levels.INFO)
    end
end

-- Toggle practice mode
function M.toggle_practice_mode()
    M.progress.practice_mode = not M.progress.practice_mode
    if M.progress.practice_mode then
        vim.notify("🎯 Practice Mode Enabled - Try the lesson commands!", vim.log.levels.INFO)
    else
        vim.notify("⚔️  Practice Mode Disabled - Back to the game!", vim.log.levels.INFO)
    end
    return M.progress.practice_mode
end

-- Set hint level
function M.set_hint_level(level)
    if level == "minimal" or level == "normal" or level == "detailed" then
        M.progress.hint_level = level
        vim.notify("💡 Hint level set to: " .. level, vim.log.levels.INFO)
    end
end

-- Get progress report
function M.get_progress_report()
    local report = {}
    table.insert(report, "=== Vim Training Progress ===")
    table.insert(report, string.format("Current Lesson: %d/%d", M.progress.current_lesson, #M.lessons))
    table.insert(report, string.format("Completed: %d lessons", vim.tbl_count(M.progress.completed_lessons)))
    table.insert(report, string.format("Accuracy: %d%%",
        M.progress.statistics.total_commands > 0 and
        math.floor(M.progress.statistics.correct_commands / M.progress.statistics.total_commands * 100) or 0))
    table.insert(report, string.format("Total Commands: %d", M.progress.statistics.total_commands))

    return table.concat(report, "\n")
end

-- Interactive tutorial overlay
function M.show_tutorial_overlay(buf)
    local lesson = M.get_current_lesson()
    local lines = {}

    -- Header
    table.insert(lines, "╔═══════════════════════════════════════╗")
    table.insert(lines, "║       VIM TRAINING - LESSON " .. M.progress.current_lesson .. "        ║")
    table.insert(lines, "╠═══════════════════════════════════════╣")

    -- Lesson content
    table.insert(lines, "║ " .. string.format("%-37s", lesson.name) .. " ║")
    table.insert(lines, "║                                       ║")

    -- Commands
    for _, cmd in ipairs(lesson.commands) do
        table.insert(lines, "║   " .. string.format("%-35s", cmd) .. " ║")
    end

    table.insert(lines, "║                                       ║")
    table.insert(lines, "║ " .. string.format("%-37s", lesson.practice_text:sub(1, 37)) .. " ║")

    -- Footer
    table.insert(lines, "╠═══════════════════════════════════════╣")
    table.insert(lines, "║  [?] Help  [P] Practice  [S] Skip    ║")
    table.insert(lines, "╚═══════════════════════════════════════╝")

    -- Display overlay
    local overlay_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(overlay_buf, 0, -1, false, lines)

    local win_height = vim.api.nvim_win_get_height(0)
    local win_width = vim.api.nvim_win_get_width(0)

    local opts = {
        relative = "editor",
        width = 41,
        height = #lines,
        row = math.floor((win_height - #lines) / 2),
        col = math.floor((win_width - 41) / 2),
        style = "minimal",
        border = "rounded"
    }

    local win = vim.api.nvim_open_win(overlay_buf, false, opts)

    -- Auto-close after 5 seconds
    vim.defer_fn(function()
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
    end, 5000)

    return win
end

return M