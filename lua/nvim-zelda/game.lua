-- Enhanced Game Engine for nvim-zelda
local M = {}

-- Better ASCII art and sprites
M.sprites = {
    -- Player sprites
    player = "🗡",
    player_alt = "@",

    -- Enemies with variety
    enemy_slime = "🟢",
    enemy_skeleton = "💀",
    enemy_bat = "🦇",
    enemy_simple = "E",

    -- Items and collectibles
    heart = "❤️",
    coin = "💰",
    key = "🔑",
    chest = "📦",
    potion = "🧪",
    sword = "⚔️",
    item_simple = "*",

    -- Environment
    wall_h = "═",
    wall_v = "║",
    wall_corner_tl = "╔",
    wall_corner_tr = "╗",
    wall_corner_bl = "╚",
    wall_corner_br = "╝",
    wall_simple = "#",

    door_closed = "🚪",
    door_open = "🚪",
    door_simple = "D",

    -- Terrain
    grass = "·",
    grass_tall = "¨",
    water = "≈",
    tree = "🌳",
    rock = "◊",
    empty = " ",

    -- Effects
    explosion = "💥",
    sparkle = "✨",
}

-- Game configuration with better defaults
M.config = {
    width = 80,
    height = 24,
    use_unicode = vim.fn.has("multi_byte") == 1,
    colors = {
        player = "Character",
        enemy = "ErrorMsg",
        item = "WarningMsg",
        wall = "Comment",
        grass = "Normal",
        water = "Constant",
        heart = "ErrorMsg",
        coin = "WarningMsg",
        UI = "StatusLine",
    }
}

-- Map generator with better level design
M.MapGenerator = {}

function M.MapGenerator.create_room(width, height, room_type)
    local room = {}

    for y = 1, height do
        room[y] = {}
        for x = 1, width do
            -- Create walls with proper corners
            if y == 1 then
                if x == 1 then
                    room[y][x] = M.sprites.wall_corner_tl
                elseif x == width then
                    room[y][x] = M.sprites.wall_corner_tr
                else
                    room[y][x] = M.sprites.wall_h
                end
            elseif y == height then
                if x == 1 then
                    room[y][x] = M.sprites.wall_corner_bl
                elseif x == width then
                    room[y][x] = M.sprites.wall_corner_br
                else
                    room[y][x] = M.sprites.wall_h
                end
            elseif x == 1 or x == width then
                room[y][x] = M.sprites.wall_v
            else
                -- Fill with appropriate terrain
                if room_type == "grass" then
                    room[y][x] = math.random() > 0.9 and M.sprites.grass_tall or M.sprites.grass
                elseif room_type == "dungeon" then
                    room[y][x] = M.sprites.empty
                elseif room_type == "water" then
                    room[y][x] = math.random() > 0.7 and M.sprites.water or M.sprites.grass
                else
                    room[y][x] = M.sprites.grass
                end
            end
        end
    end

    return room
end

-- Add obstacles and decorations
function M.MapGenerator.add_obstacles(room, density)
    local height = #room
    local width = #room[1]

    for i = 1, math.floor(width * height * density) do
        local y = math.random(2, height - 1)
        local x = math.random(2, width - 1)

        if room[y][x] == M.sprites.grass or room[y][x] == M.sprites.empty then
            local obstacle = math.random(1, 3)
            if obstacle == 1 then
                room[y][x] = M.sprites.rock
            elseif obstacle == 2 then
                room[y][x] = M.sprites.tree
            else
                room[y][x] = M.sprites.grass_tall
            end
        end
    end

    return room
end

-- Entity management
M.Entity = {}
M.Entity.__index = M.Entity

function M.Entity:new(x, y, sprite, entity_type)
    local self = setmetatable({}, M.Entity)
    self.x = x
    self.y = y
    self.sprite = sprite
    self.type = entity_type
    self.health = entity_type == "enemy" and 3 or 1
    self.active = true
    self.dx = 0
    self.dy = 0
    return self
end

function M.Entity:move(dx, dy, map)
    local new_x = self.x + dx
    local new_y = self.y + dy

    -- Check bounds
    if new_y < 1 or new_y > #map or new_x < 1 or new_x > #map[1] then
        return false
    end

    -- Check collision with walls
    local tile = map[new_y][new_x]
    if tile == M.sprites.wall_h or tile == M.sprites.wall_v or
       tile == M.sprites.wall_corner_tl or tile == M.sprites.wall_corner_tr or
       tile == M.sprites.wall_corner_bl or tile == M.sprites.wall_corner_br or
       tile == M.sprites.rock or tile == M.sprites.tree then
        return false
    end

    self.x = new_x
    self.y = new_y
    return true
end

function M.Entity:update(map, player, entities)
    if self.type == "enemy" and self.active then
        -- Simple AI: move towards player
        local dx = 0
        local dy = 0

        if math.random() > 0.5 then
            if player.x > self.x then dx = 1
            elseif player.x < self.x then dx = -1
            end
        else
            if player.y > self.y then dy = 1
            elseif player.y < self.y then dy = -1
            end
        end

        self:move(dx, dy, map)
    end
end

-- Particle effects system
M.Particles = {}
M.particles_list = {}

function M.Particles.create(x, y, particle_type, duration)
    table.insert(M.particles_list, {
        x = x,
        y = y,
        type = particle_type,
        sprite = particle_type == "explosion" and M.sprites.explosion or M.sprites.sparkle,
        duration = duration or 5,
        age = 0
    })
end

function M.Particles.update()
    for i = #M.particles_list, 1, -1 do
        local p = M.particles_list[i]
        p.age = p.age + 1
        if p.age > p.duration then
            table.remove(M.particles_list, i)
        end
    end
end

-- HUD and UI improvements
M.UI = {}

function M.UI.create_hud(stats)
    local hud = {}

    -- Health bar
    local health_bar = "HP: "
    for i = 1, stats.max_health do
        if i <= stats.health then
            health_bar = health_bar .. M.sprites.heart
        else
            health_bar = health_bar .. "🖤"
        end
    end

    -- Score and items
    local score_line = string.format("%s %d  %s %d  %s %d",
        M.sprites.coin, stats.coins or 0,
        M.sprites.key, stats.keys or 0,
        "⭐", stats.score or 0)

    -- Level and quest info
    local level_line = string.format("Level %d - %s",
        stats.level or 1,
        stats.quest_name or "Exploration")

    table.insert(hud, health_bar)
    table.insert(hud, score_line)
    table.insert(hud, level_line)

    return hud
end

function M.UI.create_border(width, height, title)
    local border = {}

    -- Top border with title
    local top = M.sprites.wall_corner_tl
    local title_padding = math.floor((width - #title - 4) / 2)
    for i = 1, title_padding do
        top = top .. M.sprites.wall_h
    end
    top = top .. " " .. title .. " "
    for i = 1, width - title_padding - #title - 4 do
        top = top .. M.sprites.wall_h
    end
    top = top .. M.sprites.wall_corner_tr

    table.insert(border, top)

    -- Side borders (handled in main render)

    -- Bottom border
    local bottom = M.sprites.wall_corner_bl
    for i = 2, width - 1 do
        bottom = bottom .. M.sprites.wall_h
    end
    bottom = bottom .. M.sprites.wall_corner_br

    return {top = top, bottom = bottom}
end

-- Animation system
M.Animations = {}
M.animations_list = {}

function M.Animations.create(entity, animation_type)
    local anim = {
        entity = entity,
        type = animation_type,
        frame = 0,
        max_frames = 10,
        original_sprite = entity.sprite
    }

    if animation_type == "attack" then
        anim.sprites = {"⚔️", "🗡️", "💫", "✨"}
    elseif animation_type == "hurt" then
        anim.sprites = {"💔", "😵", "💢"}
    elseif animation_type == "collect" then
        anim.sprites = {"✨", "⭐", "💫", "🌟"}
    end

    table.insert(M.animations_list, anim)
end

function M.Animations.update()
    for i = #M.animations_list, 1, -1 do
        local anim = M.animations_list[i]
        anim.frame = anim.frame + 1

        if anim.sprites and anim.frame <= #anim.sprites then
            anim.entity.sprite = anim.sprites[anim.frame]
        end

        if anim.frame >= anim.max_frames then
            anim.entity.sprite = anim.original_sprite
            table.remove(M.animations_list, i)
        end
    end
end

-- Level progression system
M.Levels = {
    {
        id = 1,
        name = "Tutorial Plains",
        type = "grass",
        enemies = 2,
        items = 5,
        width = 60,
        height = 20,
        obstacle_density = 0.05
    },
    {
        id = 2,
        name = "Dark Forest",
        type = "grass",
        enemies = 5,
        items = 7,
        width = 70,
        height = 22,
        obstacle_density = 0.15
    },
    {
        id = 3,
        name = "Crystal Caverns",
        type = "dungeon",
        enemies = 8,
        items = 10,
        width = 80,
        height = 24,
        obstacle_density = 0.1
    },
    {
        id = 4,
        name = "Water Temple",
        type = "water",
        enemies = 10,
        items = 12,
        width = 80,
        height = 24,
        obstacle_density = 0.08
    },
}

-- Get current level configuration
function M.get_level(level_num)
    return M.Levels[math.min(level_num, #M.Levels)]
end

return M