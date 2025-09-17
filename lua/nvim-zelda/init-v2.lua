-- nvim-zelda v2: Enhanced with MLRSA-NG Polish System
-- A beautiful and educational Zelda-inspired game for learning Neovim

local M = {}
local api = vim.api
local fn = vim.fn

-- Load modules
local game = require("nvim-zelda.game")
local quests = require("nvim-zelda.quests")

-- Enhanced game state
local state = {
    initialized = false,
    level = 1,
    score = 0,
    player = nil,
    entities = {},
    map = {},
    current_quest = nil,
    stats = {
        health = 5,
        max_health = 5,
        coins = 0,
        keys = 0,
        enemies_defeated = 0,
        items_collected = 0,
        steps = 0,
    },
    buf = nil,
    win = nil,
    ns_id = nil,
    timers = {},
}

-- Configuration
M.config = vim.tbl_extend("force", game.config, {
    enable_colors = true,
    enable_animations = true,
    enable_particles = true,
    sound_feedback = true,
})

-- Setup function
function M.setup(opts)
    M.config = vim.tbl_extend("force", M.config, opts or {})
    state.ns_id = api.nvim_create_namespace("nvim_zelda")
end

-- Create the game window with better styling
local function create_window()
    -- Create buffer
    state.buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_name(state.buf, "Zelda Game")

    -- Buffer options
    local buf_opts = {
        buftype = 'nofile',
        bufhidden = 'wipe',
        swapfile = false,
        modifiable = false,
        filetype = 'zelda',
    }
    for opt, val in pairs(buf_opts) do
        api.nvim_buf_set_option(state.buf, opt, val)
    end

    -- Calculate window size and position
    local width = M.config.width
    local height = M.config.height + 6  -- Extra space for HUD
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    -- Create floating window with style
    local win_opts = {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'double',
        title = ' ⚔️ Neovim Zelda ⚔️ ',
        title_pos = 'center',
    }

    state.win = api.nvim_open_win(state.buf, true, win_opts)

    -- Window options
    api.nvim_win_set_option(state.win, 'wrap', false)
    api.nvim_win_set_option(state.win, 'cursorline', false)
    api.nvim_win_set_option(state.win, 'number', false)
    api.nvim_win_set_option(state.win, 'relativenumber', false)

    -- Set up syntax highlighting
    setup_highlights()
end

-- Initialize the game level
local function init_level(level_num)
    local level = game.get_level(level_num)
    state.level = level_num

    -- Generate map
    state.map = game.MapGenerator.create_room(level.width, level.height, level.type)
    state.map = game.MapGenerator.add_obstacles(state.map, level.obstacle_density)

    -- Clear entities
    state.entities = {}

    -- Create player
    local player_x = math.floor(level.width / 2)
    local player_y = math.floor(level.height / 2)
    state.player = game.Entity:new(player_x, player_y, game.sprites.player_alt, "player")

    -- Add enemies
    for i = 1, level.enemies do
        local x = math.random(2, level.width - 1)
        local y = math.random(2, level.height - 1)
        local enemy_types = {"enemy_slime", "enemy_skeleton", "enemy_bat"}
        local enemy_type = enemy_types[math.random(#enemy_types)]
        local enemy = game.Entity:new(x, y, game.sprites[enemy_type] or "E", "enemy")
        table.insert(state.entities, enemy)
    end

    -- Add items
    for i = 1, level.items do
        local x = math.random(2, level.width - 1)
        local y = math.random(2, level.height - 1)
        local item_types = {"coin", "heart", "key"}
        local item_type = item_types[math.random(#item_types)]
        local sprite = game.sprites[item_type] or "*"
        local item = game.Entity:new(x, y, sprite, item_type)
        table.insert(state.entities, item)
    end

    -- Start quest
    local next_quest = quests.get_next_quest()
    if next_quest then
        state.current_quest = quests.start_quest(next_quest.id)
        show_notification(string.format("New Quest: %s", next_quest.name), "info")
    end
end

-- Render the game with improved visuals
local function render()
    if not state.buf or not api.nvim_buf_is_valid(state.buf) then
        return
    end

    local lines = {}
    local highlights = {}

    -- Create HUD
    local hud = game.UI.create_hud(state.stats)
    for _, line in ipairs(hud) do
        table.insert(lines, line)
    end

    table.insert(lines, string.rep("─", M.config.width))

    -- Render map
    local map_display = vim.deepcopy(state.map)

    -- Place entities on map
    for _, entity in ipairs(state.entities) do
        if entity.active then
            map_display[entity.y][entity.x] = entity.sprite
        end
    end

    -- Place particles
    for _, particle in ipairs(game.particles_list) do
        if map_display[particle.y] and map_display[particle.y][particle.x] then
            map_display[particle.y][particle.x] = particle.sprite
        end
    end

    -- Place player
    map_display[state.player.y][state.player.x] = state.player.sprite

    -- Convert map to lines
    for y = 1, #map_display do
        local line = ""
        for x = 1, #map_display[y] do
            line = line .. (map_display[y][x] or " ")
        end
        table.insert(lines, line)
    end

    -- Add status and instructions
    table.insert(lines, string.rep("─", M.config.width))

    -- Quest status
    if state.current_quest then
        table.insert(lines, string.format("Quest: %s", state.current_quest.name))
    end

    -- Controls hint
    table.insert(lines, "Controls: hjkl=move w/b=jump gg/G=top/bottom d=attack y=collect /=search q=quit")

    -- Update buffer
    api.nvim_buf_set_option(state.buf, 'modifiable', true)
    api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
    api.nvim_buf_set_option(state.buf, 'modifiable', false)

    -- Apply highlights if enabled
    if M.config.enable_colors then
        apply_highlights(highlights)
    end

    -- Update animations
    if M.config.enable_animations then
        game.Animations.update()
    end

    -- Update particles
    if M.config.enable_particles then
        game.Particles.update()
    end
end

-- Setup syntax highlighting
local function setup_highlights()
    -- Define highlight groups
    local highlights = {
        ZeldaPlayer = {fg = "#00ff00", bold = true},
        ZeldaEnemy = {fg = "#ff0000", bold = true},
        ZeldaItem = {fg = "#ffff00", bold = true},
        ZeldaWall = {fg = "#888888"},
        ZeldaGrass = {fg = "#228822"},
        ZeldaWater = {fg = "#0088ff"},
        ZeldaHeart = {fg = "#ff0088", bold = true},
        ZeldaCoin = {fg = "#ffaa00", bold = true},
        ZeldaKey = {fg = "#ffff00", bold = true},
    }

    for group, opts in pairs(highlights) do
        api.nvim_set_hl(0, group, opts)
    end
end

-- Apply highlights to buffer
local function apply_highlights(highlight_list)
    -- Clear existing highlights
    if state.ns_id and state.buf then
        api.nvim_buf_clear_namespace(state.buf, state.ns_id, 0, -1)
    end

    -- Apply new highlights
    for _, hl in ipairs(highlight_list) do
        api.nvim_buf_add_highlight(
            state.buf,
            state.ns_id,
            hl.group,
            hl.line,
            hl.col_start,
            hl.col_end
        )
    end
end

-- Enhanced movement with animations
local function move_player(direction)
    local dx, dy = 0, 0

    -- Calculate movement based on direction
    local movements = {
        h = {-1, 0},
        l = {1, 0},
        j = {0, 1},
        k = {0, -1},
        w = {5, 0},   -- Word jump
        b = {-5, 0},  -- Word back
    }

    if movements[direction] then
        dx, dy = movements[direction][1], movements[direction][2]
    elseif direction == "gg" then
        -- Jump to top
        dy = 1 - state.player.y
    elseif direction == "G" then
        -- Jump to bottom
        dy = #state.map - state.player.y
    end

    -- Try to move
    local old_x, old_y = state.player.x, state.player.y
    if state.player:move(dx, dy, state.map) then
        state.stats.steps = state.stats.steps + 1

        -- Update quest progress
        if state.current_quest then
            quests.update_progress(direction)
        end

        -- Check collisions
        check_collisions()

        -- Add movement particle effect
        if M.config.enable_particles then
            game.Particles.create(old_x, old_y, "sparkle", 3)
        end

        -- Sound feedback
        if M.config.sound_feedback then
            show_notification("*step*", "debug", 100)
        end
    else
        -- Hit wall feedback
        if M.config.sound_feedback then
            show_notification("*bump*", "warn", 500)
        end
    end

    render()
end

-- Check collisions with entities
local function check_collisions()
    for i = #state.entities, 1, -1 do
        local entity = state.entities[i]
        if entity.active and entity.x == state.player.x and entity.y == state.player.y then
            if entity.type == "coin" then
                state.stats.coins = state.stats.coins + 1
                state.score = state.score + 10
                entity.active = false
                show_notification("💰 Coin collected! +10 points", "info")

                if M.config.enable_particles then
                    game.Particles.create(entity.x, entity.y, "sparkle", 5)
                end
            elseif entity.type == "heart" then
                state.stats.health = math.min(state.stats.health + 1, state.stats.max_health)
                entity.active = false
                show_notification("❤️ Health restored!", "info")

                if M.config.enable_particles then
                    game.Particles.create(entity.x, entity.y, "sparkle", 5)
                end
            elseif entity.type == "key" then
                state.stats.keys = state.stats.keys + 1
                entity.active = false
                show_notification("🔑 Key found!", "info")

                if M.config.enable_particles then
                    game.Particles.create(entity.x, entity.y, "sparkle", 5)
                end
            elseif entity.type == "enemy" then
                -- Take damage
                state.stats.health = state.stats.health - 1
                show_notification("💔 Ouch! Use 'd' to attack!", "error")

                if state.stats.health <= 0 then
                    game_over()
                end
            end
        end
    end
end

-- Attack action with animation
local function attack()
    -- Create attack animation
    if M.config.enable_animations then
        game.Animations.create(state.player, "attack")
    end

    -- Check for adjacent enemies
    for i = #state.entities, 1, -1 do
        local entity = state.entities[i]
        if entity.active and entity.type == "enemy" then
            local dist = math.abs(entity.x - state.player.x) + math.abs(entity.y - state.player.y)
            if dist <= 1 then
                entity.health = entity.health - 1

                if entity.health <= 0 then
                    entity.active = false
                    state.stats.enemies_defeated = state.stats.enemies_defeated + 1
                    state.score = state.score + 25
                    show_notification("⚔️ Enemy defeated! +25 points", "info")

                    if M.config.enable_particles then
                        game.Particles.create(entity.x, entity.y, "explosion", 8)
                    end

                    -- Update quest
                    if state.current_quest then
                        quests.update_progress("d")
                    end
                else
                    show_notification("💥 Enemy hit!", "info")

                    if M.config.enable_animations then
                        game.Animations.create(entity, "hurt")
                    end
                end

                break
            end
        end
    end

    render()
end

-- Show notification with vim.notify
function show_notification(msg, level, timeout)
    level = level or "info"
    local log_level = {
        debug = vim.log.levels.DEBUG,
        info = vim.log.levels.INFO,
        warn = vim.log.levels.WARN,
        error = vim.log.levels.ERROR,
    }

    vim.notify(msg, log_level[level], {
        title = "Neovim Zelda",
        timeout = timeout or 2000,
    })
end

-- Game over handler
local function game_over()
    show_notification(string.format("Game Over! Final Score: %d", state.score), "error", 5000)

    -- Show stats
    local stats_msg = string.format(
        "Stats:\nEnemies Defeated: %d\nItems Collected: %d\nSteps Taken: %d",
        state.stats.enemies_defeated,
        state.stats.items_collected,
        state.stats.steps
    )
    show_notification(stats_msg, "info", 10000)

    -- Close after delay
    vim.defer_fn(function()
        M.quit()
    end, 5000)
end

-- Victory handler
local function victory()
    show_notification("🎉 Victory! Level Complete!", "info", 3000)

    -- Progress to next level
    if state.level < #game.Levels then
        state.level = state.level + 1
        show_notification(string.format("Advancing to Level %d...", state.level), "info")
        vim.defer_fn(function()
            init_level(state.level)
            render()
        end, 2000)
    else
        show_notification("🏆 Congratulations! You've mastered Neovim Zelda!", "info", 10000)
        vim.defer_fn(function()
            M.quit()
        end, 5000)
    end
end

-- Setup key mappings
local function setup_mappings()
    local mappings = {
        -- Movement
        ['h'] = function() move_player('h') end,
        ['j'] = function() move_player('j') end,
        ['k'] = function() move_player('k') end,
        ['l'] = function() move_player('l') end,
        ['w'] = function() move_player('w') end,
        ['b'] = function() move_player('b') end,
        ['gg'] = function() move_player('gg') end,
        ['G'] = function() move_player('G') end,

        -- Actions
        ['d'] = attack,
        ['y'] = function() show_notification("Move over items to collect them!", "info") end,
        ['/'] = function() show_notification("Search: Use / followed by text in vim!", "info") end,

        -- Game
        ['q'] = function() M.quit() end,
        ['?'] = function() M.show_help() end,
        ['r'] = function() init_level(state.level); render() end,
    }

    for key, func in pairs(mappings) do
        api.nvim_buf_set_keymap(state.buf, 'n', key, '', {
            callback = func,
            noremap = true,
            silent = true
        })
    end
end

-- Game update loop
local function update_game()
    if not state.initialized then
        return
    end

    -- Update entities
    for _, entity in ipairs(state.entities) do
        if entity.active then
            entity:update(state.map, state.player, state.entities)
        end
    end

    -- Check victory condition
    local enemies_left = 0
    for _, entity in ipairs(state.entities) do
        if entity.active and entity.type == "enemy" then
            enemies_left = enemies_left + 1
        end
    end

    if enemies_left == 0 then
        victory()
    end

    render()
end

-- Show help
function M.show_help()
    local help = [[
╔══════════════════════════════════════════╗
║          NEOVIM ZELDA - HELP             ║
╠══════════════════════════════════════════╣
║ MOVEMENT:                                 ║
║   hjkl - Basic movement                  ║
║   w/b  - Jump forward/backward           ║
║   gg/G - Jump to top/bottom              ║
║                                          ║
║ ACTIONS:                                 ║
║   d - Attack (when near enemy)           ║
║   y - Yank/collect reminder              ║
║   / - Search tutorial                    ║
║                                          ║
║ GAME:                                    ║
║   r - Restart level                      ║
║   ? - Show this help                     ║
║   q - Quit game                          ║
║                                          ║
║ OBJECTIVES:                              ║
║   - Defeat all enemies                   ║
║   - Collect coins and items              ║
║   - Complete quests to learn vim         ║
║   - Progress through levels              ║
╚══════════════════════════════════════════╝
    ]]
    show_notification(help, "info", 10000)
end

-- Start the game
function M.start()
    if state.initialized then
        show_notification("Game already running!", "warn")
        return
    end

    state.initialized = true
    state.score = 0

    create_window()
    init_level(1)
    setup_mappings()
    render()

    -- Start game loop
    state.timers.update = vim.fn.timer_start(500, function()
        update_game()
    end, {['repeat'] = -1})

    show_notification("Welcome to Neovim Zelda! Press ? for help", "info")
end

-- Quit the game
function M.quit()
    state.initialized = false

    -- Stop timers
    for _, timer in pairs(state.timers) do
        vim.fn.timer_stop(timer)
    end
    state.timers = {}

    -- Close window
    if state.win and api.nvim_win_is_valid(state.win) then
        api.nvim_win_close(state.win, true)
    end

    show_notification(string.format("Thanks for playing! Final Score: %d", state.score), "info")
end

-- Public API
M.move = move_player
M.attack = attack

return M