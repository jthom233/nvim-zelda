-- Quest system for teaching vim commands
local M = {}

M.quests = {
    {
        id = "basic_movement",
        name = "Learn Basic Movement",
        description = "Master hjkl movement keys",
        objectives = {
            {command = "h", description = "Move left 5 times", count = 5, current = 0},
            {command = "j", description = "Move down 5 times", count = 5, current = 0},
            {command = "k", description = "Move up 5 times", count = 5, current = 0},
            {command = "l", description = "Move right 5 times", count = 5, current = 0},
        },
        reward = 50,
        teaching = "hjkl are the core vim movement keys. h=left, j=down, k=up, l=right"
    },
    {
        id = "word_movement",
        name = "Word Jumping",
        description = "Learn to move by words",
        objectives = {
            {command = "w", description = "Jump forward by word 3 times", count = 3, current = 0},
            {command = "b", description = "Jump backward by word 3 times", count = 3, current = 0},
        },
        reward = 75,
        teaching = "w moves forward by word, b moves backward. Much faster than hjkl!"
    },
    {
        id = "line_movement",
        name = "Line Navigation",
        description = "Jump to start and end",
        objectives = {
            {command = "gg", description = "Jump to top of map", count = 1, current = 0},
            {command = "G", description = "Jump to bottom of map", count = 1, current = 0},
            {command = "0", description = "Jump to start of line", count = 1, current = 0},
            {command = "$", description = "Jump to end of line", count = 1, current = 0},
        },
        reward = 100,
        teaching = "gg=top of file, G=bottom, 0=start of line, $=end of line"
    },
    {
        id = "delete_operations",
        name = "Delete Commands",
        description = "Learn the 'd' operator",
        objectives = {
            {command = "d", description = "Delete 3 enemies", count = 3, current = 0},
            {command = "dd", description = "Use dd (delete line)", count = 1, current = 0},
            {command = "dw", description = "Use dw (delete word)", count = 1, current = 0},
        },
        reward = 150,
        teaching = "d is the delete operator. dd=delete line, dw=delete word, d$=delete to end"
    },
    {
        id = "yank_put",
        name = "Copy and Paste",
        description = "Master yanking and putting",
        objectives = {
            {command = "y", description = "Yank (copy) 3 items", count = 3, current = 0},
            {command = "p", description = "Put (paste) 2 times", count = 2, current = 0},
        },
        reward = 125,
        teaching = "y=yank(copy), p=put(paste). yy=yank line, yw=yank word"
    },
    {
        id = "search_commands",
        name = "Search and Find",
        description = "Learn to search efficiently",
        objectives = {
            {command = "/", description = "Search for items", count = 2, current = 0},
            {command = "n", description = "Next search result", count = 3, current = 0},
            {command = "N", description = "Previous result", count = 1, current = 0},
        },
        reward = 100,
        teaching = "/pattern searches forward, ?pattern searches backward, n=next, N=previous"
    },
}

-- Track current quest
M.current_quest = nil
M.completed_quests = {}

-- Start a quest
function M.start_quest(quest_id)
    for _, quest in ipairs(M.quests) do
        if quest.id == quest_id then
            M.current_quest = vim.deepcopy(quest)
            return quest
        end
    end
    return nil
end

-- Update quest progress
function M.update_progress(command)
    if not M.current_quest then
        return false
    end

    local quest_complete = true
    for _, objective in ipairs(M.current_quest.objectives) do
        if objective.command == command and objective.current < objective.count then
            objective.current = objective.current + 1

            if objective.current >= objective.count then
                vim.notify(string.format("✓ Objective complete: %s", objective.description),
                    vim.log.levels.INFO, {title = "Quest Progress"})
            end
        end

        if objective.current < objective.count then
            quest_complete = false
        end
    end

    if quest_complete then
        M.complete_quest()
    end

    return quest_complete
end

-- Complete current quest
function M.complete_quest()
    if M.current_quest then
        table.insert(M.completed_quests, M.current_quest.id)
        vim.notify(string.format("🎉 Quest Complete: %s! Reward: %d points",
            M.current_quest.name, M.current_quest.reward),
            vim.log.levels.INFO, {title = "Quest Complete!"})

        -- Show teaching message
        vim.notify(M.current_quest.teaching, vim.log.levels.INFO, {title = "Vim Tip"})

        M.current_quest = nil
        return true
    end
    return false
end

-- Get next available quest
function M.get_next_quest()
    for _, quest in ipairs(M.quests) do
        local completed = false
        for _, completed_id in ipairs(M.completed_quests) do
            if quest.id == completed_id then
                completed = true
                break
            end
        end
        if not completed then
            return quest
        end
    end
    return nil
end

-- Get quest status display
function M.get_quest_status()
    if not M.current_quest then
        return "No active quest"
    end

    local lines = {
        string.format("Quest: %s", M.current_quest.name),
        M.current_quest.description,
        "",
        "Objectives:"
    }

    for _, obj in ipairs(M.current_quest.objectives) do
        local status = obj.current >= obj.count and "✓" or string.format("%d/%d", obj.current, obj.count)
        table.insert(lines, string.format("  [%s] %s", status, obj.description))
    end

    return table.concat(lines, "\n")
end

return M