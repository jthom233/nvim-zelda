
-- nvim-zelda Core: Streamlined gameplay-focused version
local M = {}
local api = vim.api

-- Load core systems
M.health = require("nvim-zelda.systems.health")
M.items = require("nvim-zelda.systems.items")
M.quests = require("nvim-zelda.systems.quests")

-- Game state (no save/load)
M.state = {
    -- Core
    running = false,
    buf = nil,
    win = nil,
    ns_id = nil,

    -- Player
    player = {
        x = 10,
        y = 10,
        level = 1,
        xp = 0,
        speed = 1,
        damage = 10,
        armor = 0,
        vim_power = 1,
        luck = 1
    },

    -- World
    enemies = {},
    items_on_ground = {},
    current_room = 1,
    rooms_cleared = 0,

    -- Stats (session only)
    session_stats = {
        enemies_killed = 0,
        items_collected = 0,
        damage_dealt = 0,
        damage_taken = 0,
        commands_used = 0,
        play_time = 0,
        best_combo = 0
    }
}

-- Initialize game
function M.setup(opts)
    M.config = vim.tbl_extend("force", {
        width = 80,
        height = 30,
        difficulty = "normal"
    }, opts or {})

    M.state.ns_id = api.nvim_create_namespace("nvim_zelda")
end

-- Start new game (no loading)
function M.start()
    if M.state.running then
        vim.notify("Game already running!", vim.log.levels.WARN)
        return
    end

    -- Initialize systems
    M.health:init(M.state.player)
    M.items:init()
    M.quests:init()

    -- Create game window
    M.create_window()

    -- Spawn initial room
    M.spawn_room()

    -- Start game loop
    M.state.running = true
    M.game_loop()

    vim.notify("🎮 Game Started! No saves - make this run count!", vim.log.levels.INFO)
    vim.notify("💡 Press ? for help, i for inventory, q for quests", vim.log.levels.INFO)
end

-- Create game window
function M.create_window()
    M.state.buf = api.nvim_create_buf(false, true)
    api.nvim_buf_set_option(M.state.buf, 'buftype', 'nofile')
    api.nvim_buf_set_option(M.state.buf, 'swapfile', false)

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
        title = ' ⚔️ nvim-zelda: Room ' .. M.state.current_room .. ' ⚔️ ',
        title_pos = 'center'
    })

    -- Set up controls
    M.setup_controls()
end

-- Setup controls
function M.setup_controls()
    local keymaps = {
        -- Movement
        ['h'] = function() M.move_player(-1, 0) end,
        ['j'] = function() M.move_player(0, 1) end,
        ['k'] = function() M.move_player(0, -1) end,
        ['l'] = function() M.move_player(1, 0) end,

        -- Combat
        ['x'] = function() M.attack() end,
        ['d'] = function() M.special_attack("delete") end,

        -- Items
        ['e'] = function() M.pickup_item() end,
        ['u'] = function() M.use_item_quick() end,

        -- UI
        ['i'] = function() M.show_inventory() end,
        ['q'] = function() M.show_quests() end,
        ['?'] = function() M.show_help() end,

        -- Quit (no save)
        ['Q'] = function() M.quit() end,
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
    if new_x < 2 or new_x > 78 or new_y < 2 or new_y > 28 then
        return
    end

    -- Check enemy collision
    for _, enemy in ipairs(M.state.enemies) do
        if enemy.x == new_x and enemy.y == new_y then
            -- Take damage
            local damage_result = M.health:take_damage(enemy.damage, enemy.damage_type, enemy)
            vim.notify(damage_result.message, vim.log.levels.WARN)

            -- Check death
            if M.state.player.health <= 0 then
                M.game_over()
            end
            return
        end
    end

    -- Move
    M.state.player.x = new_x
    M.state.player.y = new_y

    -- Update quest progress
    M.quests:update_progress("move_with_hjkl", 1)

    -- Check item pickup
    M.check_item_pickup()

    -- Check room exit
    M.check_room_exit()

    M.render()
end

-- Attack
function M.attack()
    local killed = {}

    for i = #M.state.enemies, 1, -1 do
        local enemy = M.state.enemies[i]
        if math.abs(enemy.x - M.state.player.x) <= 1 and
           math.abs(enemy.y - M.state.player.y) <= 1 then
            enemy.health = enemy.health - M.state.player.damage

            if enemy.health <= 0 then
                table.insert(killed, enemy)
                table.remove(M.state.enemies, i)

                -- Drop items
                local drops = M.items:generate_drop(enemy.level, M.state.player.luck)
                for _, item in ipairs(drops) do
                    table.insert(M.state.items_on_ground, {
                        item = item,
                        x = enemy.x,
                        y = enemy.y
                    })
                end

                -- Update stats
                M.state.session_stats.enemies_killed = M.state.session_stats.enemies_killed + 1
                M.quests:update_progress("defeat_enemies", 1)

                -- XP
                M.state.player.xp = M.state.player.xp + enemy.xp_value
                vim.notify("+1" .. enemy.xp_value .. " XP", vim.log.levels.INFO)
            end
        end
    end

    if #killed > 0 then
        vim.notify("Defeated " .. #killed .. " enemies!", vim.log.levels.INFO)
    end

    M.render()
end

-- Check item pickup
function M.check_item_pickup()
    for i = #M.state.items_on_ground, 1, -1 do
        local item_drop = M.state.items_on_ground[i]
        if item_drop.x == M.state.player.x and item_drop.y == M.state.player.y then
            if M.items:add_to_inventory(item_drop.item) then
                table.remove(M.state.items_on_ground, i)
                M.quests:update_progress("collect_items", 1)
            end
        end
    end
end

-- Spawn room
function M.spawn_room()
    M.state.enemies = {}
    M.state.items_on_ground = {}

    -- Spawn enemies based on room number
    local enemy_count = 2 + math.floor(M.state.current_room / 2)
    for i = 1, enemy_count do
        table.insert(M.state.enemies, {
            x = math.random(10, 70),
            y = math.random(5, 25),
            sprite = "👹",
            health = 20 + (M.state.current_room * 5),
            damage = 5 + M.state.current_room,
            damage_type = "physical",
            level = M.state.current_room,
            xp_value = 10 * M.state.current_room
        })
    end

    -- Spawn some items
    local item_count = math.random(1, 3)
    for i = 1, item_count do
        local item = M.items.database[math.random(#M.items.database)]
        table.insert(M.state.items_on_ground, {
            item = item,
            x = math.random(10, 70),
            y = math.random(5, 25)
        })
    end
end

-- Check room exit
function M.check_room_exit()
    if #M.state.enemies == 0 then
        if M.state.player.x >= 77 then
            -- Next room
            M.state.current_room = M.state.current_room + 1
            M.state.rooms_cleared = M.state.rooms_cleared + 1
            M.state.player.x = 3
            M.spawn_room()
            vim.notify("🚪 Entered Room " .. M.state.current_room, vim.log.levels.INFO)

            -- Heal a bit between rooms
            M.health:heal(10, "regen")
        end
    end
end

-- Show inventory
function M.show_inventory()
    local display = M.items:get_inventory_display()
    vim.notify(display, vim.log.levels.INFO)
end

-- Show quests
function M.show_quests()
    local display = M.quests:get_quest_display()
    vim.notify(display, vim.log.levels.INFO)
end

-- Use item quickly (slot 1)
function M.use_item_quick()
    local result, message = M.items:use_item(1, M.state.player)
    vim.notify(message, result and vim.log.levels.INFO or vim.log.levels.WARN)
    M.render()
end

-- Render game
function M.render()
    if not M.state.buf or not api.nvim_buf_is_valid(M.state.buf) then
        return
    end

    local lines = {}

    -- Create map
    for y = 1, 30 do
        local line = ""
        for x = 1, 80 do
            local char = " "

            -- Borders
            if y == 1 or y == 30 then
                char = "═"
            elseif x == 1 or x == 80 then
                char = "║"
            -- Player
            elseif x == M.state.player.x and y == M.state.player.y then
                char = "@"
            else
                -- Enemies
                local found = false
                for _, enemy in ipairs(M.state.enemies) do
                    if enemy.x == x and enemy.y == y then
                        char = enemy.sprite
                        found = true
                        break
                    end
                end

                -- Items
                if not found then
                    for _, item_drop in ipairs(M.state.items_on_ground) do
                        if item_drop.x == x and item_drop.y == y then
                            char = item_drop.item.sprite
                            break
                        end
                    end
                end
            end

            line = line .. char
        end
        table.insert(lines, line)
    end

    -- HUD
    table.insert(lines, "")

    -- Health display
    local health_display = M.health:get_display()
    table.insert(lines, health_display.text)

    -- Stats line
    table.insert(lines, string.format("Room: %d | XP: %d | Enemies: %d | Items: %d",
                                     M.state.current_room,
                                     M.state.player.xp,
                                     #M.state.enemies,
                                     #M.items.inventory.slots))

    -- Quest progress (if active)
    if M.quests.active.main then
        local quest = M.quests.active.main
        local next_obj = nil
        for _, obj in ipairs(quest.objectives) do
            if not obj.completed then
                next_obj = obj
                break
            end
        end
        if next_obj then
            table.insert(lines, string.format("Quest: %s (%d/%d)",
                                             next_obj.description,
                                             next_obj.progress,
                                             next_obj.required))
        end
    end

    -- Controls reminder
    table.insert(lines, "Controls: hjkl=move | x=attack | e=pickup | i=inventory | q=quests | Q=quit")

    -- Update buffer
    api.nvim_buf_set_lines(M.state.buf, 0, -1, false, lines)
end

-- Game loop
function M.game_loop()
    if not M.state.running then return end

    -- Update systems
    M.state.session_stats.play_time = M.state.session_stats.play_time + 1

    -- Enemy AI (simple)
    for _, enemy in ipairs(M.state.enemies) do
        if math.random() > 0.7 then
            local dx = 0
            local dy = 0
            if enemy.x < M.state.player.x then dx = 1
            elseif enemy.x > M.state.player.x then dx = -1
            end
            if enemy.y < M.state.player.y then dy = 1
            elseif enemy.y > M.state.player.y then dy = -1
            end

            enemy.x = math.max(2, math.min(78, enemy.x + dx))
            enemy.y = math.max(2, math.min(28, enemy.y + dy))
        end
    end

    -- Render
    M.render()

    -- Continue loop
    vim.defer_fn(function()
        M.game_loop()
    end, 100)
end

-- Game over
function M.game_over()
    M.state.running = false

    vim.notify("💀 GAME OVER!", vim.log.levels.ERROR)
    vim.notify("Final Stats:", vim.log.levels.INFO)
    vim.notify("  Rooms Cleared: " .. M.state.rooms_cleared, vim.log.levels.INFO)
    vim.notify("  Enemies Killed: " .. M.state.session_stats.enemies_killed, vim.log.levels.INFO)
    vim.notify("  Items Collected: " .. M.state.session_stats.items_collected, vim.log.levels.INFO)
    vim.notify("  Total XP: " .. M.state.player.xp, vim.log.levels.INFO)

    M.quit()
end

-- Quit game (no save)
function M.quit()
    M.state.running = false

    if M.state.win and api.nvim_win_is_valid(M.state.win) then
        api.nvim_win_close(M.state.win, true)
    end

    if M.state.buf and api.nvim_buf_is_valid(M.state.buf) then
        api.nvim_buf_delete(M.state.buf, {force = true})
    end

    vim.notify("Thanks for playing! (No save - start fresh next time!)", vim.log.levels.INFO)
end

-- Show help
function M.show_help()
    local help = [[
=== CONTROLS ===
h/j/k/l - Move
x - Attack adjacent enemies
d - Special delete attack
e - Pickup items
u - Use item in slot 1
i - Show inventory
q - Show quests
? - This help
Q - Quit (no save)

=== TIPS ===
- Clear enemies to proceed to next room
- Complete quests for rewards
- Manage health carefully - no saves!
- Items drop from enemies
- Each room gets harder
]]
    vim.notify(help, vim.log.levels.INFO)
end

-- Commands
vim.api.nvim_create_user_command('Zelda', function() M.start() end, {})
vim.api.nvim_create_user_command('ZeldaQuit', function() M.quit() end, {})

return M
