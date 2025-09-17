-- nvim-zelda: Robust version with fallbacks
local M = {}
local api = vim.api

-- Safe module loading with fallbacks
local function safe_require(module_name)
    local ok, module = pcall(require, module_name)
    if ok then
        return module
    else
        vim.notify("Warning: Failed to load " .. module_name .. ": " .. tostring(module), vim.log.levels.WARN)
        return nil
    end
end

-- Try to load systems with fallbacks
M.health = safe_require("nvim-zelda.systems.health")
M.items = safe_require("nvim-zelda.systems.items")
M.quests = safe_require("nvim-zelda.systems.quests")

-- Fallback to simple version if systems fail
if not M.health or not M.items or not M.quests then
    vim.notify("Loading simple version without advanced systems", vim.log.levels.INFO)

    -- Simple fallback implementations
    M.health = {
        state = { current_hp = 100, max_hp = 100 },
        init = function() end,
        take_damage = function(self, amount)
            self.state.current_hp = math.max(0, self.state.current_hp - amount)
            return { message = "-" .. amount .. " HP", remaining_hp = self.state.current_hp }
        end,
        heal = function(self, amount)
            self.state.current_hp = math.min(self.state.max_hp, self.state.current_hp + amount)
            return { message = "+" .. amount .. " HP" }
        end,
        get_display = function(self)
            return {
                text = "HP: " .. self.state.current_hp .. "/" .. self.state.max_hp,
                hp_percent = self.state.current_hp / self.state.max_hp
            }
        end
    }

    M.items = {
        inventory = { slots = {} },
        database = {
            { id = "potion", name = "Potion", sprite = "🧪", drop_rate = 0.3 }
        },
        init = function() end,
        add_to_inventory = function(self, item)
            table.insert(self.inventory.slots, item)
            return true
        end,
        generate_drop = function() return {} end,
        get_inventory_display = function()
            return "Inventory: Basic mode"
        end,
        use_item = function()
            return true, "Item used"
        end
    }

    M.quests = {
        active = { main = nil },
        init = function() end,
        update_progress = function() end,
        get_quest_display = function()
            return "Quests: Basic mode"
        end
    }
end

-- Game state
M.state = {
    running = false,
    buf = nil,
    win = nil,
    ns_id = nil,

    player = {
        x = 10,
        y = 10,
        level = 1,
        xp = 0,
        damage = 10
    },

    enemies = {},
    items_on_ground = {},
    current_room = 1,

    map_width = 60,
    map_height = 20
}

-- Configuration
M.config = {
    width = 70,
    height = 25,
    difficulty = "normal"
}

-- Setup function
function M.setup(opts)
    M.config = vim.tbl_extend("force", M.config, opts or {})
    M.state.ns_id = api.nvim_create_namespace("nvim_zelda")
end

-- Start game
function M.start()
    if M.state.running then
        vim.notify("Game already running!", vim.log.levels.WARN)
        return
    end

    -- Initialize systems
    M.health:init(M.state.player)
    M.items:init()
    M.quests:init()

    -- Create window
    M.create_window()

    -- Start game
    M.state.running = true
    M.spawn_room()
    M.render()

    vim.notify("🎮 nvim-zelda started! Use hjkl to move, x to attack, q to quit", vim.log.levels.INFO)
end

-- Create window
function M.create_window()
    M.state.buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_option(M.state.buf, 'buftype', 'nofile')
    api.nvim_buf_set_option(M.state.buf, 'swapfile', false)
    api.nvim_buf_set_option(M.state.buf, 'filetype', 'zelda')

    local width = M.config.width
    local height = M.config.height
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    M.state.win = api.nvim_open_win(M.state.buf, true, {
        relative = 'editor',
        row = row,
        col = col,
        width = width,
        height = height,
        style = 'minimal',
        border = 'rounded',
        title = ' ⚔️ Zelda: Room ' .. M.state.current_room .. ' ⚔️ ',
        title_pos = 'center'
    })

    -- Setup keymaps
    local keymaps = {
        ['h'] = function() M.move_player(-1, 0) end,
        ['j'] = function() M.move_player(0, 1) end,
        ['k'] = function() M.move_player(0, -1) end,
        ['l'] = function() M.move_player(1, 0) end,
        ['x'] = function() M.attack() end,
        ['i'] = function() M.show_inventory() end,
        ['?'] = function() M.show_help() end,
        ['q'] = function() M.quit() end,
        ['<Esc>'] = function() M.quit() end
    }

    for key, func in pairs(keymaps) do
        api.nvim_buf_set_keymap(M.state.buf, 'n', key, '', {
            callback = func,
            noremap = true,
            silent = true
        })
    end
end

-- Move player
function M.move_player(dx, dy)
    local new_x = M.state.player.x + dx
    local new_y = M.state.player.y + dy

    -- Check bounds
    if new_x >= 2 and new_x < M.state.map_width - 1 and
       new_y >= 2 and new_y < M.state.map_height - 1 then

        -- Check enemy collision
        for _, enemy in ipairs(M.state.enemies) do
            if enemy.x == new_x and enemy.y == new_y then
                local result = M.health:take_damage(10)
                vim.notify(result.message, vim.log.levels.WARN)

                if M.health.state.current_hp <= 0 then
                    M.game_over()
                end
                return
            end
        end

        -- Move
        M.state.player.x = new_x
        M.state.player.y = new_y

        -- Update quest if available
        if M.quests and M.quests.update_progress then
            M.quests:update_progress("move_with_hjkl", 1)
        end

        -- Check for items
        for i = #M.state.items_on_ground, 1, -1 do
            local item = M.state.items_on_ground[i]
            if item.x == new_x and item.y == new_y then
                M.items:add_to_inventory(item)
                table.remove(M.state.items_on_ground, i)
                vim.notify("Picked up item!", vim.log.levels.INFO)
            end
        end

        M.render()
    end
end

-- Attack
function M.attack()
    local killed = 0

    for i = #M.state.enemies, 1, -1 do
        local enemy = M.state.enemies[i]
        if math.abs(enemy.x - M.state.player.x) <= 1 and
           math.abs(enemy.y - M.state.player.y) <= 1 then
            table.remove(M.state.enemies, i)
            killed = killed + 1
            M.state.player.xp = M.state.player.xp + 10

            -- Drop item chance
            if math.random() > 0.7 then
                table.insert(M.state.items_on_ground, {
                    x = enemy.x,
                    y = enemy.y,
                    sprite = "💰",
                    name = "Coin"
                })
            end
        end
    end

    if killed > 0 then
        vim.notify("Defeated " .. killed .. " enemies! +10 XP", vim.log.levels.INFO)

        -- Check room clear
        if #M.state.enemies == 0 then
            vim.notify("Room cleared! Move right to continue →", vim.log.levels.INFO)
        end
    end

    M.render()
end

-- Spawn room
function M.spawn_room()
    M.state.enemies = {}
    M.state.items_on_ground = {}

    -- Spawn enemies
    local enemy_count = 2 + M.state.current_room
    for i = 1, enemy_count do
        table.insert(M.state.enemies, {
            x = math.random(10, M.state.map_width - 10),
            y = math.random(5, M.state.map_height - 5),
            sprite = "👹",
            health = 10
        })
    end

    -- Spawn items
    for i = 1, 3 do
        table.insert(M.state.items_on_ground, {
            x = math.random(5, M.state.map_width - 5),
            y = math.random(3, M.state.map_height - 3),
            sprite = "🧪",
            name = "Potion"
        })
    end
end

-- Show inventory
function M.show_inventory()
    if M.items and M.items.get_inventory_display then
        vim.notify(M.items:get_inventory_display(), vim.log.levels.INFO)
    else
        vim.notify("Inventory not available", vim.log.levels.WARN)
    end
end

-- Show help
function M.show_help()
    local help = [[
=== CONTROLS ===
h/j/k/l - Move
x - Attack
i - Inventory
? - Help
q - Quit

=== GOAL ===
Clear rooms and survive!
]]
    vim.notify(help, vim.log.levels.INFO)
end

-- Render
function M.render()
    if not M.state.buf or not api.nvim_buf_is_valid(M.state.buf) then
        return
    end

    local lines = {}

    -- Draw map
    for y = 1, M.state.map_height do
        local line = ""
        for x = 1, M.state.map_width do
            if x == 1 or x == M.state.map_width then
                line = line .. "|"
            elseif y == 1 or y == M.state.map_height then
                line = line .. "-"
            elseif x == M.state.player.x and y == M.state.player.y then
                line = line .. "@"
            else
                local char = "."

                -- Check enemies
                for _, enemy in ipairs(M.state.enemies) do
                    if enemy.x == x and enemy.y == y then
                        char = enemy.sprite
                        break
                    end
                end

                -- Check items
                if char == "." then
                    for _, item in ipairs(M.state.items_on_ground) do
                        if item.x == x and item.y == y then
                            char = item.sprite
                            break
                        end
                    end
                end

                line = line .. char
            end
        end
        table.insert(lines, line)
    end

    -- HUD
    table.insert(lines, "")

    local health_display = M.health:get_display()
    table.insert(lines, health_display.text)
    table.insert(lines, "Room: " .. M.state.current_room .. " | XP: " .. M.state.player.xp .. " | Enemies: " .. #M.state.enemies)
    table.insert(lines, "Controls: hjkl=move | x=attack | i=inventory | ?=help | q=quit")

    api.nvim_buf_set_lines(M.state.buf, 0, -1, false, lines)
end

-- Game over
function M.game_over()
    M.state.running = false
    vim.notify("💀 GAME OVER! Score: " .. M.state.player.xp, vim.log.levels.ERROR)
    M.quit()
end

-- Quit
function M.quit()
    M.state.running = false

    if M.state.win and api.nvim_win_is_valid(M.state.win) then
        api.nvim_win_close(M.state.win, true)
    end

    if M.state.buf and api.nvim_buf_is_valid(M.state.buf) then
        api.nvim_buf_delete(M.state.buf, { force = true })
    end

    vim.notify("Thanks for playing nvim-zelda!", vim.log.levels.INFO)
end

-- Commands
vim.api.nvim_create_user_command('Zelda', function() M.start() end, {})
vim.api.nvim_create_user_command('ZeldaStart', function() M.start() end, {})
vim.api.nvim_create_user_command('ZeldaQuit', function() M.quit() end, {})

return M