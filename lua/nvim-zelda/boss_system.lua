
-- Boss Battle System
local Boss = {}
Boss.bosses = {
    {
        name = "Vim Dragon",
        health = 100,
        commands_required = {"dd", "yy", "p", "u", "ctrl-r"},
        attacks = {"syntax_error", "indent_chaos", "register_wipe"},
        reward = "macro_recording"
    },
    {
        name = "Modal Monster",
        health = 150,
        commands_required = {"i", "esc", "v", "ctrl-v", "V"},
        attacks = {"mode_lock", "insert_trap", "visual_maze"},
        reward = "quick_scope"
    }
}

function Boss:start_battle(boss_id)
    local boss = self.bosses[boss_id]
    local battle_state = {
        boss = boss,
        player_combo = {},
        phase = 1,
        timer = 60
    }

    return battle_state
end
