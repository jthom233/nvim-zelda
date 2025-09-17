
-- Advanced Health System for nvim-zelda
local Health = {}

-- Health configuration
Health.config = {
    base_hp = 100,
    base_shield = 0,
    base_armor = 0,
    regen_rate = 1, -- HP per second
    invulnerability_time = 1.5, -- seconds after taking damage
}

-- Health state
Health.state = {
    current_hp = 100,
    max_hp = 100,
    current_shield = 0,
    max_shield = 50,
    armor = 0,
    is_invulnerable = false,
    last_damage_time = 0,
    status_effects = {},
    health_bar_animation = 0
}

-- Initialize health system
function Health:init(player_stats)
    self.state.max_hp = self.config.base_hp + (player_stats.level * 10)
    self.state.current_hp = self.state.max_hp

    -- Set up health regeneration timer
    self:start_regeneration()
end

-- Take damage with advanced mechanics
function Health:take_damage(amount, damage_type, source)
    -- Check invulnerability
    if self.state.is_invulnerable then
        return {
            damage_dealt = 0,
            blocked = true,
            message = "Invulnerable!"
        }
    end

    local actual_damage = amount
    local blocked_damage = 0

    -- Apply shield first
    if self.state.current_shield > 0 then
        local shield_absorb = math.min(self.state.current_shield, actual_damage)
        self.state.current_shield = self.state.current_shield - shield_absorb
        actual_damage = actual_damage - shield_absorb
        blocked_damage = shield_absorb

        -- Shield break effect
        if self.state.current_shield == 0 then
            vim.notify("💔 Shield Broken!", vim.log.levels.WARN)
            self:apply_effect("shield_break", 2)
        end
    end

    -- Apply armor reduction
    if self.state.armor > 0 then
        local reduction = actual_damage * (self.state.armor / 100)
        actual_damage = actual_damage - reduction
        blocked_damage = blocked_damage + reduction
    end

    -- Apply damage type modifiers
    if damage_type == "poison" then
        self:apply_effect("poisoned", 5)
        actual_damage = actual_damage * 0.8
    elseif damage_type == "fire" then
        self:apply_effect("burning", 3)
        actual_damage = actual_damage * 1.2
    elseif damage_type == "ice" then
        self:apply_effect("frozen", 2)
        actual_damage = actual_damage * 0.9
    end

    -- Critical hit chance (from source)
    if source and source.crit_chance and math.random() < source.crit_chance then
        actual_damage = actual_damage * 2
        vim.notify("💥 Critical Hit!", vim.log.levels.ERROR)
    end

    -- Apply final damage
    self.state.current_hp = math.max(0, self.state.current_hp - actual_damage)
    self.state.last_damage_time = os.time()

    -- Trigger invulnerability frames
    self.state.is_invulnerable = true
    vim.defer_fn(function()
        self.state.is_invulnerable = false
    end, self.config.invulnerability_time * 1000)

    -- Health bar shake animation
    self.state.health_bar_animation = 10

    -- Check for death
    if self.state.current_hp <= 0 then
        self:handle_death()
    end

    return {
        damage_dealt = actual_damage,
        blocked = blocked_damage,
        remaining_hp = self.state.current_hp,
        message = string.format("-%d HP (blocked: %d)", actual_damage, blocked_damage)
    }
end

-- Heal with various mechanics
function Health:heal(amount, heal_type)
    local actual_heal = amount
    local overheal = 0

    -- Apply heal type modifiers
    if heal_type == "potion" then
        actual_heal = amount
    elseif heal_type == "regen" then
        -- Regen is reduced in combat
        if os.time() - self.state.last_damage_time < 5 then
            actual_heal = amount * 0.5
        end
    elseif heal_type == "lifesteal" then
        actual_heal = amount * 1.5
    elseif heal_type == "burst" then
        -- Instant full heal
        actual_heal = self.state.max_hp
    end

    -- Apply healing
    local old_hp = self.state.current_hp
    self.state.current_hp = math.min(self.state.max_hp, self.state.current_hp + actual_heal)
    local healed = self.state.current_hp - old_hp

    -- Calculate overheal for shield conversion
    if heal_type == "overheal" and self.state.current_hp == self.state.max_hp then
        overheal = amount - healed
        self.state.current_shield = math.min(self.state.max_shield,
                                            self.state.current_shield + overheal * 0.5)
    end

    return {
        healed = healed,
        overheal = overheal,
        current_hp = self.state.current_hp,
        message = string.format("+%d HP", healed)
    }
end

-- Apply status effects
function Health:apply_effect(effect_name, duration)
    self.state.status_effects[effect_name] = {
        duration = duration,
        started = os.time(),
        tick_damage = 0
    }

    -- Set effect properties
    if effect_name == "poisoned" then
        self.state.status_effects[effect_name].tick_damage = 2
    elseif effect_name == "burning" then
        self.state.status_effects[effect_name].tick_damage = 3
    elseif effect_name == "regenerating" then
        self.state.status_effects[effect_name].tick_heal = 5
    elseif effect_name == "shield_break" then
        self.state.armor = self.state.armor * 0.5
    end

    -- Start effect ticker
    self:tick_effects()
end

-- Health regeneration system
function Health:start_regeneration()
    vim.defer_fn(function()
        -- Only regenerate out of combat
        if os.time() - self.state.last_damage_time > 5 then
            if self.state.current_hp < self.state.max_hp then
                self:heal(self.config.regen_rate, "regen")
            end
        end

        -- Continue regeneration
        if self.state.current_hp > 0 then
            self:start_regeneration()
        end
    end, 1000) -- Every second
end

-- Get health display with colors
function Health:get_display()
    local hp_percent = self.state.current_hp / self.state.max_hp
    local hp_color = "Normal"

    if hp_percent <= 0.2 then
        hp_color = "ErrorMsg"
    elseif hp_percent <= 0.5 then
        hp_color = "WarningMsg"
    else
        hp_color = "Function"
    end

    -- Create health bar
    local bar_length = 20
    local filled = math.floor(bar_length * hp_percent)
    local health_bar = string.rep("█", filled) .. string.rep("░", bar_length - filled)

    -- Add shake effect if recently damaged
    if self.state.health_bar_animation > 0 then
        self.state.health_bar_animation = self.state.health_bar_animation - 1
        local offset = math.random(-1, 1)
        health_bar = string.rep(" ", math.abs(offset)) .. health_bar
    end

    -- Shield display
    local shield_display = ""
    if self.state.current_shield > 0 then
        shield_display = string.format(" 🛡️%d", self.state.current_shield)
    end

    -- Status effects display
    local effects_display = ""
    for effect, data in pairs(self.state.status_effects) do
        if effect == "poisoned" then
            effects_display = effects_display .. "🟢"
        elseif effect == "burning" then
            effects_display = effects_display .. "🔥"
        elseif effect == "frozen" then
            effects_display = effects_display .. "❄️"
        elseif effect == "regenerating" then
            effects_display = effects_display .. "💚"
        end
    end

    return {
        text = string.format("HP: %d/%d [%s]%s %s",
                           self.state.current_hp,
                           self.state.max_hp,
                           health_bar,
                           shield_display,
                           effects_display),
        color = hp_color,
        hp_percent = hp_percent
    }
end

-- Handle death
function Health:handle_death()
    vim.notify("💀 You have been defeated!", vim.log.levels.ERROR)
    -- Trigger game over logic
    return {
        is_dead = true,
        final_stats = {
            damage_taken_total = self.state.max_hp - self.state.current_hp,
            effects_suffered = vim.tbl_keys(self.state.status_effects)
        }
    }
end

return Health
