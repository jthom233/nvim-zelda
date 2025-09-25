
-- Procedural Generation System
local Procedural = {}

Procedural.generators = {}
Procedural.seeds = {}

function Procedural:generate_dungeon(level, seed)
    math.randomseed(seed or os.time())

    local dungeon = {
        width = 80 + (level * 10),
        height = 30 + (level * 5),
        rooms = {},
        corridors = {},
        special_rooms = {},
        theme = self:select_theme(level)
    }

    -- Generate rooms using BSP (Binary Space Partitioning)
    local function partition(x, y, w, h, depth)
        if depth > 5 or (w < 15 or h < 10) then
            -- Create room
            local room = {
                x = x + math.random(2, 4),
                y = y + math.random(2, 4),
                width = w - math.random(4, 8),
                height = h - math.random(4, 8),
                type = self:select_room_type(level),
                enemies = self:generate_enemies(level),
                treasures = self:generate_treasures(level),
                puzzle = nil
            }

            -- Add vim puzzle to some rooms
            if math.random() > 0.6 then
                room.puzzle = self:generate_vim_puzzle(level)
            end

            table.insert(dungeon.rooms, room)
            return room
        end

        -- Split space
        local split_horizontal = math.random() > 0.5
        if split_horizontal then
            local split = y + math.floor(h * (0.4 + math.random() * 0.2))
            partition(x, y, w, split - y, depth + 1)
            partition(x, split, w, y + h - split, depth + 1)
        else
            local split = x + math.floor(w * (0.4 + math.random() * 0.2))
            partition(x, y, split - x, h, depth + 1)
            partition(split, y, x + w - split, h, depth + 1)
        end
    end

    partition(0, 0, dungeon.width, dungeon.height, 0)

    -- Connect rooms with corridors
    self:connect_rooms(dungeon)

    -- Add special rooms
    self:add_special_rooms(dungeon, level)

    -- Generate minimap
    dungeon.minimap = self:generate_minimap(dungeon)

    return dungeon
end

function Procedural:generate_vim_puzzle(level)
    local puzzle_types = {
        "regex_match",     -- Match pattern in text
        "macro_sequence",  -- Record and replay macro
        "visual_block",    -- Manipulate visual blocks
        "substitution",    -- Complex substitutions
        "buffer_juggle",   -- Switch between buffers
        "mark_navigation", -- Use marks to navigate
        "fold_unfold",     -- Code folding puzzle
        "quickfix_quest"   -- Navigate quickfix list
    }

    local puzzle_type = puzzle_types[math.random(#puzzle_types)]

    local puzzle = {
        type = puzzle_type,
        difficulty = level,
        solution = self:generate_solution(puzzle_type, level),
        hints = self:generate_hints(puzzle_type),
        reward = self:calculate_puzzle_reward(level),
        time_limit = 60 + (level * 10)
    }

    return puzzle
end

function Procedural:generate_quest(player_stats)
    local quest_templates = {
        {
            type = "collection",
            template = "Collect %d %s using only %s commands",
            generate = function()
                local count = math.random(5, 15)
                local item = self:random_item()
                local command = self:select_command_restriction()
                return string.format(quest_templates[1].template, count, item, command)
            end
        },
        {
            type = "speedrun",
            template = "Complete %s in under %d seconds",
            generate = function()
                local dungeon = self:select_dungeon()
                local time = 120 + math.random(60, 180)
                return string.format(quest_templates[2].template, dungeon, time)
            end
        },
        {
            type = "no_damage",
            template = "Defeat %s without taking damage",
            generate = function()
                local boss = self:select_boss()
                return string.format(quest_templates[3].template, boss)
            end
        },
        {
            type = "combo_chain",
            template = "Perform a %d combo chain",
            generate = function()
                local length = 5 + math.random(5, 10)
                return string.format(quest_templates[4].template, length)
            end
        }
    }

    local template = quest_templates[math.random(#quest_templates)]

    return {
        id = vim.fn.sha256(os.time() .. template.type),
        description = template.generate(),
        type = template.type,
        xp_reward = 100 * player_stats.level,
        item_reward = self:generate_reward_item(player_stats.level),
        time_limit = template.type == "speedrun" and true or false
    }
end

function Procedural:generate_daily_challenge()
    -- Generate consistent daily challenge using date as seed
    local date = os.date("%Y%m%d")
    math.randomseed(tonumber(date))

    local challenge = {
        id = "daily_" .. date,
        name = self:generate_challenge_name(),
        dungeon = self:generate_dungeon(10, tonumber(date)),
        modifiers = self:select_modifiers(3),
        leaderboard_enabled = true,
        rewards = {
            completion = {xp = 500, coins = 100},
            gold = {xp = 1500, coins = 300, item = "legendary"},
            silver = {xp = 1000, coins = 200, item = "epic"},
            bronze = {xp = 750, coins = 150, item = "rare"}
        }
    }

    return challenge
end

return Procedural
