
-- Multiplayer System using WebSockets
local Multiplayer = {}
local uv = vim.loop
local json = vim.json

Multiplayer.server = nil
Multiplayer.clients = {}
Multiplayer.rooms = {}
Multiplayer.player_data = {}

function Multiplayer:init()
    -- Initialize WebSocket server
    self.server = uv.new_tcp()
    self.server:bind("127.0.0.1", 7777)

    self.server:listen(128, function()
        local client = uv.new_tcp()
        self.server:accept(client)
        self:handle_client(client)
    end)

    vim.notify("🌐 Multiplayer server started on port 7777", vim.log.levels.INFO)
end

function Multiplayer:create_room(room_name, mode)
    self.rooms[room_name] = {
        id = vim.fn.sha256(room_name .. os.time()),
        name = room_name,
        mode = mode, -- "coop", "pvp", "race"
        players = {},
        max_players = mode == "coop" and 4 or 2,
        game_state = {},
        created_at = os.time()
    }
    return self.rooms[room_name]
end

function Multiplayer:join_room(player_id, room_name)
    local room = self.rooms[room_name]
    if room and #room.players < room.max_players then
        table.insert(room.players, player_id)
        self:broadcast_to_room(room_name, {
            type = "player_joined",
            player = self.player_data[player_id]
        })
        return true
    end
    return false
end

function Multiplayer:sync_game_state(room_name, state)
    -- Sync game state across all players in room
    self:broadcast_to_room(room_name, {
        type = "state_sync",
        state = state,
        timestamp = vim.fn.reltimefloat(vim.fn.reltime())
    })
end

function Multiplayer:handle_vim_command(player_id, command)
    -- Process vim commands in multiplayer context
    local room = self:get_player_room(player_id)
    if room then
        if room.mode == "race" then
            -- Track command completion times
            self:update_race_progress(player_id, command)
        elseif room.mode == "coop" then
            -- Combine commands for team combos
            self:check_team_combo(room, player_id, command)
        elseif room.mode == "pvp" then
            -- Commands affect opponent
            self:apply_pvp_effect(room, player_id, command)
        end
    end
end

function Multiplayer:update_leaderboard(player_id, score)
    -- Send to global leaderboard API
    vim.fn.jobstart({
        "curl", "-X", "POST",
        "https://api.nvim-zelda.com/leaderboard",
        "-d", json.encode({
            player_id = player_id,
            score = score,
            timestamp = os.time(),
            version = "2.0"
        })
    })
end

return Multiplayer
