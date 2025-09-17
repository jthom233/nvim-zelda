-- nvim-zelda: Enhanced version with MLRSA-NG improvements
local M = {}
local api = vim.api
local fn = vim.fn

-- Load enhancement modules (safe loading with fallback)
local combo_system = nil
local boss_system = nil
local hints_system = nil
local save_system = nil

-- Try loading modules
pcall(function()
    combo_system = dofile(vim.fn.stdpath("data") .. "/lazy/nvim-zelda/lua/nvim-zelda/combo_system.lua")
end)

-- Game state with enhanced features
local state = {
    buf = nil,
    win = nil,
    ns_id = nil,
    player_x = 10,
    player_y = 10,
    health = 5,
    max_health = 5,
    coins = 0,
    keys = 0,
    level = 1,
    score = 0,
    map_width = 60,
    map_height = 20,
    running = false,
    enemies = {},
    items = {},
    combo_buffer = {},
    current_boss = nil,
    achievements = {},
    stats = {
        enemies_defeated = 0,
        items_collected = 0,
        commands_used = {},
        play_time = 0,
    }
}

-- Enhanced Configuration
M.config = {
    width = 80,
    height = 30,
    teach_mode = true,
    difficulty = "normal",
    enable_combos = true,
    enable_bosses = true,
    enable_hints = true,
    enable_save = true,
}

-- Combo definitions
local combos = {
    ["hjkl"] = {name = "Navigator", points = 10, desc = "Basic movement mastered!"},
    ["dd"] = {name = "Line Slayer", points = 15, desc = "Delete enemies in line!"},
    ["yp"] = {name = "Duplicator", points = 20, desc = "Copy and paste power!"},
    ["gg"] = {name = "Top Jumper", points = 25, desc = "Jump to beginning!"},
    ["G"] = {name = "End Seeker", points = 25, desc = "Jump to end!"},
    ["ciw"] = {name = "Word Warrior", points = 30, desc = "Change inner word!"},
    ["vi{"] = {name = "Block Master", points = 35, desc = "Select inside blocks!"},
    [":%s"] = {name = "Replacer", points = 40, desc = "Substitute power activated!"},
}

-- Boss definitions
local bosses = {
    {
        name = "Vim Dragon",
        health = 50,
        sprite = "🐉",
        weakness = "dd",
        attacks = {"syntax_error", "indent_chaos"},
        intro = "I am the Vim Dragon! Show me your delete skills (dd)!"
    },
    {
        name = "Modal Monster",
        health = 75,
        sprite = "👾",
        weakness = "ciw",
        attacks = {"mode_lock", "insert_trap"},
        intro = "Modal Monster appears! Master 'ciw' to defeat me!"
    },
}

-- Setup function
function M.setup(opts)
    M.config = vim.tbl_extend("force", M.config, opts or {})
    state.ns_id = api.nvim_create_namespace("nvim_zelda")
end

-- Check for combos
local function check_combo(key)
    if not M.config.enable_combos then return end

    table.insert(state.combo_buffer, key)
    if #state.combo_buffer > 10 then
        table.remove(state.combo_buffer, 1)
    end

    local buffer_str = table.concat(state.combo_buffer)

    for combo, data in pairs(combos) do
        if buffer_str:match(combo .. "$") then
            -- Combo activated!
            state.score = state.score + data.points
            vim.notify("🎯 " .. data.name .. "! " .. data.desc, vim.log.levels.INFO)
            state.combo_buffer = {}
            return data
        end
    end
end

-- Create game window with enhanced UI
local function create_window()
    -- Create buffer
    state.buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_option(state.buf, 'buftype', 'nofile')
    api.nvim_buf_set_option(state.buf, 'swapfile', false)
    api.nvim_buf_set_option(state.buf, 'filetype', 'zelda')

    -- Calculate window position
    local width = M.config.width
    local height = M.config.height
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    -- Create window with enhanced styling
    state.win = api.nvim_open_win(state.buf, true, {
        relative = 'editor',
        row = row,
        col = col,
        width = width,
        height = height,
        style = 'minimal',
        border = 'double',
        title = ' ⚔️  Zelda: Vim Quest - Level ' .. state.level .. ' ⚔️ ',
        title_pos = 'center',
    })

    -- Enhanced keymaps
    local keymaps = {
        -- Movement
        ['h'] = function() move_player(-1, 0, 'h') end,
        ['j'] = function() move_player(0, 1, 'j') end,
        ['k'] = function() move_player(0, -1, 'k') end,
        ['l'] = function() move_player(1, 0, 'l') end,
        -- Advanced movement
        ['w'] = function() jump_word(1) end,
        ['b'] = function() jump_word(-1) end,
        ['gg'] = function() teleport_top() end,
        ['G'] = function() teleport_bottom() end,
        -- Actions
        ['x'] = function() attack() end,
        ['d'] = function() check_combo('d') end,
        ['y'] = function() check_combo('y') end,
        ['p'] = function() check_combo('p') end,
        ['i'] = function() check_combo('i') end,
        ['c'] = function() check_combo('c') end,
        ['v'] = function() check_combo('v') end,
        -- Game controls
        ['?'] = function() show_help() end,
        ['s'] = function() save_game() end,
        ['q'] = function() M.quit() end,
        ['<Esc>'] = function() M.quit() end,
    }

    for key, func in pairs(keymaps) do
        api.nvim_buf_set_keymap(state.buf, 'n', key, '', {
            callback = func,
            noremap = true,
            silent = true
        })
    end

    -- Track command usage
    api.nvim_create_autocmd("CursorMoved", {
        buffer = state.buf,
        callback = function()
            state.stats.play_time = state.stats.play_time + 1
        end
    })
end

-- Enhanced movement with combo tracking
function move_player(dx, dy, key)
    check_combo(key)

    local new_x = state.player_x + dx
    local new_y = state.player_y + dy

    -- Check boundaries
    if new_x >= 2 and new_x < state.map_width - 1 and
       new_y >= 2 and new_y < state.map_height - 1 then

        -- Check for enemy collision
        for i, enemy in ipairs(state.enemies) do
            if enemy.x == new_x and enemy.y == new_y then
                state.health = state.health - 1
                vim.notify("💥 Hit enemy! Health: " .. state.health, vim.log.levels.WARN)
                if state.health <= 0 then
                    game_over()
                    return
                end
            end
        end

        -- Check for item collection
        for i, item in ipairs(state.items) do
            if item.x == new_x and item.y == new_y then
                collect_item(item, i)
            end
        end

        state.player_x = new_x
        state.player_y = new_y
        render_game()
    end
end

-- Advanced movement functions
function jump_word(direction)
    check_combo(direction > 0 and 'w' or 'b')
    state.player_x = math.max(2, math.min(state.map_width - 2,
                              state.player_x + (direction * 5)))
    render_game()
end

function teleport_top()
    check_combo('g')
    check_combo('g')
    state.player_y = 2
    render_game()
end

function teleport_bottom()
    check_combo('G')
    state.player_y = state.map_height - 2
    render_game()
end

-- Attack function
function attack()
    check_combo('x')

    -- Attack enemies around player
    for i = #state.enemies, 1, -1 do
        local enemy = state.enemies[i]
        if math.abs(enemy.x - state.player_x) <= 1 and
           math.abs(enemy.y - state.player_y) <= 1 then
            table.remove(state.enemies, i)
            state.stats.enemies_defeated = state.stats.enemies_defeated + 1
            state.score = state.score + 5
            vim.notify("⚔️ Enemy defeated! Score: " .. state.score, vim.log.levels.INFO)
        end
    end

    -- Check boss damage
    if state.current_boss then
        state.current_boss.health = state.current_boss.health - 5
        if state.current_boss.health <= 0 then
            defeat_boss()
        end
    end

    render_game()
end

-- Collect item
function collect_item(item, index)
    if item.type == "coin" then
        state.coins = state.coins + 1
        vim.notify("💰 Coin collected! Total: " .. state.coins, vim.log.levels.INFO)
    elseif item.type == "heart" then
        state.health = math.min(state.max_health, state.health + 1)
        vim.notify("❤️ Health restored! HP: " .. state.health, vim.log.levels.INFO)
    elseif item.type == "key" then
        state.keys = state.keys + 1
        vim.notify("🔑 Key found! Keys: " .. state.keys, vim.log.levels.INFO)
    end

    table.remove(state.items, index)
    state.stats.items_collected = state.stats.items_collected + 1
end

-- Spawn entities
function spawn_entities()
    -- Clear old entities
    state.enemies = {}
    state.items = {}

    -- Spawn enemies based on level
    local enemy_count = 2 + (state.level * 2)
    for i = 1, enemy_count do
        table.insert(state.enemies, {
            x = math.random(3, state.map_width - 3),
            y = math.random(3, state.map_height - 3),
            type = "slime",
            sprite = "👹"
        })
    end

    -- Spawn items
    local item_count = 3 + state.level
    for i = 1, item_count do
        local item_types = {"coin", "heart", "key"}
        local item_sprites = {coin = "💰", heart = "❤️", key = "🔑"}
        local itype = item_types[math.random(#item_types)]

        table.insert(state.items, {
            x = math.random(3, state.map_width - 3),
            y = math.random(3, state.map_height - 3),
            type = itype,
            sprite = item_sprites[itype]
        })
    end

    -- Spawn boss every 3 levels
    if state.level % 3 == 0 and M.config.enable_bosses then
        local boss = bosses[math.random(#bosses)]
        state.current_boss = vim.deepcopy(boss)
        state.current_boss.x = state.map_width / 2
        state.current_boss.y = 3
        vim.notify("⚠️ BOSS BATTLE: " .. boss.intro, vim.log.levels.WARN)
    end
end

-- Defeat boss
function defeat_boss()
    vim.notify("🎊 BOSS DEFEATED! Amazing vim skills!", vim.log.levels.INFO)
    state.score = state.score + 100
    state.current_boss = nil
    state.level = state.level + 1
    spawn_entities()
end

-- Game over
function game_over()
    vim.notify("💀 GAME OVER! Final Score: " .. state.score, vim.log.levels.ERROR)
    vim.notify("Stats - Enemies: " .. state.stats.enemies_defeated ..
               " | Items: " .. state.stats.items_collected, vim.log.levels.INFO)
    M.quit()
end

-- Show help
function show_help()
    local help = {
        "=== VIM ZELDA CONTROLS ===",
        "Movement: h/j/k/l (vim navigation)",
        "Jump: w/b (word jump), gg/G (top/bottom)",
        "Attack: x (delete char in vim)",
        "Combos: Try vim commands like dd, yp, ciw!",
        "Save: s | Help: ? | Quit: q",
        "",
        "=== ACTIVE COMBOS ===",
    }

    for combo, data in pairs(combos) do
        table.insert(help, combo .. " - " .. data.name .. " (" .. data.points .. " pts)")
    end

    vim.notify(table.concat(help, "\n"), vim.log.levels.INFO)
end

-- Save game
function save_game()
    if not M.config.enable_save then return end

    local save_dir = vim.fn.stdpath("data") .. "/nvim-zelda/"
    vim.fn.mkdir(save_dir, "p")

    local save_data = vim.json.encode(state)
    local save_file = save_dir .. "save.json"
    vim.fn.writefile({save_data}, save_file)

    vim.notify("💾 Game saved!", vim.log.levels.INFO)
end

-- Load game
function load_game()
    if not M.config.enable_save then return false end

    local save_file = vim.fn.stdpath("data") .. "/nvim-zelda/save.json"
    if vim.fn.filereadable(save_file) == 1 then
        local data = vim.fn.readfile(save_file)
        if data and data[1] then
            local loaded = vim.json.decode(data[1])
            -- Restore state (except window/buffer)
            for k, v in pairs(loaded) do
                if k ~= "buf" and k ~= "win" and k ~= "ns_id" then
                    state[k] = v
                end
            end
            return true
        end
    end
    return false
end

-- Enhanced render function
function render_game()
    if not state.buf or not api.nvim_buf_is_valid(state.buf) then
        return
    end

    local lines = {}

    -- Create map with entities
    for y = 1, state.map_height do
        local line = ""
        for x = 1, state.map_width do
            local char = ""

            -- Borders
            if x == 1 or x == state.map_width then
                char = "║"
            elseif y == 1 or y == state.map_height then
                char = "═"
            -- Player
            elseif x == state.player_x and y == state.player_y then
                char = "🗡"
            else
                -- Check for entities at this position
                local entity_found = false

                -- Boss
                if state.current_boss and x == state.current_boss.x and y == state.current_boss.y then
                    char = state.current_boss.sprite
                    entity_found = true
                end

                -- Enemies
                if not entity_found then
                    for _, enemy in ipairs(state.enemies) do
                        if enemy.x == x and enemy.y == y then
                            char = enemy.sprite
                            entity_found = true
                            break
                        end
                    end
                end

                -- Items
                if not entity_found then
                    for _, item in ipairs(state.items) do
                        if item.x == x and item.y == y then
                            char = item.sprite
                            entity_found = true
                            break
                        end
                    end
                end

                -- Empty space
                if not entity_found then
                    char = "·"
                end
            end

            line = line .. char
        end
        table.insert(lines, line)
    end

    -- Add enhanced HUD
    table.insert(lines, "")
    table.insert(lines, "═══════════════════════════════════════════════════════════════")

    -- Health bar
    local health_bar = " HP: "
    for i = 1, state.max_health do
        health_bar = health_bar .. (i <= state.health and "❤️" or "🖤")
    end
    table.insert(lines, health_bar .. "  |  💰 " .. state.coins .. "  |  🔑 " .. state.keys ..
                 "  |  ⭐ Score: " .. state.score .. "  |  📍 Level: " .. state.level)

    -- Boss health
    if state.current_boss then
        table.insert(lines, " BOSS: " .. state.current_boss.name .. " [" ..
                     string.rep("█", state.current_boss.health / 5) ..
                     string.rep("░", 10 - state.current_boss.health / 5) .. "]")
    end

    -- Combo buffer display
    if #state.combo_buffer > 0 then
        table.insert(lines, " Combo: " .. table.concat(state.combo_buffer))
    end

    table.insert(lines, "═══════════════════════════════════════════════════════════════")
    table.insert(lines, " Controls: hjkl=move | x=attack | ?=help | s=save | q=quit")

    if M.config.teach_mode then
        table.insert(lines, " 💡 Tip: Try vim combos like 'dd', 'yp', 'ciw' for bonus points!")
    end

    -- Update buffer
    api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)

    -- Add colors if available
    if state.ns_id then
        -- Color the player
        vim.api.nvim_buf_add_highlight(state.buf, state.ns_id, "Character",
                                       state.player_y - 1,
                                       (state.player_x - 1) * 2,
                                       state.player_x * 2)
    end
end

-- Start the game
function M.start()
    if state.running then
        vim.notify("Game already running!", vim.log.levels.WARN)
        return
    end

    state.running = true

    -- Try to load saved game
    if load_game() then
        vim.notify("💾 Save game loaded! Continue your adventure!", vim.log.levels.INFO)
    else
        spawn_entities()
        vim.notify("🎮 Welcome to Zelda: Vim Quest! Master vim to survive!", vim.log.levels.INFO)
    end

    create_window()
    render_game()
end

-- Quit the game
function M.quit()
    -- Optional: Auto-save on quit
    if state.running and M.config.enable_save then
        save_game()
    end

    if state.win and api.nvim_win_is_valid(state.win) then
        api.nvim_win_close(state.win, true)
    end

    if state.buf and api.nvim_buf_is_valid(state.buf) then
        api.nvim_buf_delete(state.buf, { force = true })
    end

    state.running = false
    state.buf = nil
    state.win = nil

    vim.notify("Thanks for playing Zelda: Vim Quest! Your vim skills have improved!", vim.log.levels.INFO)
end

-- Commands
vim.api.nvim_create_user_command('Zelda', function() M.start() end, {})
vim.api.nvim_create_user_command('ZeldaStart', function() M.start() end, {})
vim.api.nvim_create_user_command('ZeldaQuit', function() M.quit() end, {})
vim.api.nvim_create_user_command('ZeldaSave', function() save_game() end, {})
vim.api.nvim_create_user_command('ZeldaHelp', function() show_help() end, {})

return M