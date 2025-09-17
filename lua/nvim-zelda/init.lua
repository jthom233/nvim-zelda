-- nvim-zelda: A Zelda-inspired game to learn Neovim
-- Learn vim motions and commands through gameplay!

local M = {}
local api = vim.api
local fn = vim.fn

-- Game state
local game_state = {
    initialized = false,
    level = 1,
    score = 0,
    player_pos = {row = 10, col = 10},
    enemies = {},
    items = {},
    messages = {},
    current_quest = nil,
    commands_used = {},
    buf = nil,
    win = nil,
}

-- ASCII Art characters
local sprites = {
    player = "@",
    enemy = "E",
    item = "*",
    wall = "#",
    door = "D",
    chest = "C",
    heart = "♥",
    sword = "†",
    key = "K",
    empty = " ",
    grass = ".",
}

-- Game configuration
M.config = {
    width = 60,
    height = 20,
    teach_mode = true,
    difficulty = "normal",
}

-- Initialize the game
function M.setup(opts)
    M.config = vim.tbl_extend("force", M.config, opts or {})
end

-- Create game buffer and window
local function create_game_window()
    -- Create a new buffer
    game_state.buf = api.nvim_create_buf(false, true)

    -- Set buffer options
    api.nvim_buf_set_option(game_state.buf, 'buftype', 'nofile')
    api.nvim_buf_set_option(game_state.buf, 'bufhidden', 'wipe')
    api.nvim_buf_set_option(game_state.buf, 'swapfile', false)
    api.nvim_buf_set_option(game_state.buf, 'modifiable', false)

    -- Create a floating window
    local width = M.config.width
    local height = M.config.height
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local win_opts = {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
        style = 'minimal',
        border = 'rounded',
        title = ' nvim-zelda ',
        title_pos = 'center',
    }

    game_state.win = api.nvim_open_win(game_state.buf, true, win_opts)

    -- Set window-local options
    api.nvim_win_set_option(game_state.win, 'wrap', false)
    api.nvim_win_set_option(game_state.win, 'cursorline', true)
end

-- Generate the game map
local function generate_map()
    local map = {}

    -- Create empty map
    for i = 1, M.config.height do
        map[i] = {}
        for j = 1, M.config.width do
            -- Add borders
            if i == 1 or i == M.config.height or j == 1 or j == M.config.width then
                map[i][j] = sprites.wall
            else
                map[i][j] = sprites.grass
            end
        end
    end

    -- Add some random items
    for _ = 1, 5 do
        local row = math.random(2, M.config.height - 1)
        local col = math.random(2, M.config.width - 1)
        map[row][col] = sprites.item
        table.insert(game_state.items, {row = row, col = col, type = "coin"})
    end

    -- Add enemies
    for _ = 1, 3 do
        local row = math.random(2, M.config.height - 1)
        local col = math.random(2, M.config.width - 1)
        map[row][col] = sprites.enemy
        table.insert(game_state.enemies, {row = row, col = col, health = 1})
    end

    -- Place player
    map[game_state.player_pos.row][game_state.player_pos.col] = sprites.player

    return map
end

-- Render the game
local function render()
    local map = generate_map()
    local lines = {}

    -- Convert map to lines
    for i = 1, M.config.height do
        local line = table.concat(map[i], "")
        table.insert(lines, line)
    end

    -- Add status line
    table.insert(lines, "")
    table.insert(lines, string.format("Score: %d | Level: %d | Quest: %s",
        game_state.score,
        game_state.level,
        game_state.current_quest or "Explore!"))

    -- Add instructions
    if M.config.teach_mode then
        table.insert(lines, "")
        table.insert(lines, "Commands: hjkl=move | d=attack | y=collect | /=search | q=quit")
        table.insert(lines, "Vim Motions: w=word forward | b=word back | gg=top | G=bottom")
    end

    -- Update buffer
    api.nvim_buf_set_option(game_state.buf, 'modifiable', true)
    api.nvim_buf_set_lines(game_state.buf, 0, -1, false, lines)
    api.nvim_buf_set_option(game_state.buf, 'modifiable', false)
end

-- Handle player movement
local function move_player(direction)
    local new_pos = {
        row = game_state.player_pos.row,
        col = game_state.player_pos.col
    }

    -- Calculate new position based on direction
    if direction == "h" then
        new_pos.col = new_pos.col - 1
    elseif direction == "l" then
        new_pos.col = new_pos.col + 1
    elseif direction == "j" then
        new_pos.row = new_pos.row + 1
    elseif direction == "k" then
        new_pos.row = new_pos.row - 1
    elseif direction == "w" then
        new_pos.col = new_pos.col + 5  -- Word jump
    elseif direction == "b" then
        new_pos.col = new_pos.col - 5  -- Word back
    elseif direction == "gg" then
        new_pos.row = 2  -- Top
    elseif direction == "G" then
        new_pos.row = M.config.height - 1  -- Bottom
    end

    -- Check boundaries
    if new_pos.row > 1 and new_pos.row < M.config.height and
       new_pos.col > 1 and new_pos.col < M.config.width then
        game_state.player_pos = new_pos

        -- Check for item collection
        for i, item in ipairs(game_state.items) do
            if item.row == new_pos.row and item.col == new_pos.col then
                game_state.score = game_state.score + 10
                table.remove(game_state.items, i)
                show_message("Item collected! +10 points")

                -- Teaching moment
                if M.config.teach_mode then
                    show_message("Great! You used vim motion to move. Try 'y' to yank items!")
                end
                break
            end
        end

        -- Check for enemy collision
        for _, enemy in ipairs(game_state.enemies) do
            if enemy.row == new_pos.row and enemy.col == new_pos.col then
                show_message("Enemy encountered! Press 'd' to defeat!")
            end
        end
    end

    render()
end

-- Handle attack action
local function attack()
    local pos = game_state.player_pos

    -- Check adjacent cells for enemies
    for i, enemy in ipairs(game_state.enemies) do
        local dist = math.abs(enemy.row - pos.row) + math.abs(enemy.col - pos.col)
        if dist <= 1 then
            table.remove(game_state.enemies, i)
            game_state.score = game_state.score + 25
            show_message("Enemy defeated! +25 points")

            if M.config.teach_mode then
                show_message("Nice! 'd' is for delete in vim. Try 'dd' to delete a line!")
            end

            render()
            return
        end
    end

    show_message("No enemy nearby!")
end

-- Show message to player
function show_message(msg)
    vim.notify(msg, vim.log.levels.INFO, {title = "nvim-zelda"})
    table.insert(game_state.messages, msg)
end

-- Setup key mappings
local function setup_mappings()
    local buf = game_state.buf

    -- Movement
    api.nvim_buf_set_keymap(buf, 'n', 'h', '<cmd>lua require("nvim-zelda").move("h")<CR>', {silent = true})
    api.nvim_buf_set_keymap(buf, 'n', 'j', '<cmd>lua require("nvim-zelda").move("j")<CR>', {silent = true})
    api.nvim_buf_set_keymap(buf, 'n', 'k', '<cmd>lua require("nvim-zelda").move("k")<CR>', {silent = true})
    api.nvim_buf_set_keymap(buf, 'n', 'l', '<cmd>lua require("nvim-zelda").move("l")<CR>', {silent = true})

    -- Word movements
    api.nvim_buf_set_keymap(buf, 'n', 'w', '<cmd>lua require("nvim-zelda").move("w")<CR>', {silent = true})
    api.nvim_buf_set_keymap(buf, 'n', 'b', '<cmd>lua require("nvim-zelda").move("b")<CR>', {silent = true})

    -- Line movements
    api.nvim_buf_set_keymap(buf, 'n', 'gg', '<cmd>lua require("nvim-zelda").move("gg")<CR>', {silent = true})
    api.nvim_buf_set_keymap(buf, 'n', 'G', '<cmd>lua require("nvim-zelda").move("G")<CR>', {silent = true})

    -- Actions
    api.nvim_buf_set_keymap(buf, 'n', 'd', '<cmd>lua require("nvim-zelda").attack()<CR>', {silent = true})
    api.nvim_buf_set_keymap(buf, 'n', 'y', '<cmd>lua require("nvim-zelda").collect()<CR>', {silent = true})

    -- Quit
    api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>lua require("nvim-zelda").quit()<CR>', {silent = true})

    -- Search tutorial
    api.nvim_buf_set_keymap(buf, 'n', '/', '<cmd>lua require("nvim-zelda").search_tutorial()<CR>', {silent = true})
end

-- Search tutorial
function M.search_tutorial()
    show_message("In vim, '/' starts a search. Try '/item' to find items!")
    show_message("Press 'n' for next match, 'N' for previous")
end

-- Public functions
function M.move(direction)
    move_player(direction)
end

function M.attack()
    attack()
end

function M.collect()
    show_message("Press 'y' to yank (copy) in vim. Move over an item first!")
end

function M.quit()
    if game_state.win and api.nvim_win_is_valid(game_state.win) then
        api.nvim_win_close(game_state.win, true)
    end
    game_state.initialized = false
    show_message("Thanks for playing nvim-zelda! Your score: " .. game_state.score)
end

-- Start the game
function M.start()
    if game_state.initialized then
        show_message("Game already running!")
        return
    end

    game_state.initialized = true
    game_state.score = 0
    game_state.level = 1
    game_state.enemies = {}
    game_state.items = {}

    create_game_window()
    setup_mappings()
    render()

    show_message("Welcome to nvim-zelda! Learn vim while playing!")
    show_message("Use hjkl to move, 'd' to attack, 'y' to collect items")
end

return M