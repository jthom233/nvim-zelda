
-- Combo System for Vim Commands
local Combo = {}
Combo.active_combo = {}
Combo.combo_list = {
    ["hjkl"] = {name = "Navigator", points = 10, effect = "speed_boost"},
    ["dd2j"] = {name = "Delete Master", points = 20, effect = "clear_enemies"},
    ["ggVG"] = {name = "Select All", points = 50, effect = "reveal_map"},
    ["ciw"] = {name = "Word Warrior", points = 15, effect = "extra_damage"},
    ["/.*\n"] = {name = "Regex Ranger", points = 30, effect = "find_secret"}
}

function Combo:check_combo(input)
    table.insert(self.active_combo, input)
    local combo_str = table.concat(self.active_combo)

    for pattern, combo_data in pairs(self.combo_list) do
        if combo_str:match(pattern .. "$") then
            return combo_data
        end
    end

    -- Clear old inputs
    if #self.active_combo > 10 then
        table.remove(self.active_combo, 1)
    end
end
