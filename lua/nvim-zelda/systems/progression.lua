
-- Meta Progression System
local Progression = {}

Progression.skill_tree = {}
Progression.character_classes = {}
Progression.equipment = {}
Progression.achievements = {}

function Progression:init()
    self:load_skill_tree()
    self:load_character_classes()
    self:load_equipment_system()
    self:load_achievements()
end

-- Skill Tree System
function Progression:create_skill_tree()
    local tree = {
        branches = {
            movement = {
                name = "Swift Navigator",
                skills = {
                    {id = "quick_hjkl", name = "Quick Steps", cost = 1,
                     effect = "Movement speed +10%"},
                    {id = "word_jump", name = "Word Jumper", cost = 2,
                     effect = "Unlock w/b movement in combat"},
                    {id = "teleport", name = "Instant Transmission", cost = 5,
                     effect = "Unlock gg/G teleportation"}
                }
            },
            combat = {
                name = "Vim Warrior",
                skills = {
                    {id = "delete_mastery", name = "Delete Mastery", cost = 1,
                     effect = "dd does area damage"},
                    {id = "visual_combat", name = "Visual Combat", cost = 3,
                     effect = "Visual mode selections deal damage"},
                    {id = "macro_warrior", name = "Macro Warrior", cost = 5,
                     effect = "Recorded macros can be used as special attacks"}
                }
            },
            magic = {
                name = "Command Wizard",
                skills = {
                    {id = "regex_magic", name = "Regex Sorcery", cost = 2,
                     effect = "Regex patterns cast spells"},
                    {id = "ex_commands", name = "Ex Mastery", cost = 3,
                     effect = "Ex commands have magical effects"},
                    {id = "vimscript", name = "Script Caster", cost = 5,
                     effect = "Write vimscript for powerful spells"}
                }
            }
        },
        points_available = 0,
        points_spent = 0,
        unlocked_skills = {}
    }

    return tree
end

-- Character Classes
function Progression:create_character_classes()
    local classes = {
        {
            id = "normal_knight",
            name = "Normal Knight",
            description = "Master of movement and navigation",
            starting_stats = {
                speed = 1.2,
                damage = 1.0,
                defense = 1.1
            },
            special_abilities = {
                "dash" -- Can dash using number + hjkl
            },
            preferred_mode = "normal"
        },
        {
            id = "insert_mage",
            name = "Insert Mage",
            description = "Creator and manipulator of reality",
            starting_stats = {
                speed = 0.9,
                damage = 1.3,
                defense = 0.8
            },
            special_abilities = {
                "text_creation" -- Can create platforms with text
            },
            preferred_mode = "insert"
        },
        {
            id = "visual_ranger",
            name = "Visual Ranger",
            description = "Master of area selection and control",
            starting_stats = {
                speed = 1.0,
                damage = 1.1,
                defense = 1.0
            },
            special_abilities = {
                "area_select" -- Can select and manipulate areas
            },
            preferred_mode = "visual"
        },
        {
            id = "command_sage",
            name = "Command Sage",
            description = "Wielder of ancient Ex commands",
            starting_stats = {
                speed = 0.8,
                damage = 1.5,
                defense = 0.7
            },
            special_abilities = {
                "command_cast" -- Ex commands as spells
            },
            preferred_mode = "command"
        }
    }

    return classes
end

-- Equipment System
function Progression:create_equipment()
    local equipment = {
        weapons = {
            {
                id = "vim_blade",
                name = "Vim Blade",
                rarity = "common",
                stats = {damage = 5},
                effect = "Basic attacks use 'x' command"
            },
            {
                id = "regex_staff",
                name = "Staff of Regex",
                rarity = "rare",
                stats = {damage = 8, magic = 3},
                effect = "Enables regex pattern attacks"
            },
            {
                id = "macro_hammer",
                name = "Macro Hammer",
                rarity = "epic",
                stats = {damage = 12},
                effect = "Attacks can be recorded and replayed"
            },
            {
                id = "neovim_excalibur",
                name = "Neovim Excalibur",
                rarity = "legendary",
                stats = {damage = 20, speed = 5, magic = 10},
                effect = "All vim commands are enhanced"
            }
        },
        armor = {
            {
                id = "buffer_shield",
                name = "Buffer Shield",
                rarity = "common",
                stats = {defense = 5},
                effect = "Reduces damage by buffering"
            },
            {
                id = "syntax_armor",
                name = "Syntax Highlighting Armor",
                rarity = "rare",
                stats = {defense = 8, magic_resist = 3},
                effect = "Highlights incoming attacks"
            }
        },
        accessories = {
            {
                id = "quickfix_compass",
                name = "Quickfix Compass",
                rarity = "rare",
                stats = {speed = 3},
                effect = "Navigate to objectives quickly"
            },
            {
                id = "mark_ring",
                name = "Ring of Marks",
                rarity = "epic",
                stats = {magic = 5},
                effect = "Set and jump to marks in combat"
            }
        }
    }

    return equipment
end

-- Achievement System
function Progression:create_achievements()
    local achievements = {
        {
            id = "first_combo",
            name = "Combo Beginner",
            description = "Perform your first vim combo",
            points = 10,
            reward = {xp = 50}
        },
        {
            id = "speed_demon",
            name = "Speed Demon",
            description = "Complete a level in under 30 seconds",
            points = 25,
            reward = {xp = 200, item = "speed_boots"}
        },
        {
            id = "macro_master",
            name = "Macro Master",
            description = "Record and use 10 different macros",
            points = 50,
            reward = {xp = 500, title = "Macro Master"}
        },
        {
            id = "regex_wizard",
            name = "Regex Wizard",
            description = "Solve 25 regex puzzles",
            points = 75,
            reward = {xp = 750, item = "regex_staff"}
        },
        {
            id = "vim_god",
            name = "Vim God",
            description = "Complete the game without using arrow keys",
            points = 100,
            reward = {xp = 1000, title = "Vim God", item = "neovim_excalibur"}
        }
    }

    return achievements
end

-- Prestige System
function Progression:prestige_rebirth()
    local prestige_level = self:get_prestige_level() + 1

    -- Reset progress but grant permanent bonuses
    local bonuses = {
        xp_multiplier = 1.0 + (prestige_level * 0.1),
        starting_skill_points = prestige_level * 2,
        unlock_special_mode = prestige_level >= 3,
        cosmetic_unlock = self:get_prestige_cosmetic(prestige_level)
    }

    -- Reset player progress
    self:reset_progress()

    -- Apply prestige bonuses
    self:apply_prestige_bonuses(bonuses)

    vim.notify("⭐ Prestige Level " .. prestige_level .. " achieved!", vim.log.levels.INFO)

    return bonuses
end

return Progression
