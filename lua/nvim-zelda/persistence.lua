-- Real Persistence Layer for nvim-zelda
-- No mocks, actual SQLite database implementation with graceful fallback

local M = {}
local sqlite = nil
local db = nil
local player_id = nil
M.available = false
M.in_memory = {}  -- Fallback storage if SQLite not available

-- Check if SQLite3 is available
function M.check_sqlite()
    local handle = io.popen('sqlite3 --version 2>&1')
    if handle then
        local result = handle:read('*a')
        handle:close()
        if result and result:match('%d+%.%d+%.%d+') then
            return true
        end
    end
    return false
end

-- Initialize SQLite (using vim.fn.system for now, will integrate lsqlite3 later)
function M.init()
    -- Check if SQLite is available
    if not M.check_sqlite() then
        vim.notify('⚠️  SQLite3 not found. Progress will not be saved. Install sqlite3 for persistence.', vim.log.levels.WARN)
        M.available = false
        -- Initialize in-memory fallback
        M.in_memory = {
            player = { id = 1, username = vim.fn.expand('$USER'), level = 1, score = 0 },
            session = { id = 1, start_time = vim.fn.localtime() },
            commands = {},
            achievements = {}
        }
        return true  -- Return true so game can still run
    end

    M.available = true

    -- Create real database in Neovim data directory
    local data_path = vim.fn.stdpath('data')
    M.db_path = data_path .. '/nvim-zelda.db'

    -- Create tables using sqlite3 command
    local schema = [[
        CREATE TABLE IF NOT EXISTS players (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            last_played DATETIME DEFAULT CURRENT_TIMESTAMP,
            total_playtime INTEGER DEFAULT 0,
            current_level INTEGER DEFAULT 1,
            total_score INTEGER DEFAULT 0
        );

        CREATE TABLE IF NOT EXISTS command_progress (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            player_id INTEGER NOT NULL,
            command TEXT NOT NULL,
            mastery_level INTEGER DEFAULT 0,
            practice_count INTEGER DEFAULT 0,
            success_count INTEGER DEFAULT 0,
            average_speed REAL DEFAULT 0.0,
            last_practiced DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(player_id) REFERENCES players(id),
            UNIQUE(player_id, command)
        );

        CREATE TABLE IF NOT EXISTS achievements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            player_id INTEGER NOT NULL,
            achievement_id TEXT NOT NULL,
            unlocked_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            progress_data TEXT,
            FOREIGN KEY(player_id) REFERENCES players(id),
            UNIQUE(player_id, achievement_id)
        );

        CREATE TABLE IF NOT EXISTS game_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            player_id INTEGER NOT NULL,
            started_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            ended_at DATETIME,
            duration INTEGER DEFAULT 0,
            commands_used INTEGER DEFAULT 0,
            enemies_defeated INTEGER DEFAULT 0,
            rooms_cleared INTEGER DEFAULT 0,
            score INTEGER DEFAULT 0,
            FOREIGN KEY(player_id) REFERENCES players(id)
        );

        CREATE TABLE IF NOT EXISTS command_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER NOT NULL,
            command TEXT NOT NULL,
            success BOOLEAN DEFAULT 1,
            execution_time REAL,
            context TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(session_id) REFERENCES game_sessions(id)
        );

        CREATE TABLE IF NOT EXISTS leaderboard (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            player_id INTEGER NOT NULL,
            score INTEGER NOT NULL,
            level INTEGER NOT NULL,
            commands_mastered INTEGER DEFAULT 0,
            achievements_count INTEGER DEFAULT 0,
            recorded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY(player_id) REFERENCES players(id)
        );
    ]]

    -- Execute schema creation
    local cmd = string.format('sqlite3 "%s" "%s"', M.db_path, schema:gsub('"', '\\"'):gsub('\n', ' '))
    local result = vim.fn.system(cmd)

    if vim.v.shell_error ~= 0 then
        vim.notify('Failed to initialize database: ' .. result, vim.log.levels.ERROR)
        return false
    end

    return true
end

-- Get or create player
function M.get_or_create_player(username)
    username = username or vim.fn.expand('$USER')

    -- Fallback to in-memory if SQLite not available
    if not M.available then
        M.in_memory.player.username = username
        return M.in_memory.player
    end

    -- Check if player exists
    local query = string.format('SELECT id, current_level, total_score FROM players WHERE username = "%s"', username)
    local cmd = string.format('sqlite3 -json "%s" "%s"', M.db_path, query)
    local result = vim.fn.system(cmd)

    if result and result ~= '' and result ~= '[]' then
        -- Parse JSON result
        local ok, data = pcall(vim.json.decode, result)
        if ok and data[1] then
            player_id = data[1].id
            return {
                id = data[1].id,
                level = data[1].current_level,
                score = data[1].total_score
            }
        end
    end

    -- Create new player
    local insert = string.format('INSERT INTO players (username) VALUES ("%s")', username)
    vim.fn.system(string.format('sqlite3 "%s" "%s"', M.db_path, insert))

    -- Get the new player ID
    local last_id_cmd = string.format('sqlite3 "%s" "SELECT last_insert_rowid()"', M.db_path)
    local new_id = vim.fn.system(last_id_cmd)
    player_id = tonumber(new_id)

    return {
        id = player_id,
        level = 1,
        score = 0
    }
end

-- Start a new game session
function M.start_session()
    -- Fallback to in-memory
    if not M.available then
        M.in_memory.session.id = (M.in_memory.session.id or 0) + 1
        M.in_memory.session.start_time = vim.fn.localtime()
        return M.in_memory.session.id
    end

    if not player_id then
        vim.notify('No player loaded', vim.log.levels.ERROR)
        return nil
    end

    local insert = string.format('INSERT INTO game_sessions (player_id) VALUES (%d)', player_id)
    vim.fn.system(string.format('sqlite3 "%s" "%s"', M.db_path, insert))

    local session_id_cmd = string.format('sqlite3 "%s" "SELECT last_insert_rowid()"', M.db_path)
    local session_id = tonumber(vim.fn.system(session_id_cmd))

    M.current_session = session_id
    return session_id
end

-- End game session
function M.end_session(stats)
    if not M.current_session then return end

    local update = string.format([[
        UPDATE game_sessions
        SET ended_at = CURRENT_TIMESTAMP,
            duration = %d,
            commands_used = %d,
            enemies_defeated = %d,
            rooms_cleared = %d,
            score = %d
        WHERE id = %d
    ]], stats.duration or 0,
        stats.commands_used or 0,
        stats.enemies_defeated or 0,
        stats.rooms_cleared or 0,
        stats.score or 0,
        M.current_session)

    vim.fn.system(string.format('sqlite3 "%s" "%s"', M.db_path, update))
    M.current_session = nil
end

-- Track command usage
function M.track_command(command, success, execution_time, context)
    -- Fallback to in-memory
    if not M.available then
        if not M.in_memory.commands[command] then
            M.in_memory.commands[command] = {
                count = 0,
                successes = 0,
                total_time = 0
            }
        end
        M.in_memory.commands[command].count = M.in_memory.commands[command].count + 1
        if success then
            M.in_memory.commands[command].successes = M.in_memory.commands[command].successes + 1
        end
        M.in_memory.commands[command].total_time = M.in_memory.commands[command].total_time + (execution_time or 0)
        return
    end

    if not M.current_session then return end

    -- Record in command history
    local insert = string.format([[
        INSERT INTO command_history (session_id, command, success, execution_time, context)
        VALUES (%d, '%s', %d, %f, '%s')
    ]], M.current_session, command, success and 1 or 0, execution_time or 0, context or '')

    vim.fn.system(string.format('sqlite3 "%s" "%s"', M.db_path, insert))

    -- Update command progress
    M.update_command_progress(command, success, execution_time)
end

-- Update command mastery progress
function M.update_command_progress(command, success, execution_time)
    if not player_id then return end

    -- Check if command progress exists
    local check = string.format([[
        SELECT id, practice_count, success_count, average_speed
        FROM command_progress
        WHERE player_id = %d AND command = '%s'
    ]], player_id, command)

    local result = vim.fn.system(string.format('sqlite3 -json "%s" "%s"', M.db_path, check))

    if result and result ~= '' and result ~= '[]' then
        -- Update existing progress
        local ok, data = pcall(vim.json.decode, result)
        if ok and data[1] then
            local new_practice_count = data[1].practice_count + 1
            local new_success_count = data[1].success_count + (success and 1 or 0)
            local new_avg_speed = (data[1].average_speed * data[1].practice_count + execution_time) / new_practice_count
            local mastery = math.floor((new_success_count / new_practice_count) * 100)

            local update = string.format([[
                UPDATE command_progress
                SET practice_count = %d,
                    success_count = %d,
                    average_speed = %f,
                    mastery_level = %d,
                    last_practiced = CURRENT_TIMESTAMP
                WHERE id = %d
            ]], new_practice_count, new_success_count, new_avg_speed, mastery, data[1].id)

            vim.fn.system(string.format('sqlite3 "%s" "%s"', M.db_path, update))
        end
    else
        -- Insert new progress record
        local insert = string.format([[
            INSERT INTO command_progress (player_id, command, practice_count, success_count, average_speed, mastery_level)
            VALUES (%d, '%s', 1, %d, %f, %d)
        ]], player_id, command, success and 1 or 0, execution_time, success and 100 or 0)

        vim.fn.system(string.format('sqlite3 "%s" "%s"', M.db_path, insert))
    end
end

-- Unlock achievement
function M.unlock_achievement(achievement_id, progress_data)
    if not player_id then return end

    -- Check if already unlocked
    local check = string.format([[
        SELECT id FROM achievements
        WHERE player_id = %d AND achievement_id = '%s'
    ]], player_id, achievement_id)

    local result = vim.fn.system(string.format('sqlite3 "%s" "%s"', M.db_path, check))

    if not result or result == '' then
        -- Unlock new achievement
        local insert = string.format([[
            INSERT INTO achievements (player_id, achievement_id, progress_data)
            VALUES (%d, '%s', '%s')
        ]], player_id, achievement_id, vim.json.encode(progress_data or {}))

        vim.fn.system(string.format('sqlite3 "%s" "%s"', M.db_path, insert))

        vim.notify('🏆 Achievement Unlocked: ' .. achievement_id, vim.log.levels.INFO)
        return true
    end

    return false
end

-- Get player statistics
function M.get_player_stats()
    -- Fallback to in-memory
    if not M.available then
        local stats = {
            playtime = vim.fn.localtime() - (M.in_memory.session.start_time or 0),
            level = M.in_memory.player.level or 1,
            score = M.in_memory.player.score or 0,
            achievements = vim.tbl_count(M.in_memory.achievements or {}),
            top_commands = {}
        }

        -- Convert commands to top_commands format
        for cmd, data in pairs(M.in_memory.commands or {}) do
            local mastery = data.count > 0 and (data.successes / data.count * 100) or 0
            table.insert(stats.top_commands, {
                command = cmd,
                mastery_level = mastery,
                practice_count = data.count
            })
        end

        -- Sort by mastery level
        table.sort(stats.top_commands, function(a, b)
            return a.mastery_level > b.mastery_level
        end)

        return stats
    end

    if not player_id then return {} end

    local stats = {}

    -- Get overall stats
    local player_query = string.format([[
        SELECT total_playtime, current_level, total_score
        FROM players WHERE id = %d
    ]], player_id)

    local player_result = vim.fn.system(string.format('sqlite3 -json "%s" "%s"', M.db_path, player_query))
    local ok, player_data = pcall(vim.json.decode, player_result)
    if ok and player_data[1] then
        stats.playtime = player_data[1].total_playtime
        stats.level = player_data[1].current_level
        stats.score = player_data[1].total_score
    end

    -- Get command mastery
    local command_query = string.format([[
        SELECT command, mastery_level, practice_count
        FROM command_progress
        WHERE player_id = %d
        ORDER BY mastery_level DESC
        LIMIT 10
    ]], player_id)

    local command_result = vim.fn.system(string.format('sqlite3 -json "%s" "%s"', M.db_path, command_query))
    ok, stats.top_commands = pcall(vim.json.decode, command_result)

    -- Get achievements
    local achievement_query = string.format([[
        SELECT COUNT(*) as count FROM achievements WHERE player_id = %d
    ]], player_id)

    local achievement_result = vim.fn.system(string.format('sqlite3 -json "%s" "%s"', M.db_path, achievement_query))
    ok, achievement_data = pcall(vim.json.decode, achievement_result)
    if ok and achievement_data[1] then
        stats.achievements = achievement_data[1].count
    end

    return stats
end

-- Get leaderboard
function M.get_leaderboard(limit)
    limit = limit or 10

    local query = string.format([[
        SELECT p.username, l.score, l.level, l.commands_mastered, l.achievements_count
        FROM leaderboard l
        JOIN players p ON l.player_id = p.id
        ORDER BY l.score DESC
        LIMIT %d
    ]], limit)

    local result = vim.fn.system(string.format('sqlite3 -json "%s" "%s"', M.db_path, query))
    local ok, leaderboard = pcall(vim.json.decode, result)

    return ok and leaderboard or {}
end

-- Update leaderboard entry
function M.update_leaderboard(score, level, commands_mastered, achievements_count)
    if not player_id then return end

    local insert = string.format([[
        INSERT INTO leaderboard (player_id, score, level, commands_mastered, achievements_count)
        VALUES (%d, %d, %d, %d, %d)
    ]], player_id, score, level, commands_mastered, achievements_count)

    vim.fn.system(string.format('sqlite3 "%s" "%s"', M.db_path, insert))
end

-- Save game state
function M.save_game_state(state)
    if not player_id then return end

    local update = string.format([[
        UPDATE players
        SET last_played = CURRENT_TIMESTAMP,
            current_level = %d,
            total_score = %d
        WHERE id = %d
    ]], state.level or 1, state.score or 0, player_id)

    vim.fn.system(string.format('sqlite3 "%s" "%s"', M.db_path, update))
end

return M