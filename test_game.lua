-- Test file to verify the plugin works
-- Run this with :luafile % in Neovim

-- Load the plugin
local zelda = require('nvim-zelda')

-- Setup with custom config
zelda.setup({
    width = 70,
    height = 25,
    teach_mode = true,
    difficulty = "easy"
})

-- Start the game
zelda.start()

print("nvim-zelda loaded successfully!")
print("Game should now be visible in a floating window")
print("Use hjkl to move, d to attack, q to quit")