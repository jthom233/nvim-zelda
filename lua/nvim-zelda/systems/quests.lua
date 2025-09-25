
-- Quest System for nvim-zelda
local Quests = {}

-- Quest database
Quests.database = {
    -- Main Story Quests
    {
        id = "learn_basics",
        name = "Vim Novice",
        type = "main",
        description = "Master the basic vim motions",
        objectives = {
            {task = "move_with_hjkl", description = "Move 100 steps using h,j,k,l",
             progress = 0, required = 100, completed = false},
            {task = "defeat_enemies", description = "Defeat 5 enemies",
             progress = 0, required = 5, completed = false},
            {task = "collect_items", description = "Collect 10 items",
             progress = 0, required = 10, completed = false}
        },
        rewards = {
            xp = 100,
            items = {"health_potion", "iron_sword"},
            unlock_quest = "advanced_motions"
        },
        dialogue = {
            start = "Welcome, young vimmer! Let's start with the basics.",
            complete = "Excellent! You've mastered the fundamentals."
        }
    },
    {
        id = "advanced_motions",
        name = "Motion Master",
        type = "main",
        description = "Learn advanced vim movement",
        objectives = {
            {task = "use_word_jump", description = "Use w/b movement 20 times",
             progress = 0, required = 20, completed = false},
            {task = "use_goto", description = "Use gg/G commands 10 times",
             progress = 0, required = 10, completed = false},
            {task = "perform_combo", description = "Execute a 5-hit combo",
             progress = 0, required = 5, completed = false}
        },
        rewards = {
            xp = 250,
            items = {"vim_blade", "speed_boots"},
            unlock_quest = "boss_battle_1"
        }
    },

    -- Side Quests
    {
        id = "treasure_hunter",
        name = "Treasure Hunter",
        type = "side",
        description = "Find hidden treasures",
        objectives = {
            {task = "find_chests", description = "Open 5 treasure chests",
             progress = 0, required = 5, completed = false},
            {task = "collect_coins", description = "Collect 100 coins",
             progress = 0, required = 100, completed = false}
        },
        rewards = {
            xp = 150,
            items = {"golden_key", "gem"},
            title = "Treasure Hunter"
        }
    },
    {
        id = "monster_slayer",
        name = "Monster Slayer",
        type = "side",
        description = "Prove your combat prowess",
        objectives = {
            {task = "defeat_slimes", description = "Defeat 20 slimes",
             progress = 0, required = 20, completed = false},
            {task = "no_damage_room", description = "Clear a room without taking damage",
             progress = 0, required = 1, completed = false}
        },
        rewards = {
            xp = 200,
            items = {"berserker_potion", "leather_armor"},
            achievement = "monster_slayer"
        }
    },

    -- Hidden Quests
    {
        id = "secret_of_vim",
        name = "The Secret of Vim",
        type = "hidden",
        description = "Discover the ancient vim secrets",
        hidden_trigger = "find_vim_tome",
        objectives = {
            {task = "collect_tomes", description = "Find all 3 Vim Tomes",
             progress = 0, required = 3, completed = false},
            {task = "solve_regex_puzzle", description = "Solve the master regex puzzle",
             progress = 0, required = 1, completed = false},
            {task = "perfect_macro", description = "Record a perfect 10-command macro",
             progress = 0, required = 10, completed = false}
        },
        rewards = {
            xp = 1000,
            items = {"neovim_excalibur"},
            title = "Vim Master",
            special_ability = "vim_enlightenment"
        }
    },

    -- Daily Quests
    {
        id = "daily_practice",
        name = "Daily Practice",
        type = "daily",
        description = "Today's vim practice",
        objectives = {
            {task = "play_time", description = "Play for 10 minutes",
             progress = 0, required = 600, completed = false},
            {task = "use_commands", description = "Use 50 vim commands",
             progress = 0, required = 50, completed = false}
        },
        rewards = {
            xp = 50,
            items = {"health_potion"},
            daily_streak = 1
        }
    }
}

-- Active quest tracking
Quests.active = {
    main = nil,
    side = {},
    hidden = {},
    daily = nil
}

Quests.completed = {}

-- Initialize quest system
function Quests:init()
    -- Start with first main quest
    self:start_quest("learn_basics")

    -- Load daily quest
    self:generate_daily_quest()
end

-- Start a quest
function Quests:start_quest(quest_id)
    local quest = self:get_quest_by_id(quest_id)
    if not quest then return false end

    if quest.type == "main" then
        self.active.main = vim.deepcopy(quest)
    elseif quest.type == "side" then
        table.insert(self.active.side, vim.deepcopy(quest))
    elseif quest.type == "hidden" then
        table.insert(self.active.hidden, vim.deepcopy(quest))
    elseif quest.type == "daily" then
        self.active.daily = vim.deepcopy(quest)
    end

    -- Show quest dialogue
    if quest.dialogue and quest.dialogue.start then
        vim.notify("📜 " .. quest.dialogue.start, vim.log.levels.INFO)
    end

    vim.notify("🎯 New Quest: " .. quest.name, vim.log.levels.INFO)
    return true
end

-- Update quest progress
function Quests:update_progress(task_type, amount)
    amount = amount or 1

    -- Check all active quests
    local quests_to_check = {self.active.main}
    vim.list_extend(quests_to_check, self.active.side)
    vim.list_extend(quests_to_check, self.active.hidden)
    if self.active.daily then
        table.insert(quests_to_check, self.active.daily)
    end

    for _, quest in ipairs(quests_to_check) do
        if quest then
            for _, objective in ipairs(quest.objectives) do
                if objective.task == task_type and not objective.completed then
                    objective.progress = math.min(
                        objective.progress + amount,
                        objective.required
                    )

                    -- Check if objective completed
                    if objective.progress >= objective.required then
                        objective.completed = true
                        vim.notify("✅ Objective Complete: " .. objective.description,
                                 vim.log.levels.INFO)

                        -- Check if quest completed
                        if self:is_quest_complete(quest) then
                            self:complete_quest(quest)
                        end
                    end
                end
            end
        end
    end
end

-- Check if quest is complete
function Quests:is_quest_complete(quest)
    for _, objective in ipairs(quest.objectives) do
        if not objective.completed then
            return false
        end
    end
    return true
end

-- Complete a quest
function Quests:complete_quest(quest)
    vim.notify("🎊 Quest Complete: " .. quest.name, vim.log.levels.INFO)

    -- Give rewards
    if quest.rewards then
        -- XP reward
        if quest.rewards.xp then
            vim.notify("⭐ +" .. quest.rewards.xp .. " XP", vim.log.levels.INFO)
        end

        -- Item rewards
        if quest.rewards.items then
            for _, item_id in ipairs(quest.rewards.items) do
                vim.notify("📦 Received: " .. item_id, vim.log.levels.INFO)
            end
        end

        -- Unlock next quest
        if quest.rewards.unlock_quest then
            self:start_quest(quest.rewards.unlock_quest)
        end
    end

    -- Show completion dialogue
    if quest.dialogue and quest.dialogue.complete then
        vim.notify("💬 " .. quest.dialogue.complete, vim.log.levels.INFO)
    end

    -- Move to completed
    table.insert(self.completed, quest)

    -- Remove from active
    if quest.type == "main" then
        self.active.main = nil
    elseif quest.type == "side" then
        -- Remove from side quests
        for i, q in ipairs(self.active.side) do
            if q.id == quest.id then
                table.remove(self.active.side, i)
                break
            end
        end
    end
end

-- Generate daily quest
function Quests:generate_daily_quest()
    local date = os.date("%Y%m%d")
    math.randomseed(tonumber(date))

    local daily_objectives = {
        {task = "defeat_enemies", description = "Defeat %d enemies",
         min = 10, max = 30},
        {task = "collect_coins", description = "Collect %d coins",
         min = 50, max = 200},
        {task = "use_combos", description = "Perform %d combos",
         min = 5, max = 15},
        {task = "explore_rooms", description = "Explore %d rooms",
         min = 5, max = 15}
    }

    -- Pick 2-3 random objectives
    local num_objectives = math.random(2, 3)
    local selected = {}

    for i = 1, num_objectives do
        local obj = daily_objectives[math.random(#daily_objectives)]
        local required = math.random(obj.min, obj.max)
        table.insert(selected, {
            task = obj.task,
            description = string.format(obj.description, required),
            progress = 0,
            required = required,
            completed = false
        })
    end

    self.active.daily = {
        id = "daily_" .. date,
        name = "Daily Challenge",
        type = "daily",
        description = "Complete today's challenges",
        objectives = selected,
        rewards = {
            xp = 100 * num_objectives,
            items = {"health_potion"},
            daily_streak = 1
        }
    }
end

-- Get quest display
function Quests:get_quest_display()
    local lines = {"=== ACTIVE QUESTS ==="}

    -- Main quest
    if self.active.main then
        table.insert(lines, "")
        table.insert(lines, "📍 MAIN: " .. self.active.main.name)
        for _, obj in ipairs(self.active.main.objectives) do
            local check = obj.completed and "✅" or "⬜"
            table.insert(lines, string.format("  %s %s (%d/%d)",
                                             check,
                                             obj.description,
                                             obj.progress,
                                             obj.required))
        end
    end

    -- Side quests
    if #self.active.side > 0 then
        table.insert(lines, "")
        table.insert(lines, "📋 SIDE QUESTS:")
        for _, quest in ipairs(self.active.side) do
            table.insert(lines, "  • " .. quest.name)
            for _, obj in ipairs(quest.objectives) do
                if not obj.completed then
                    table.insert(lines, string.format("    - %s (%d/%d)",
                                                     obj.description,
                                                     obj.progress,
                                                     obj.required))
                    break -- Show only next objective
                end
            end
        end
    end

    -- Daily quest
    if self.active.daily then
        table.insert(lines, "")
        table.insert(lines, "⏰ DAILY: " .. self.active.daily.name)
        for _, obj in ipairs(self.active.daily.objectives) do
            local check = obj.completed and "✅" or "⬜"
            table.insert(lines, string.format("  %s %s (%d/%d)",
                                             check,
                                             obj.description,
                                             obj.progress,
                                             obj.required))
        end
    end

    return table.concat(lines, "\n")
end

-- Helper function
function Quests:get_quest_by_id(quest_id)
    for _, quest in ipairs(self.database) do
        if quest.id == quest_id then
            return quest
        end
    end
    return nil
end

return Quests
