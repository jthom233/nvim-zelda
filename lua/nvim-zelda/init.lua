-- nvim-zelda: Vim Training Edition with MLRSA-NG Real Implementations
local M = {}
local api = vim.api

-- Lazy load modules for performance
local persistence, learning, ai_system, logger

local function load_modules()
    if not persistence then
        persistence = require('nvim-zelda.persistence')
        learning = require('nvim-zelda.learning_engine')
        ai_system = require('nvim-zelda.ai_system')

        -- Logger disabled by default for performance
        logger = {
            init = function() end,
            info = function() end,
            debug = function() end,
            warn = function() end,
            error = function() end,
            log_command = function() end,
            log_ai = function() end
        }
    end
end

-- Game state
M.state = {
    running = false,
    buf = nil,
    win = nil,
    ns_id = nil,

    -- Player
    player = {
        x = 5,
        y = 10,
        hp = 100,
        max_hp = 100,
        damage = 10,
        coins = 0,
        keys = 0,
        vim_power = 1,
        learned_commands = {}
    },

    -- Room
    current_room = 1,
    room_cleared = false,
    exit_open = false,

    -- Entities
    enemies = {},
    items = {},
    obstacles = {},
    doors = {},

    -- Inventory
    inventory = {},
    inventory_open = false,
    selected_slot = 1,

    -- Vim training
    combo_buffer = "",
    last_command = "",
    command_history = {},
    tutorial_hints = true,

    -- Map dimensions
    map_width = 70,
    map_height = 20
}

-- Configuration
M.config = {
    width = 80,
    height = 28,  -- Reduced to fit map + HUD
    teach_mode = true
}

-- Room templates with vim challenges
M.room_templates = {
    {
        name = "Tutorial Room",
        layout = "basic",
        vim_lesson = "hjkl movement",
        enemies = 2,
        hint = "Use h (left), j (down), k (up), l (right) to move!"
    },
    {
        name = "Word Jump Arena",
        layout = "platforms",
        vim_lesson = "w/b word movement",
        enemies = 3,
        hint = "Press w to jump forward by word, b to jump backward!"
    },
    {
        name = "Delete Dungeon",
        layout = "maze",
        vim_lesson = "dd delete command",
        enemies = 4,
        hint = "Press dd to delete entire enemy lines!"
    },
    {
        name = "Visual Valley",
        layout = "open",
        vim_lesson = "visual mode",
        enemies = 5,
        hint = "Press v for visual mode, then select multiple enemies!"
    },
    {
        name = "Search Sanctuary",
        layout = "puzzle",
        vim_lesson = "/ search",
        enemies = 3,
        hint = "Press / followed by enemy type to highlight them!"
    }
}

-- Initialize
function M.setup(opts)
    M.config = vim.tbl_extend("force", M.config, opts or {})
    M.state.ns_id = api.nvim_create_namespace("nvim_zelda")

    -- Logger disabled by default - use :ZeldaLogs to enable

    -- Set up highlight groups for colors
    vim.cmd([[
        highlight ZeldaHealth guifg=#ff0000 ctermfg=Red
        highlight ZeldaHealthBar guifg=#00ff00 ctermfg=Green
        highlight ZeldaEnemy guifg=#ff6600 ctermfg=Yellow
        highlight ZeldaItem guifg=#00ffff ctermfg=Cyan
        highlight ZeldaWall guifg=#666666 ctermfg=Gray
        highlight ZeldaDoor guifg=#ffff00 ctermfg=Yellow
        highlight ZeldaPlayer guifg=#ffffff ctermfg=White
    ]])
end

-- Start game
function M.start()
    -- Ensure setup has been called
    if not M.state.ns_id then
        M.setup()
    end

    -- Load modules when game starts
    load_modules()

    if M.state.running then
        vim.notify("Game already running!", vim.log.levels.WARN)
        return
    end

    -- Initialize real persistence
    if not persistence.init() then
        vim.notify("Failed to initialize database. Check permissions.", vim.log.levels.ERROR)
        return
    end

    -- Load or create player profile
    local player_data = persistence.get_or_create_player()
    M.state.player.level = player_data.level
    M.state.player.total_score = player_data.score
    M.state.player.id = player_data.id

    -- Start game session
    M.state.session_id = persistence.start_session()
    M.state.session_start = vim.fn.localtime()

    M.state.running = true
    M.state.current_room = 1
    M.state.player.hp = M.state.player.max_hp

    -- Create window and check for errors
    local window_created = M.create_window()
    if window_created == false then
        M.state.running = false
        vim.notify("Failed to create game window. Run :ZeldaHealth for diagnostics.", vim.log.levels.ERROR)
        return
    end

    M.generate_room(M.state.current_room)
    M.render()

    logger.info("Game", "Game started successfully", {
        room = M.state.current_room,
        player_id = M.state.player.id
    })

    vim.notify("🎮 Welcome to Vim Training! Room 1: " .. M.room_templates[1].hint, vim.log.levels.INFO)
end

-- Create window
function M.create_window()
    -- Create buffer with error handling
    local ok, buf = pcall(api.nvim_create_buf, false, true)
    if not ok then
        vim.notify('Failed to create buffer: ' .. tostring(buf), vim.log.levels.ERROR)
        return false
    end
    M.state.buf = buf

    -- Set buffer options with safe API calls
    local buf_options = {
        buftype = 'nofile',
        bufhidden = 'wipe',
        swapfile = false,
        modifiable = false,
        cursorline = false
    }

    for option, value in pairs(buf_options) do
        local opt_ok, opt_err = pcall(vim.api.nvim_buf_set_option, M.state.buf, option, value)
        if not opt_ok then
            vim.notify('Failed to set buffer option ' .. option .. ': ' .. tostring(opt_err), vim.log.levels.WARN)
        end
    end

    local width = M.config.width
    local height = M.config.height
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    -- Create window with error handling
    local win_ok, win = pcall(api.nvim_open_win, M.state.buf, true, {
        relative = 'editor',
        row = row,
        col = col,
        width = width,
        height = height,
        style = 'minimal',
        border = 'rounded',
        title = ' ⚔️ Vim Training: Room ' .. M.state.current_room .. ' ⚔️ ',
        title_pos = 'center'
    })

    if not win_ok then
        vim.notify('Failed to create window: ' .. tostring(win), vim.log.levels.ERROR)
        return false
    end
    M.state.win = win

    -- Set window options after window is created with error handling
    local win_options = {
        wrap = false,
        scrolloff = 0,
        cursorline = false,
        cursorcolumn = false,
        number = false,
        relativenumber = false,
        signcolumn = 'no'
    }

    for option, value in pairs(win_options) do
        local wopt_ok, wopt_err = pcall(vim.api.nvim_win_set_option, M.state.win, option, value)
        if not wopt_ok then
            vim.notify('Failed to set window option ' .. option .. ': ' .. tostring(wopt_err), vim.log.levels.WARN)
        end
    end

    -- Set up ALL vim-like keybindings
    local keymaps = {
        -- Basic movement
        ['h'] = function() M.move_player(-1, 0, 'h') end,
        ['j'] = function() M.move_player(0, 1, 'j') end,
        ['k'] = function() M.move_player(0, -1, 'k') end,
        ['l'] = function() M.move_player(1, 0, 'l') end,

        -- Word movement (jumps)
        ['w'] = function() M.word_jump(5, 'w') end,
        ['b'] = function() M.word_jump(-5, 'b') end,
        ['e'] = function() M.word_jump(3, 'e') end,

        -- Line movement
        ['0'] = function() M.move_to_line_start() end,
        ['$'] = function() M.move_to_line_end() end,
        ['gg'] = function() M.move_to_top() end,
        ['G'] = function() M.move_to_bottom() end,

        -- Delete commands (attacks)
        ['x'] = function() M.delete_char() end,
        ['dd'] = function() M.delete_line() end,
        ['dw'] = function() M.delete_word() end,
        ['D'] = function() M.delete_to_end() end,

        -- Visual mode
        ['v'] = function() M.enter_visual_mode() end,
        ['V'] = function() M.visual_line_mode() end,

        -- Search
        ['/'] = function() M.search_mode() end,
        ['n'] = function() M.next_search_result() end,
        ['N'] = function() M.prev_search_result() end,

        -- Yank and paste (special abilities)
        ['y'] = function() M.yank_enemy() end,
        ['p'] = function() M.paste_ability() end,

        -- Change and insert (buffs)
        ['c'] = function() M.change_mode() end,
        ['i'] = function() M.inventory_toggle() end,

        -- Numbers (repeat commands)
        ['1'] = function() M.set_repeat(1) end,
        ['2'] = function() M.set_repeat(2) end,
        ['3'] = function() M.set_repeat(3) end,
        ['4'] = function() M.set_repeat(4) end,
        ['5'] = function() M.set_repeat(5) end,

        -- Marks
        ['m'] = function() M.set_mark() end,
        ["'"] = function() M.jump_to_mark() end,

        -- Undo/Redo
        ['u'] = function() M.undo_action() end,
        ['<C-r>'] = function() M.redo_action() end,

        -- Game controls
        ['?'] = function() M.show_help() end,
        [':'] = function() M.command_mode() end,
        ['q'] = function() M.quit() end,
        ['<Esc>'] = function() M.escape_action() end
    }

    for key, func in pairs(keymaps) do
        vim.api.nvim_buf_set_keymap(M.state.buf, 'n', key, '', {
            callback = func,
            noremap = true,
            silent = true
        })
    end

    return true  -- Success
end

-- Generate interesting room layouts
function M.generate_room(room_num)
    M.state.enemies = {}
    M.state.items = {}
    M.state.obstacles = {}
    M.state.doors = {}
    M.state.room_cleared = false
    M.state.exit_open = false

    local template = M.room_templates[math.min(room_num, #M.room_templates)]

    -- Create room layout
    if template.layout == "basic" then
        -- Simple open room
        M.generate_basic_room()
    elseif template.layout == "platforms" then
        -- Platforms requiring word jumps
        M.generate_platform_room()
    elseif template.layout == "maze" then
        -- Maze with walls
        M.generate_maze_room()
    elseif template.layout == "puzzle" then
        -- Puzzle room
        M.generate_puzzle_room()
    else
        M.generate_basic_room()
    end

    -- Add enemies with REAL AI based on room difficulty
    local enemy_types_by_room = {
        [1] = { "goblin" },
        [2] = { "goblin", "skeleton" },
        [3] = { "skeleton", "orc" },
        [4] = { "orc", "guard" },
        [5] = { "guard", "boss" }
    }

    local available_types = enemy_types_by_room[math.min(room_num, 5)]

    for i = 1, template.enemies do
        -- Deterministic enemy placement using room number and index
        local type_index = ((room_num + i - 1) % #available_types) + 1
        local enemy_type = available_types[type_index]

        -- Use golden ratio for better distribution
        local golden_ratio = 1.618033988749895
        local x = math.floor((i * golden_ratio * 7) % (M.state.map_width - 20)) + 10
        local y = math.floor((i * golden_ratio * 11) % (M.state.map_height - 10)) + 5

        -- Create enemy with real AI
        local enemy = ai_system.create_enemy(enemy_type, x, y)
        enemy.id = i
        table.insert(M.state.enemies, enemy)
    end

    -- Add items deterministically based on room
    local item_types = {
        {sprite = "❤️", name = "heart", type = "health"},
        {sprite = "💰", name = "coin", type = "currency"},
        {sprite = "🔑", name = "key", type = "key"},
        {sprite = "⚔️", name = "sword", type = "weapon"},
        {sprite = "🛡️", name = "shield", type = "armor"},
        {sprite = "📜", name = "scroll", type = "vim_power"}
    }

    -- Deterministic item count based on room number
    local item_count = 3 + (room_num % 4)

    for i = 1, item_count do
        local item_index = ((room_num * 3 + i - 1) % #item_types) + 1
        local item = item_types[item_index]

        -- Fibonacci sequence for item placement
        local fib_a, fib_b = 1, 1
        for j = 1, i do
            fib_a, fib_b = fib_b, fib_a + fib_b
        end

        table.insert(M.state.items, {
            x = (fib_a * 7) % (M.state.map_width - 10) + 5,
            y = (fib_b * 5) % (M.state.map_height - 6) + 3,
            sprite = item.sprite,
            name = item.name,
            type = item.type
        })
    end

    -- Add exit door (locked initially)
    table.insert(M.state.doors, {
        x = M.state.map_width - 2,
        y = math.floor(M.state.map_height / 2),
        sprite = "🚪",
        locked = true,
        type = "exit"
    })
end

-- Generate room layouts
function M.generate_basic_room()
    -- Add some obstacles
    for i = 1, 5 do
        table.insert(M.state.obstacles, {
            x = math.random(10, M.state.map_width - 10),
            y = math.random(5, M.state.map_height - 5),
            sprite = "🌳",
            solid = true
        })
    end
end

function M.generate_platform_room()
    -- Create platforms that require w/b jumps
    for i = 1, 4 do
        local platform_x = i * 15
        for j = 0, 5 do
            table.insert(M.state.obstacles, {
                x = platform_x + j,
                y = M.state.map_height - 5,
                sprite = "▓",
                solid = true
            })
        end
    end
end

function M.generate_maze_room()
    -- Create maze walls
    local maze_pattern = {
        "####  ####",
        "#        #",
        "# #### # #",
        "#    # # #",
        "#### # # #",
        "#      # #",
        "# ###### #",
        "#        #",
        "##########"
    }

    for y, row in ipairs(maze_pattern) do
        for x = 1, #row do
            if row:sub(x, x) == "#" then
                table.insert(M.state.obstacles, {
                    x = x * 3 + 10,
                    y = y * 2 + 3,
                    sprite = "█",
                    solid = true
                })
            end
        end
    end
end

function M.generate_puzzle_room()
    -- Create puzzle elements
    local colors = {"🔴", "🟡", "🟢", "🔵"}
    for i = 1, 4 do
        table.insert(M.state.obstacles, {
            x = i * 12 + 5,
            y = 10,
            sprite = colors[i],
            solid = false,
            puzzle_element = true,
            color = i
        })
    end
end

-- Move player with vim training
function M.move_player(dx, dy, key)
    -- Log movement attempt
    logger.debug("Movement", string.format("Player move: %s", key), {
        from = { x = M.state.player.x, y = M.state.player.y },
        delta = { dx = dx, dy = dy }
    })
    -- Track command
    M.state.last_command = key
    M.state.combo_buffer = M.state.combo_buffer .. key

    local new_x = M.state.player.x + dx
    local new_y = M.state.player.y + dy

    -- Check bounds
    if new_x < 2 or new_x > M.state.map_width - 1 or
       new_y < 2 or new_y > M.state.map_height - 1 then
        logger.debug("Movement", "Move blocked by bounds")
        return
    end

    -- Check obstacles
    for _, obs in ipairs(M.state.obstacles) do
        if obs.solid and obs.x == new_x and obs.y == new_y then
            return
        end
    end

    -- Check enemy collision
    for _, enemy in ipairs(M.state.enemies) do
        if enemy.x == new_x and enemy.y == new_y then
            M.state.player.hp = M.state.player.hp - 5
            logger.info("Combat", "Player collided with enemy", {
                enemy_type = enemy.type,
                damage = 5,
                player_hp = M.state.player.hp
            })
            vim.notify("Ouch! -5 HP", vim.log.levels.WARN)
            return
        end
    end

    -- Check door
    for _, door in ipairs(M.state.doors) do
        if door.x == new_x and door.y == new_y then
            if door.locked and M.state.room_cleared then
                door.locked = false
                M.state.exit_open = true
                vim.notify("🚪 Door unlocked! Move through to next room!", vim.log.levels.INFO)
            elseif not door.locked then
                M.next_room()
                return
            else
                vim.notify("🔒 Clear all enemies first!", vim.log.levels.WARN)
                return
            end
        end
    end

    -- Move player
    M.state.player.x = new_x
    M.state.player.y = new_y

    -- Check item pickup
    for i = #M.state.items, 1, -1 do
        local item = M.state.items[i]
        if item.x == new_x and item.y == new_y then
            M.pickup_item(item)
            table.remove(M.state.items, i)
        end
    end

    -- Track vim command learning
    if not M.state.player.learned_commands[key] then
        M.state.player.learned_commands[key] = true
        vim.notify("✨ Learned vim command: " .. key, vim.log.levels.INFO)
    end

    M.render()
end

-- Word jump (w/b commands)
function M.word_jump(distance, key)
    M.state.combo_buffer = M.state.combo_buffer .. key

    local new_x = M.state.player.x + distance
    new_x = math.max(2, math.min(M.state.map_width - 2, new_x))

    -- Check if landing spot is safe
    local safe = true
    for _, obs in ipairs(M.state.obstacles) do
        if obs.solid and obs.x == new_x and obs.y == M.state.player.y then
            safe = false
            break
        end
    end

    if safe then
        M.state.player.x = new_x
        vim.notify("Word jump with '" .. key .. "'!", vim.log.levels.INFO)
    end

    -- Track with real systems
    local execution_time = (vim.loop.hrtime() - start_time) / 1e9
    learning.track_command(key, safe, execution_time, "word_jump")
    persistence.track_command(key, safe, execution_time, "word_jump")

    M.render()
end

-- Delete commands as attacks
function M.delete_char()
    M.state.combo_buffer = M.state.combo_buffer .. "x"

    -- Attack adjacent enemy
    for i = #M.state.enemies, 1, -1 do
        local e = M.state.enemies[i]
        if math.abs(e.x - M.state.player.x) <= 1 and
           math.abs(e.y - M.state.player.y) <= 1 then
            e.hp = e.hp - M.state.player.damage
            if e.hp <= 0 then
                table.remove(M.state.enemies, i)
                vim.notify("Enemy deleted with 'x'!", vim.log.levels.INFO)
                M.check_room_clear()
            else
                vim.notify("Hit! Enemy HP: " .. e.hp, vim.log.levels.INFO)
            end
            break
        end
    end

    M.render()
end

function M.delete_line()
    M.state.combo_buffer = M.state.combo_buffer .. "dd"

    -- Delete all enemies on the same line
    local killed = 0
    for i = #M.state.enemies, 1, -1 do
        if M.state.enemies[i].y == M.state.player.y then
            table.remove(M.state.enemies, i)
            killed = killed + 1
        end
    end

    if killed > 0 then
        vim.notify("Deleted " .. killed .. " enemies with 'dd'!", vim.log.levels.INFO)
        M.check_room_clear()
    end

    M.render()
end

-- Visual mode selection
function M.enter_visual_mode()
    vim.notify("Visual mode! Select area to attack!", vim.log.levels.INFO)
    -- TODO: Implement visual selection
    M.render()
end

-- Search mode
function M.search_mode()
    vim.ui.input({prompt = "Search (enemy name): "}, function(input)
        if input then
            for _, enemy in ipairs(M.state.enemies) do
                if enemy.name:find(input) then
                    enemy.highlighted = true
                    vim.notify("Found " .. enemy.name .. "!", vim.log.levels.INFO)
                end
            end
            M.render()
        end
    end)
end

-- Inventory with vim-style navigation
function M.inventory_toggle()
    M.state.inventory_open = not M.state.inventory_open

    if M.state.inventory_open then
        M.show_inventory()
    else
        M.render()
    end
end

function M.show_inventory()
    local lines = {"", "=== INVENTORY (j/k to select, Enter to use, i to close) ===", ""}

    if #M.state.inventory == 0 then
        table.insert(lines, "  Empty - collect items!")
    else
        for i, item in ipairs(M.state.inventory) do
            local prefix = i == M.state.selected_slot and "> " or "  "
            table.insert(lines, prefix .. item.sprite .. " " .. item.name)
        end
    end

    table.insert(lines, "")
    table.insert(lines, "Coins: " .. M.state.player.coins)
    table.insert(lines, "Keys: " .. M.state.player.keys)

    -- Show in buffer
    local buf_lines = {}
    for _ = 1, 5 do table.insert(buf_lines, "") end
    for _, line in ipairs(lines) do
        table.insert(buf_lines, line)
    end

    api.nvim_buf_set_lines(M.state.buf, 0, #lines + 5, false, buf_lines)
end

-- Pickup items
function M.pickup_item(item)
    if item.type == "health" then
        M.state.player.hp = math.min(M.state.player.max_hp, M.state.player.hp + 20)
        vim.notify(item.sprite .. " +20 HP!", vim.log.levels.INFO)
    elseif item.type == "currency" then
        M.state.player.coins = M.state.player.coins + 1
        vim.notify(item.sprite .. " +1 coin!", vim.log.levels.INFO)
    elseif item.type == "key" then
        M.state.player.keys = M.state.player.keys + 1
        vim.notify(item.sprite .. " Got a key!", vim.log.levels.INFO)
    elseif item.type == "vim_power" then
        M.state.player.vim_power = M.state.player.vim_power + 0.5
        vim.notify(item.sprite .. " Vim power increased!", vim.log.levels.INFO)
    else
        table.insert(M.state.inventory, item)
        vim.notify(item.sprite .. " Added to inventory!", vim.log.levels.INFO)
    end
end

-- Check if room is cleared
function M.check_room_clear()
    if #M.state.enemies == 0 and not M.state.room_cleared then
        M.state.room_cleared = true
        for _, door in ipairs(M.state.doors) do
            if door.type == "exit" then
                door.locked = false
            end
        end
        vim.notify("🎉 Room cleared! Exit unlocked! →", vim.log.levels.INFO)
    end
end

-- Next room
function M.next_room()
    M.state.current_room = M.state.current_room + 1
    M.state.player.x = 5
    M.state.player.y = math.floor(M.state.map_height / 2)

    local template = M.room_templates[math.min(M.state.current_room, #M.room_templates)]
    vim.notify("📍 Room " .. M.state.current_room .. ": " .. template.name, vim.log.levels.INFO)
    vim.notify("💡 " .. template.hint, vim.log.levels.INFO)

    M.generate_room(M.state.current_room)
    M.render()
end

-- Update AI enemies
function M.update_enemies()
    if not M.state.enemies then return end

    local obstacles = M.state.obstacles or {}
    local dt = 0.1 -- Fixed timestep for now

    for _, enemy in ipairs(M.state.enemies) do
        if enemy.behavior then
            -- Get AI decision
            local move = enemy.behavior:update(enemy, M.state.player, obstacles, dt)

            -- Apply movement if valid
            if move and move.dx then
                local new_x = enemy.x + move.dx
                local new_y = enemy.y + move.dy

                -- Check bounds
                if new_x >= 2 and new_x <= M.state.map_width - 1 and
                   new_y >= 2 and new_y <= M.state.map_height - 1 then
                    -- Check collision with obstacles
                    local blocked = false
                    for _, obs in ipairs(obstacles) do
                        if obs.solid and obs.x == new_x and obs.y == new_y then
                            blocked = true
                            break
                        end
                    end

                    -- Check collision with other enemies
                    if not blocked then
                        for _, other in ipairs(M.state.enemies) do
                            if other ~= enemy and other.x == new_x and other.y == new_y then
                                blocked = true
                                break
                            end
                        end
                    end

                    if not blocked then
                        enemy.x = new_x
                        enemy.y = new_y
                    end
                end
            end
        end
    end
end

-- Render with colors
function M.render()
    if not M.state.buf or not api.nvim_buf_is_valid(M.state.buf) then
        return
    end

    -- Update AI before rendering
    M.update_enemies()

    local lines = {}

    -- Draw map
    for y = 1, M.state.map_height do
        local line = ""
        for x = 1, M.state.map_width do
            local char = " "

            -- Borders
            if y == 1 or y == M.state.map_height then
                char = "═"
            elseif x == 1 or x == M.state.map_width then
                char = "║"
            -- Player
            elseif x == M.state.player.x and y == M.state.player.y then
                char = "@"
            else
                -- Check doors
                local found = false
                for _, door in ipairs(M.state.doors) do
                    if door.x == x and door.y == y then
                        char = door.locked and "🔒" or "🚪"
                        found = true
                        break
                    end
                end

                -- Check obstacles
                if not found then
                    for _, obs in ipairs(M.state.obstacles) do
                        if obs.x == x and obs.y == y then
                            char = obs.sprite
                            found = true
                            break
                        end
                    end
                end

                -- Check enemies
                if not found then
                    for _, enemy in ipairs(M.state.enemies) do
                        if enemy.x == x and enemy.y == y then
                            char = enemy.highlighted and "⭕" or enemy.sprite
                            found = true
                            break
                        end
                    end
                end

                -- Check items
                if not found then
                    for _, item in ipairs(M.state.items) do
                        if item.x == x and item.y == y then
                            char = item.sprite
                            found = true
                            break
                        end
                    end
                end

                -- Floor
                if not found then
                    char = "·"
                end
            end

            line = line .. char
        end
        table.insert(lines, line)
    end

    -- HUD separator
    table.insert(lines, string.rep("═", 80))

    -- Health bar with color
    local hp_percent = M.state.player.hp / M.state.player.max_hp
    local hp_bar_length = 20
    local hp_filled = math.floor(hp_bar_length * hp_percent)
    local hp_empty = hp_bar_length - hp_filled

    -- Use ASCII characters for better visibility
    local hp_bar = ""
    for i = 1, hp_bar_length do
        if i <= hp_filled then
            if hp_percent > 0.5 then
                hp_bar = hp_bar .. "█"  -- Full block for high health
            elseif hp_percent > 0.25 then
                hp_bar = hp_bar .. "▓"  -- Medium block for mid health
            else
                hp_bar = hp_bar .. "▒"  -- Light block for low health
            end
        else
            hp_bar = hp_bar .. "░"  -- Empty block
        end
    end

    -- Main HUD line with HP bar
    local hud_line = string.format("HP: %d/%d [%s] | 💰%d 🔑%d | Room %d | 👹%d",
        M.state.player.hp, M.state.player.max_hp, hp_bar,
        M.state.player.coins, M.state.player.keys,
        M.state.current_room, #M.state.enemies)
    table.insert(lines, hud_line)

    -- Room status and combo on same line
    local template = M.room_templates[math.min(M.state.current_room, #M.room_templates)]
    local status_line = "Lesson: " .. template.vim_lesson .. (M.state.room_cleared and " ✅" or " ⏳")
    if #M.state.combo_buffer > 0 then
        status_line = status_line .. " | Combo: " .. M.state.combo_buffer:sub(-10)
    end
    table.insert(lines, status_line)

    -- Compact controls
    table.insert(lines, "[hjkl:move] [w/b:jump] [x/dd:attack] [/:search] [i:inv] [?:help] [q:quit]")

    -- Ensure buffer shows all content
    while #lines < M.config.height do
        table.insert(lines, "")
    end

    -- Update buffer with modifiable temporarily
    vim.api.nvim_buf_set_option(M.state.buf, 'modifiable', true)
    api.nvim_buf_set_lines(M.state.buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(M.state.buf, 'modifiable', false)

    -- Hide the real cursor - we only want the @ character visible
    if M.state.win and api.nvim_win_is_valid(M.state.win) then
        -- Hide cursor by setting it off-screen or to a fixed position
        -- Don't follow the player - that creates double cursor
        pcall(api.nvim_win_set_cursor, M.state.win, {1, 1})

        -- Set cursor to be invisible in the game window
        vim.api.nvim_win_set_option(M.state.win, 'cursorline', false)
        vim.api.nvim_win_set_option(M.state.win, 'cursorcolumn', false)
    end
end

-- Show help
function M.show_help()
    local help = [[
=== VIM TRAINING GAME ===

MOVEMENT:
h/j/k/l - Basic movement (left/down/up/right)
w/b - Jump forward/backward by word
e - Jump to end of word
0/$ - Start/end of line
gg/G - Top/bottom of room

COMBAT:
x - Delete character (basic attack)
dd - Delete line (attack all on line)
dw - Delete word (area attack)
D - Delete to end of line

SPECIAL:
v/V - Visual mode (select enemies)
/ - Search for enemies by name
y - Yank (copy enemy ability)
p - Paste (use copied ability)
u - Undo last action
i - Open inventory

GOAL:
- Learn vim commands through gameplay
- Clear enemies to unlock doors
- Progress through increasingly complex rooms
- Each room teaches new vim concepts
]]
    vim.notify(help, vim.log.levels.INFO)
end

-- Quit
function M.quit()
    M.state.running = false

    if M.state.win and api.nvim_win_is_valid(M.state.win) then
        api.nvim_win_close(M.state.win, true)
    end

    if M.state.buf and api.nvim_buf_is_valid(M.state.buf) then
        api.nvim_buf_delete(M.state.buf, {force = true})
    end

    -- Save progress to database
    if M.state.session_id then
        local session_duration = vim.fn.localtime() - (M.state.session_start or 0)
        persistence.end_session({
            duration = session_duration,
            commands_used = vim.tbl_count(M.state.player.learned_commands),
            enemies_defeated = M.state.enemies_defeated or 0,
            rooms_cleared = M.state.current_room - 1,
            score = M.state.player.total_score or 0
        })

        persistence.save_game_state({
            level = M.state.current_room,
            score = M.state.player.total_score or 0
        })
    end

    -- Show learned commands and stats
    local learned = vim.tbl_keys(M.state.player.learned_commands)
    if #learned > 0 then
        vim.notify("Vim commands learned: " .. table.concat(learned, ", "), vim.log.levels.INFO)
    end

    -- Show session stats
    local stats = persistence.get_player_stats()
    if stats then
        vim.notify(string.format("📊 Session Stats: Level %d | Score %d | %d Achievements",
            stats.level or 1,
            stats.score or 0,
            stats.achievements or 0), vim.log.levels.INFO)
    end

    vim.notify("Thanks for training! You reached room " .. M.state.current_room, vim.log.levels.INFO)
end

-- Commands are registered in plugin/nvim-zelda.lua to ensure availability

return M