
-- Comprehensive Item System for nvim-zelda
local Items = {}

-- Item database
Items.database = {
    -- Consumables
    {
        id = "health_potion",
        name = "Health Potion",
        type = "consumable",
        rarity = "common",
        sprite = "🧪",
        effect = function(player)
            player.health:heal(50, "potion")
            return "Restored 50 HP!"
        end,
        description = "Restores 50 HP",
        drop_rate = 0.15
    },
    {
        id = "mega_potion",
        name = "Mega Potion",
        type = "consumable",
        rarity = "rare",
        sprite = "💉",
        effect = function(player)
            player.health:heal(100, "potion")
            return "Restored 100 HP!"
        end,
        description = "Restores 100 HP",
        drop_rate = 0.05
    },
    {
        id = "shield_crystal",
        name = "Shield Crystal",
        type = "consumable",
        rarity = "rare",
        sprite = "🔷",
        effect = function(player)
            player.health.state.current_shield = 50
            return "Shield activated!"
        end,
        description = "Grants 50 shield points",
        drop_rate = 0.08
    },
    {
        id = "vim_scroll",
        name = "Vim Scroll",
        type = "consumable",
        rarity = "epic",
        sprite = "📜",
        effect = function(player)
            player.vim_power = player.vim_power * 2
            return "Vim power doubled for 30 seconds!"
        end,
        description = "Doubles vim command power",
        drop_rate = 0.02
    },

    -- Equipment
    {
        id = "iron_sword",
        name = "Iron Sword",
        type = "weapon",
        rarity = "common",
        sprite = "🗡️",
        stats = {damage = 10, crit_chance = 0.1},
        description = "Basic sword (+10 damage)",
        drop_rate = 0.1
    },
    {
        id = "vim_blade",
        name = "Vim Blade",
        type = "weapon",
        rarity = "rare",
        sprite = "⚔️",
        stats = {damage = 20, crit_chance = 0.2, vim_bonus = 1.5},
        description = "Empowered by vim commands (+20 damage, +50% vim power)",
        drop_rate = 0.05
    },
    {
        id = "leather_armor",
        name = "Leather Armor",
        type = "armor",
        rarity = "common",
        sprite = "🎽",
        stats = {armor = 10, max_hp = 20},
        description = "Basic protection (+10 armor, +20 HP)",
        drop_rate = 0.1
    },
    {
        id = "regex_robe",
        name = "Regex Robe",
        type = "armor",
        rarity = "epic",
        sprite = "🥋",
        stats = {armor = 15, magic_resist = 30, regex_power = 2},
        description = "Mystical robe (+15 armor, regex commands 2x effective)",
        drop_rate = 0.03
    },

    -- Special Items
    {
        id = "golden_key",
        name = "Golden Key",
        type = "key",
        rarity = "rare",
        sprite = "🔑",
        description = "Opens golden chests and secret doors",
        drop_rate = 0.05
    },
    {
        id = "map_fragment",
        name = "Map Fragment",
        type = "quest",
        rarity = "uncommon",
        sprite = "🗺️",
        description = "Part of the ancient map",
        drop_rate = 0.08
    },
    {
        id = "vim_tome",
        name = "Ancient Vim Tome",
        type = "quest",
        rarity = "legendary",
        sprite = "📖",
        description = "Contains the secrets of vim mastery",
        drop_rate = 0.01
    },

    -- Temporary Buffs
    {
        id = "speed_boots",
        name = "Speed Boots",
        type = "buff",
        rarity = "uncommon",
        sprite = "👟",
        effect = function(player)
            player.speed = player.speed * 1.5
            vim.defer_fn(function()
                player.speed = player.speed / 1.5
            end, 30000)
            return "Speed increased for 30 seconds!"
        end,
        description = "Temporary speed boost",
        drop_rate = 0.12
    },
    {
        id = "berserker_potion",
        name = "Berserker Potion",
        type = "buff",
        rarity = "rare",
        sprite = "💊",
        effect = function(player)
            player.damage = player.damage * 2
            player.armor = player.armor * 0.5
            vim.defer_fn(function()
                player.damage = player.damage / 2
                player.armor = player.armor * 2
            end, 20000)
            return "Berserk mode! Double damage, half armor!"
        end,
        description = "Trade defense for offense",
        drop_rate = 0.06
    },

    -- Coins and Currency
    {
        id = "coin",
        name = "Coin",
        type = "currency",
        rarity = "common",
        sprite = "🪙",
        value = 1,
        description = "Standard currency",
        drop_rate = 0.3
    },
    {
        id = "gem",
        name = "Gem",
        type = "currency",
        rarity = "rare",
        sprite = "💎",
        value = 10,
        description = "Valuable gem worth 10 coins",
        drop_rate = 0.05
    },

    -- Food Items
    {
        id = "apple",
        name = "Apple",
        type = "food",
        rarity = "common",
        sprite = "🍎",
        effect = function(player)
            player.health:heal(10, "food")
            return "Restored 10 HP"
        end,
        description = "Simple healing food",
        drop_rate = 0.2
    },
    {
        id = "magic_mushroom",
        name = "Magic Mushroom",
        type = "food",
        rarity = "rare",
        sprite = "🍄",
        effect = function(player)
            -- Random effect
            local effects = {
                function() player.health:heal(50, "food") return "Healed 50 HP!" end,
                function() player.size = player.size * 2 return "You grew bigger!" end,
                function() player.invisible = true return "You're invisible!" end,
                function() player.health:apply_effect("poisoned", 5) return "Oh no, poisoned!" end
            }
            return effects[math.random(#effects)]()
        end,
        description = "Unpredictable effects",
        drop_rate = 0.04
    }
}

-- Inventory management
Items.inventory = {
    slots = {},
    max_slots = 20,
    equipped = {
        weapon = nil,
        armor = nil,
        accessory = nil
    }
}

-- Initialize item system
function Items:init()
    -- Create empty inventory slots
    for i = 1, self.inventory.max_slots do
        self.inventory.slots[i] = nil
    end
end

-- Generate random item drop
function Items:generate_drop(enemy_level, luck_modifier)
    luck_modifier = luck_modifier or 1

    local drops = {}
    for _, item in ipairs(self.database) do
        local drop_chance = item.drop_rate * luck_modifier

        -- Higher level enemies drop better items
        if item.rarity == "rare" then
            drop_chance = drop_chance * (enemy_level / 10)
        elseif item.rarity == "epic" then
            drop_chance = drop_chance * (enemy_level / 20)
        elseif item.rarity == "legendary" then
            drop_chance = drop_chance * (enemy_level / 50)
        end

        if math.random() < drop_chance then
            table.insert(drops, item)
        end
    end

    return drops
end

-- Add item to inventory
function Items:add_to_inventory(item)
    -- Find first empty slot
    for i = 1, self.inventory.max_slots do
        if not self.inventory.slots[i] then
            self.inventory.slots[i] = item
            vim.notify("📦 " .. item.name .. " added to inventory!", vim.log.levels.INFO)
            return true
        end
    end

    vim.notify("❌ Inventory full!", vim.log.levels.WARN)
    return false
end

-- Use item from inventory
function Items:use_item(slot_index, player)
    local item = self.inventory.slots[slot_index]
    if not item then
        return false, "No item in slot"
    end

    if item.type == "consumable" or item.type == "food" or item.type == "buff" then
        -- Use and remove
        local result = item.effect(player)
        self.inventory.slots[slot_index] = nil
        return true, result
    elseif item.type == "weapon" or item.type == "armor" then
        -- Equip item
        return self:equip_item(slot_index, player)
    else
        return false, "Cannot use " .. item.name
    end
end

-- Equip item
function Items:equip_item(slot_index, player)
    local item = self.inventory.slots[slot_index]
    if not item then return false end

    local slot_type = nil
    if item.type == "weapon" then
        slot_type = "weapon"
    elseif item.type == "armor" then
        slot_type = "armor"
    else
        return false, "Cannot equip " .. item.type
    end

    -- Swap with currently equipped
    local old_item = self.inventory.equipped[slot_type]
    self.inventory.equipped[slot_type] = item
    self.inventory.slots[slot_index] = old_item

    -- Apply stats
    if item.stats then
        for stat, value in pairs(item.stats) do
            if player[stat] then
                player[stat] = player[stat] + value
            end
        end
    end

    -- Remove old stats
    if old_item and old_item.stats then
        for stat, value in pairs(old_item.stats) do
            if player[stat] then
                player[stat] = player[stat] - value
            end
        end
    end

    return true, "Equipped " .. item.name
end

-- Get inventory display
function Items:get_inventory_display()
    local lines = {"=== INVENTORY ==="}

    -- Equipped items
    table.insert(lines, "")
    table.insert(lines, "EQUIPPED:")
    for slot, item in pairs(self.inventory.equipped) do
        if item then
            table.insert(lines, string.format("  %s: %s %s",
                                             slot:upper(),
                                             item.sprite,
                                             item.name))
        end
    end

    -- Inventory slots
    table.insert(lines, "")
    table.insert(lines, "ITEMS:")
    for i = 1, self.inventory.max_slots do
        if self.inventory.slots[i] then
            local item = self.inventory.slots[i]
            local rarity_color = {
                common = "",
                uncommon = "*",
                rare = "**",
                epic = "***",
                legendary = "****"
            }
            table.insert(lines, string.format("  [%d] %s %s%s",
                                             i,
                                             item.sprite,
                                             item.name,
                                             rarity_color[item.rarity] or ""))
        end
    end

    return table.concat(lines, "\n")
end

return Items
