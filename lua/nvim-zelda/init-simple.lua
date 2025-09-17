-- nvim-zelda: Simple self-contained version
local M = {}
local api = vim.api
local fn = vim.fn

-- Game state
local state = {
    buf = nil,
    win = nil,
    ns_id = nil,
    player_x = 10,
    player_y = 10,
    health = 5,
    coins = 0,
    map_width = 60,
    map_height = 20,
    running = false,
}

-- Configuration
M.config = {
    width = 70,
    height = 25,
    teach_mode = true,
}

-- Setup function
function M.setup(opts)
    M.config = vim.tbl_extend("force", M.config, opts or {})
    state.ns_id = api.nvim_create_namespace("nvim_zelda")
end

-- Create game window
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

    -- Create window
    state.win = api.nvim_open_win(state.buf, true, {
        relative = 'editor',
        row = row,
        col = col,
        width = width,
        height = height,
        style = 'minimal',
        border = 'rounded',
        title = ' Zelda - Learn Vim Motions ',
        title_pos = 'center',
    })

    -- Set up keymaps
    local keymaps = {
        ['h'] = function() move_player(-1, 0) end,
        ['j'] = function() move_player(0, 1) end,
        ['k'] = function() move_player(0, -1) end,
        ['l'] = function() move_player(1, 0) end,
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
end

-- Move player
function move_player(dx, dy)
    local new_x = state.player_x + dx
    local new_y = state.player_y + dy

    -- Check boundaries
    if new_x >= 2 and new_x < state.map_width - 1 and
       new_y >= 2 and new_y < state.map_height - 1 then
        state.player_x = new_x
        state.player_y = new_y
        render_game()
    end
end

-- Render the game
function render_game()
    if not state.buf or not api.nvim_buf_is_valid(state.buf) then
        return
    end

    local lines = {}

    -- Create map
    for y = 1, state.map_height do
        local line = ""
        for x = 1, state.map_width do
            if x == 1 or x == state.map_width then
                line = line .. "|"
            elseif y == 1 or y == state.map_height then
                line = line .. "-"
            elseif x == state.player_x and y == state.player_y then
                line = line .. "@"
            else
                line = line .. "."
            end
        end
        table.insert(lines, line)
    end

    -- Add HUD
    table.insert(lines, "")
    table.insert(lines, string.format(" HP: %d  Coins: %d", state.health, state.coins))
    table.insert(lines, "")
    table.insert(lines, " Controls: h/j/k/l to move, q to quit")

    if M.config.teach_mode then
        table.insert(lines, " Tip: These are the same keys used for navigation in Vim!")
    end

    -- Update buffer
    api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
end

-- Start the game
function M.start()
    if state.running then
        vim.notify("Game already running!", vim.log.levels.WARN)
        return
    end

    state.running = true
    create_window()
    render_game()

    vim.notify("Welcome to Zelda! Use h/j/k/l to move", vim.log.levels.INFO)
end

-- Quit the game
function M.quit()
    if state.win and api.nvim_win_is_valid(state.win) then
        api.nvim_win_close(state.win, true)
    end

    if state.buf and api.nvim_buf_is_valid(state.buf) then
        api.nvim_buf_delete(state.buf, { force = true })
    end

    state.running = false
    state.buf = nil
    state.win = nil

    vim.notify("Thanks for playing!", vim.log.levels.INFO)
end

-- Commands
vim.api.nvim_create_user_command('Zelda', function() M.start() end, {})
vim.api.nvim_create_user_command('ZeldaStart', function() M.start() end, {})
vim.api.nvim_create_user_command('ZeldaQuit', function() M.quit() end, {})

return M