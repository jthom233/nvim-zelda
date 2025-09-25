
-- nvim-zelda Ultimate Edition
-- Enhanced with MLRSA-NG Advanced Features
local M = {}

-- Load all systems
M.systems = {
    multiplayer = require("nvim-zelda.systems.multiplayer"),
    ai = require("nvim-zelda.systems.ai_adaptive"),
    procedural = require("nvim-zelda.systems.procedural"),
    vim_mechanics = require("nvim-zelda.systems.vim_mechanics"),
    progression = require("nvim-zelda.systems.progression")
}

-- Game modes
M.modes = {
    campaign = require("nvim-zelda.modes.campaign"),
    multiplayer = require("nvim-zelda.modes.multiplayer"),
    endless = require("nvim-zelda.modes.endless"),
    speedrun = require("nvim-zelda.modes.speedrun")
}

-- Initialize game
function M.setup(opts)
    M.config = vim.tbl_extend("force", {
        mode = "campaign",
        difficulty = "adaptive",
        multiplayer_enabled = false,
        ai_companion = true,
        procedural_content = true,
        progression_enabled = true
    }, opts or {})

    -- Initialize all systems
    for name, system in pairs(M.systems) do
        if system.init then
            system:init()
        end
    end

    vim.notify("🎮 nvim-zelda Ultimate Edition initialized!", vim.log.levels.INFO)
end

-- Start game with selected mode
function M.start(mode)
    mode = mode or M.config.mode

    if mode == "multiplayer" then
        M.systems.multiplayer:init()
        M.modes.multiplayer:start()
    elseif mode == "endless" then
        M.systems.procedural:generate_dungeon(1)
        M.modes.endless:start()
    elseif mode == "speedrun" then
        M.modes.speedrun:start()
    else
        M.modes.campaign:start()
    end

    -- Start AI adaptive system
    M.systems.ai:analyze_player_skill()

    vim.notify("🚀 Game started in " .. mode .. " mode!", vim.log.levels.INFO)
end

-- Commands
vim.api.nvim_create_user_command('Zelda', function(opts)
    M.start(opts.args)
end, {
    nargs = '?',
    complete = function()
        return {'campaign', 'multiplayer', 'endless', 'speedrun'}
    end
})

vim.api.nvim_create_user_command('ZeldaMultiplayer', function()
    M.start('multiplayer')
end, {})

vim.api.nvim_create_user_command('ZeldaDaily', function()
    local challenge = M.systems.procedural:generate_daily_challenge()
    M.start_daily_challenge(challenge)
end, {})

vim.api.nvim_create_user_command('ZeldaSkillTree', function()
    M.systems.progression:show_skill_tree()
end, {})

return M
