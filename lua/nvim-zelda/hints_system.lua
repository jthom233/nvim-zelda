
-- Educational Hint System
local Hints = {}
Hints.context_hints = {
    stuck_at_wall = "Try using 'h' (left), 'j' (down), 'k' (up), 'l' (right) to move!",
    near_enemy = "Press 'x' to attack, or 'V' to enter visual mode for area damage!",
    low_health = "Find hearts or use ':heal' command to restore HP!",
    puzzle_room = "This puzzle requires the '%s' command. Type ':help %s' to learn!",
    boss_battle = "Boss weakness: %s. Master this command to deal massive damage!"
}

function Hints:get_contextual_hint(game_state)
    -- Analyze game state and provide appropriate hint
    if game_state.player.health < 2 then
        return self.context_hints.low_health
    elseif game_state.near_wall then
        return self.context_hints.stuck_at_wall
    elseif game_state.in_puzzle then
        local cmd = game_state.puzzle.required_command
        return string.format(self.context_hints.puzzle_room, cmd, cmd)
    end
end
