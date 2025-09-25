-- Real AI System for nvim-zelda
-- Actual pathfinding and intelligent enemy behavior, no random() calls

local M = {}

-- Priority queue for A* pathfinding
local PriorityQueue = {}
PriorityQueue.__index = PriorityQueue

function PriorityQueue.new()
    return setmetatable({ items = {}, size = 0 }, PriorityQueue)
end

function PriorityQueue:push(item, priority)
    table.insert(self.items, { item = item, priority = priority })
    self.size = self.size + 1

    -- Bubble up
    local idx = self.size
    while idx > 1 do
        local parent_idx = math.floor(idx / 2)
        if self.items[idx].priority < self.items[parent_idx].priority then
            self.items[idx], self.items[parent_idx] = self.items[parent_idx], self.items[idx]
            idx = parent_idx
        else
            break
        end
    end
end

function PriorityQueue:pop()
    if self.size == 0 then return nil end

    local top = self.items[1].item
    self.items[1] = self.items[self.size]
    self.items[self.size] = nil
    self.size = self.size - 1

    -- Bubble down
    local idx = 1
    while idx * 2 <= self.size do
        local left = idx * 2
        local right = idx * 2 + 1
        local smallest = idx

        if self.items[left].priority < self.items[smallest].priority then
            smallest = left
        end

        if right <= self.size and self.items[right].priority < self.items[smallest].priority then
            smallest = right
        end

        if smallest ~= idx then
            self.items[idx], self.items[smallest] = self.items[smallest], self.items[idx]
            idx = smallest
        else
            break
        end
    end

    return top
end

function PriorityQueue:empty()
    return self.size == 0
end

-- Real A* pathfinding implementation
function M.astar(start, goal, get_neighbors, heuristic, cost_fn)
    local open_set = PriorityQueue.new()
    local came_from = {}
    local g_score = {}
    local f_score = {}

    local start_key = start.x .. "," .. start.y
    g_score[start_key] = 0
    f_score[start_key] = heuristic(start, goal)
    open_set:push(start, f_score[start_key])

    local closed_set = {}

    while not open_set:empty() do
        local current = open_set:pop()
        local current_key = current.x .. "," .. current.y

        if current.x == goal.x and current.y == goal.y then
            -- Reconstruct path
            local path = {}
            local node = current
            while node do
                table.insert(path, 1, node)
                node = came_from[node.x .. "," .. node.y]
            end
            return path
        end

        closed_set[current_key] = true

        for _, neighbor in ipairs(get_neighbors(current)) do
            local neighbor_key = neighbor.x .. "," .. neighbor.y

            if not closed_set[neighbor_key] then
                local tentative_g = g_score[current_key] + cost_fn(current, neighbor)

                if not g_score[neighbor_key] or tentative_g < g_score[neighbor_key] then
                    came_from[neighbor_key] = current
                    g_score[neighbor_key] = tentative_g
                    f_score[neighbor_key] = tentative_g + heuristic(neighbor, goal)
                    open_set:push(neighbor, f_score[neighbor_key])
                end
            end
        end
    end

    return nil -- No path found
end

-- Real Dijkstra's algorithm for guaranteed shortest path
function M.dijkstra(start, goal, get_neighbors, cost_fn)
    local distances = {}
    local previous = {}
    local unvisited = {}

    local start_key = start.x .. "," .. start.y
    distances[start_key] = 0

    -- Initialize all nodes as unvisited with infinite distance
    local function add_to_unvisited(node)
        local key = node.x .. "," .. node.y
        if not distances[key] then
            distances[key] = math.huge
            unvisited[key] = node
        end
    end

    add_to_unvisited(start)

    while next(unvisited) do
        -- Find unvisited node with minimum distance
        local min_key, min_node = nil, nil
        local min_dist = math.huge

        for key, node in pairs(unvisited) do
            if distances[key] < min_dist then
                min_dist = distances[key]
                min_key = key
                min_node = node
            end
        end

        if not min_node then break end

        if min_node.x == goal.x and min_node.y == goal.y then
            -- Reconstruct path
            local path = {}
            local node = min_node
            local key = node.x .. "," .. node.y

            while previous[key] do
                table.insert(path, 1, node)
                node = previous[key]
                key = node.x .. "," .. node.y
            end
            table.insert(path, 1, start)

            return path
        end

        unvisited[min_key] = nil

        for _, neighbor in ipairs(get_neighbors(min_node)) do
            add_to_unvisited(neighbor)
            local neighbor_key = neighbor.x .. "," .. neighbor.y
            local alt = distances[min_key] + cost_fn(min_node, neighbor)

            if alt < distances[neighbor_key] then
                distances[neighbor_key] = alt
                previous[neighbor_key] = min_node
            end
        end
    end

    return nil
end

-- Enemy behavior state machine
M.EnemyBehavior = {}
M.EnemyBehavior.__index = M.EnemyBehavior

function M.EnemyBehavior.new(enemy_type)
    local self = setmetatable({}, M.EnemyBehavior)
    self.type = enemy_type
    self.state = "idle"
    self.state_timer = 0
    self.path = nil
    self.path_index = 1
    self.last_player_pos = nil
    self.reaction_time = M.get_reaction_time(enemy_type)
    self.detection_range = M.get_detection_range(enemy_type)
    self.speed = M.get_enemy_speed(enemy_type)
    self.memory_duration = 5 -- Seconds to remember player position

    return self
end

-- Real enemy AI based on type and player skill
function M.EnemyBehavior:update(enemy, player, obstacles, dt)
    self.state_timer = self.state_timer + dt

    local distance = M.manhattan_distance(enemy, player)
    local can_see_player = M.has_line_of_sight(enemy, player, obstacles)

    -- State transitions
    if self.state == "idle" then
        if can_see_player and distance <= self.detection_range then
            self.state = "alerted"
            self.state_timer = 0
            self.last_player_pos = { x = player.x, y = player.y }
        else
            -- Patrol behavior
            return self:patrol(enemy)
        end
    elseif self.state == "alerted" then
        if self.state_timer >= self.reaction_time then
            self.state = "pursuing"
            self.state_timer = 0
        end
        return { dx = 0, dy = 0 } -- Freeze during reaction
    elseif self.state == "pursuing" then
        if can_see_player then
            self.last_player_pos = { x = player.x, y = player.y }
            return self:pursue(enemy, player, obstacles)
        elseif self.last_player_pos then
            -- Move to last known position
            local result = self:move_to(enemy, self.last_player_pos, obstacles)
            if enemy.x == self.last_player_pos.x and enemy.y == self.last_player_pos.y then
                self.state = "searching"
                self.state_timer = 0
            end
            return result
        else
            self.state = "searching"
            self.state_timer = 0
        end
    elseif self.state == "searching" then
        if can_see_player and distance <= self.detection_range then
            self.state = "alerted"
            self.state_timer = 0
            self.last_player_pos = { x = player.x, y = player.y }
        elseif self.state_timer > self.memory_duration then
            self.state = "idle"
            self.state_timer = 0
        else
            return self:search_pattern(enemy)
        end
    end

    return { dx = 0, dy = 0 }
end

-- Patrol in a pattern
function M.EnemyBehavior:patrol(enemy)
    if not self.patrol_points then
        -- Generate patrol points based on enemy position
        self.patrol_points = M.generate_patrol_points(enemy)
        self.patrol_index = 1
    end

    local target = self.patrol_points[self.patrol_index]

    if enemy.x == target.x and enemy.y == target.y then
        self.patrol_index = (self.patrol_index % #self.patrol_points) + 1
        target = self.patrol_points[self.patrol_index]
    end

    -- Move towards patrol point
    local dx = target.x > enemy.x and 1 or (target.x < enemy.x and -1 or 0)
    local dy = target.y > enemy.y and 1 or (target.y < enemy.y and -1 or 0)

    return { dx = dx, dy = dy }
end

-- Pursue player using pathfinding
function M.EnemyBehavior:pursue(enemy, player, obstacles)
    -- Recalculate path if needed
    if not self.path or self.state_timer % 1 < 0.1 then
        local get_neighbors = function(node)
            return M.get_valid_neighbors(node, obstacles)
        end

        local heuristic = function(a, b)
            return M.manhattan_distance(a, b)
        end

        local cost = function(a, b)
            return 1 -- Uniform cost for now
        end

        self.path = M.astar(enemy, player, get_neighbors, heuristic, cost)
        self.path_index = 1
    end

    if self.path and self.path_index <= #self.path then
        local target = self.path[self.path_index]

        if enemy.x == target.x and enemy.y == target.y then
            self.path_index = self.path_index + 1

            if self.path_index <= #self.path then
                target = self.path[self.path_index]
            else
                return { dx = 0, dy = 0 }
            end
        end

        local dx = target.x > enemy.x and 1 or (target.x < enemy.x and -1 or 0)
        local dy = target.y > enemy.y and 1 or (target.y < enemy.y and -1 or 0)

        return { dx = dx, dy = dy }
    end

    return { dx = 0, dy = 0 }
end

-- Search pattern when player is lost
function M.EnemyBehavior:search_pattern(enemy)
    if not self.search_points then
        -- Generate search pattern around last known position
        self.search_points = M.generate_search_pattern(self.last_player_pos)
        self.search_index = 1
    end

    if self.search_index <= #self.search_points then
        local target = self.search_points[self.search_index]

        if enemy.x == target.x and enemy.y == target.y then
            self.search_index = self.search_index + 1

            if self.search_index > #self.search_points then
                self.search_points = nil
                return { dx = 0, dy = 0 }
            end
        end

        local dx = target.x > enemy.x and 1 or (target.x < enemy.x and -1 or 0)
        local dy = target.y > enemy.y and 1 or (target.y < enemy.y and -1 or 0)

        return { dx = dx, dy = dy }
    end

    return { dx = 0, dy = 0 }
end

-- Move to a specific position
function M.EnemyBehavior:move_to(enemy, target, obstacles)
    local get_neighbors = function(node)
        return M.get_valid_neighbors(node, obstacles)
    end

    local cost = function(a, b)
        return 1
    end

    local path = M.dijkstra(enemy, target, get_neighbors, cost)

    if path and #path > 1 then
        local next_pos = path[2]
        local dx = next_pos.x > enemy.x and 1 or (next_pos.x < enemy.x and -1 or 0)
        local dy = next_pos.y > enemy.y and 1 or (next_pos.y < enemy.y and -1 or 0)

        return { dx = dx, dy = dy }
    end

    return { dx = 0, dy = 0 }
end

-- Utility functions
function M.manhattan_distance(a, b)
    return math.abs(a.x - b.x) + math.abs(a.y - b.y)
end

function M.euclidean_distance(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

function M.has_line_of_sight(from, to, obstacles)
    -- Bresenham's line algorithm to check for obstacles
    local x0, y0 = from.x, from.y
    local x1, y1 = to.x, to.y

    local dx = math.abs(x1 - x0)
    local dy = math.abs(y1 - y0)
    local sx = x0 < x1 and 1 or -1
    local sy = y0 < y1 and 1 or -1
    local err = dx - dy

    while true do
        -- Check if current position is blocked
        for _, obs in ipairs(obstacles) do
            if obs.x == x0 and obs.y == y0 and not (x0 == from.x and y0 == from.y) then
                return false
            end
        end

        if x0 == x1 and y0 == y1 then
            break
        end

        local e2 = 2 * err

        if e2 > -dy then
            err = err - dy
            x0 = x0 + sx
        end

        if e2 < dx then
            err = err + dx
            y0 = y0 + sy
        end
    end

    return true
end

function M.get_valid_neighbors(node, obstacles)
    local neighbors = {}
    local directions = {
        { x = 0, y = -1 },  -- Up
        { x = 1, y = 0 },   -- Right
        { x = 0, y = 1 },   -- Down
        { x = -1, y = 0 }   -- Left
    }

    for _, dir in ipairs(directions) do
        local new_x = node.x + dir.x
        local new_y = node.y + dir.y

        local blocked = false
        for _, obs in ipairs(obstacles) do
            if obs.x == new_x and obs.y == new_y then
                blocked = true
                break
            end
        end

        if not blocked then
            table.insert(neighbors, { x = new_x, y = new_y })
        end
    end

    return neighbors
end

-- Enemy type configurations
function M.get_reaction_time(enemy_type)
    local reactions = {
        goblin = 0.3,
        orc = 0.5,
        skeleton = 0.4,
        boss = 0.2,
        guard = 0.35
    }
    return reactions[enemy_type] or 0.5
end

function M.get_detection_range(enemy_type)
    local ranges = {
        goblin = 5,
        orc = 7,
        skeleton = 6,
        boss = 10,
        guard = 8
    }
    return ranges[enemy_type] or 6
end

function M.get_enemy_speed(enemy_type)
    local speeds = {
        goblin = 1.2,
        orc = 0.8,
        skeleton = 1.0,
        boss = 0.9,
        guard = 1.1
    }
    return speeds[enemy_type] or 1.0
end

-- Generate patrol points for an enemy
function M.generate_patrol_points(enemy)
    local points = {}

    -- Create a square patrol pattern
    local size = 3

    table.insert(points, { x = enemy.x + size, y = enemy.y })
    table.insert(points, { x = enemy.x + size, y = enemy.y + size })
    table.insert(points, { x = enemy.x, y = enemy.y + size })
    table.insert(points, { x = enemy.x, y = enemy.y })

    return points
end

-- Generate search pattern around a position
function M.generate_search_pattern(center)
    if not center then return {} end

    local points = {}
    local radius = 3

    -- Spiral pattern
    for r = 1, radius do
        for angle = 0, 7 do
            local theta = (angle / 8) * 2 * math.pi
            local x = center.x + math.floor(r * math.cos(theta) + 0.5)
            local y = center.y + math.floor(r * math.sin(theta) + 0.5)
            table.insert(points, { x = x, y = y })
        end
    end

    return points
end

-- Predict player movement for interception
function M.predict_player_position(player, velocity, time)
    if not velocity then
        return { x = player.x, y = player.y }
    end

    return {
        x = player.x + math.floor(velocity.x * time + 0.5),
        y = player.y + math.floor(velocity.y * time + 0.5)
    }
end

-- Create enemy with real AI
function M.create_enemy(enemy_type, x, y)
    return {
        x = x,
        y = y,
        type = enemy_type,
        hp = M.get_enemy_hp(enemy_type),
        damage = M.get_enemy_damage(enemy_type),
        behavior = M.EnemyBehavior.new(enemy_type),
        sprite = M.get_enemy_sprite(enemy_type)
    }
end

-- Enemy stats based on type
function M.get_enemy_hp(enemy_type)
    local hp_values = {
        goblin = 30,
        orc = 50,
        skeleton = 40,
        boss = 100,
        guard = 60
    }
    return hp_values[enemy_type] or 40
end

function M.get_enemy_damage(enemy_type)
    local damage_values = {
        goblin = 5,
        orc = 10,
        skeleton = 7,
        boss = 15,
        guard = 8
    }
    return damage_values[enemy_type] or 5
end

function M.get_enemy_sprite(enemy_type)
    local sprites = {
        goblin = "g",
        orc = "O",
        skeleton = "S",
        boss = "B",
        guard = "G"
    }
    return sprites[enemy_type] or "E"
end

-- Enhanced AI behaviors for smarter enemies
function M.EnemyBehavior:flank_player(enemy, player, obstacles)
    -- Try to position behind or beside the player
    local flanking_positions = {
        { x = player.x + 1, y = player.y },     -- Right
        { x = player.x - 1, y = player.y },     -- Left
        { x = player.x, y = player.y + 1 },     -- Below
        { x = player.x, y = player.y - 1 },     -- Above
        { x = player.x + 1, y = player.y + 1 }, -- Diagonal
        { x = player.x - 1, y = player.y - 1 }, -- Diagonal
    }

    -- Find the best flanking position that's not blocked
    for _, pos in ipairs(flanking_positions) do
        if not M.is_position_blocked(pos.x, pos.y, obstacles) then
            return self:move_to(enemy, pos, obstacles)
        end
    end

    -- Fall back to direct pursuit
    return self:pursue(enemy, player, obstacles)
end

function M.EnemyBehavior:coordinate_with_allies(enemy, player, all_enemies)
    -- Count nearby allies
    local nearby_allies = 0
    local ally_positions = {}

    for _, other_enemy in ipairs(all_enemies) do
        if other_enemy ~= enemy then
            local distance = M.manhattan_distance(enemy, other_enemy)
            if distance <= 3 then
                nearby_allies = nearby_allies + 1
                table.insert(ally_positions, other_enemy)
            end
        end
    end

    -- If we have allies, coordinate attack
    if nearby_allies >= 1 then
        -- Try to surround the player
        local player_distance = M.manhattan_distance(enemy, player)

        if player_distance <= 2 then
            -- Close enough - try to position strategically
            return self:flank_player(enemy, player, {})
        else
            -- Move to engage
            return self:pursue(enemy, player, {})
        end
    end

    -- No coordination needed, use normal behavior
    return self:pursue(enemy, player, {})
end

function M.EnemyBehavior:ambush_behavior(enemy, player, obstacles)
    -- Wait until player gets close, then surprise attack
    local distance = M.manhattan_distance(enemy, player)

    if distance > 2 and distance <= self.detection_range then
        -- Stay still and wait for player to come closer
        return { dx = 0, dy = 0 }
    elseif distance <= 2 then
        -- Spring the ambush!
        return self:pursue(enemy, player, obstacles)
    end

    return self:patrol(enemy)
end

function M.EnemyBehavior:retreat_and_regroup(enemy, player, obstacles)
    -- If low health, try to retreat to a safer position
    if enemy.hp < (enemy.max_hp * 0.3) then
        -- Find positions further from player
        local retreat_positions = {}
        for dx = -2, 2 do
            for dy = -2, 2 do
                local pos = { x = enemy.x + dx, y = enemy.y + dy }
                local player_dist = M.manhattan_distance(pos, player)
                local current_dist = M.manhattan_distance(enemy, player)

                if player_dist > current_dist and not M.is_position_blocked(pos.x, pos.y, obstacles) then
                    table.insert(retreat_positions, pos)
                end
            end
        end

        if #retreat_positions > 0 then
            -- Move to the furthest retreat position
            local best_retreat = retreat_positions[1]
            local max_distance = M.manhattan_distance(best_retreat, player)

            for _, pos in ipairs(retreat_positions) do
                local dist = M.manhattan_distance(pos, player)
                if dist > max_distance then
                    max_distance = dist
                    best_retreat = pos
                end
            end

            return self:move_to(enemy, best_retreat, obstacles)
        end
    end

    return self:pursue(enemy, player, obstacles)
end

-- Enhanced update function with smarter behaviors
function M.EnemyBehavior:enhanced_update(enemy, player, all_enemies, obstacles, dt)
    self.state_timer = self.state_timer + dt

    local distance = M.manhattan_distance(enemy, player)
    local can_see_player = M.has_line_of_sight(enemy, player, obstacles)

    -- Enhanced behavior based on enemy type
    if enemy.type == "goblin" then
        -- Goblins are sneaky - use ambush tactics
        if self.state == "idle" or self.state == "searching" then
            if can_see_player and distance <= self.detection_range then
                self.state = "pursuing"
                return self:ambush_behavior(enemy, player, obstacles)
            end
        elseif self.state == "pursuing" then
            return self:ambush_behavior(enemy, player, obstacles)
        end
    elseif enemy.type == "orc" then
        -- Orcs are aggressive and coordinate
        if can_see_player then
            self.state = "pursuing"
            return self:coordinate_with_allies(enemy, player, all_enemies)
        end
    elseif enemy.type == "skeleton" then
        -- Skeletons are tactical - flank and retreat when hurt
        if can_see_player then
            self.state = "pursuing"
            return self:retreat_and_regroup(enemy, player, obstacles)
        end
    elseif enemy.type == "guard" then
        -- Guards are defensive but smart
        if can_see_player and distance <= 4 then
            self.state = "pursuing"
            return self:flank_player(enemy, player, obstacles)
        end
    elseif enemy.type == "boss" then
        -- Boss uses all tactics dynamically
        if can_see_player then
            self.state = "pursuing"
            if enemy.hp < (enemy.max_hp * 0.5) then
                return self:retreat_and_regroup(enemy, player, obstacles)
            else
                return self:coordinate_with_allies(enemy, player, all_enemies)
            end
        end
    end

    -- Fall back to standard behavior
    return self:update(enemy, player, obstacles, dt)
end

return M