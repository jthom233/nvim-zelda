-- Test script for nvim-zelda commands
-- Run this with :luafile % in Neovim after starting the game

local M = require('nvim-zelda')

-- Test all basic movement commands
local tests = {
    {cmd = 'h', func = function() M.move_player(-1, 0, 'h') end, desc = "Move left"},
    {cmd = 'j', func = function() M.move_player(0, 1, 'j') end, desc = "Move down"},
    {cmd = 'k', func = function() M.move_player(0, -1, 'k') end, desc = "Move up"},
    {cmd = 'l', func = function() M.move_player(1, 0, 'l') end, desc = "Move right"},
    {cmd = 'w', func = function() M.word_jump(3, 'w') end, desc = "Word jump forward"},
    {cmd = 'b', func = function() M.word_jump(-3, 'b') end, desc = "Word jump backward"},
    {cmd = 'i', func = function() M.insert_mode() end, desc = "Show inventory"},
    {cmd = 'v', func = function() M.enter_visual_mode() end, desc = "Visual mode"},
    {cmd = '/', func = function() M.search_mode() end, desc = "Search mode"},
    {cmd = 'x', func = function() M.delete_char() end, desc = "Delete char attack"},
    {cmd = 'dd', func = function() M.delete_line() end, desc = "Delete line attack"},
    {cmd = '0', func = function() M.move_to_line_start() end, desc = "Move to line start"},
    {cmd = '$', func = function() M.move_to_line_end() end, desc = "Move to line end"},
}

print("=== Testing nvim-zelda Commands ===")
print("")

for _, test in ipairs(tests) do
    print(string.format("Testing %s (%s)...", test.cmd, test.desc))
    local ok, err = pcall(test.func)
    if ok then
        print("  ✓ Success")
    else
        print("  ✗ Error: " .. tostring(err))
    end
end

print("")
print("=== Test Complete ===")