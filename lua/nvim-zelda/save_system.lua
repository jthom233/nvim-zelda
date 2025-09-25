
-- Save/Load System
local SaveGame = {}
SaveGame.save_dir = vim.fn.stdpath("data") .. "/nvim-zelda/saves/"

function SaveGame:save(slot, game_state)
    vim.fn.mkdir(self.save_dir, "p")
    local save_file = self.save_dir .. "slot_" .. slot .. ".json"

    local save_data = {
        version = "1.0",
        timestamp = os.time(),
        player = game_state.player,
        level = game_state.level,
        stats = game_state.stats,
        achievements = game_state.achievements,
        settings = game_state.settings
    }

    local json = vim.json.encode(save_data)
    vim.fn.writefile({json}, save_file)

    return true
end

function SaveGame:load(slot)
    local save_file = self.save_dir .. "slot_" .. slot .. ".json"

    if vim.fn.filereadable(save_file) == 0 then
        return nil
    end

    local json = vim.fn.readfile(save_file)[1]
    return vim.json.decode(json)
end
