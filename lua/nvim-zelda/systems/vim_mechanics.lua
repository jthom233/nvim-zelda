
-- Advanced Vim Mechanics System
local VimMechanics = {}

VimMechanics.spellbook = {}
VimMechanics.macro_recorder = {}
VimMechanics.regex_engine = {}

function VimMechanics:init()
    -- Initialize vim spell system
    self:load_spell_definitions()
    self:setup_macro_recorder()
    self:init_regex_engine()
end

-- Spell Casting using Ex Commands
function VimMechanics:cast_spell(command)
    local spells = {
        [":s/enemy/friend/g"] = {
            name = "Mind Control",
            effect = function(state)
                -- Convert enemies to allies
                for _, enemy in ipairs(state.enemies) do
                    enemy.faction = "ally"
                    enemy.sprite = "🤝"
                end
            end
        },
        [":g/treasure/d"] = {
            name = "Treasure Magnet",
            effect = function(state)
                -- Collect all visible treasures
                for _, item in ipairs(state.items) do
                    if item.type == "treasure" then
                        state.player.inventory:add(item)
                    end
                end
            end
        },
        [":%!sort"] = {
            name = "Order from Chaos",
            effect = function(state)
                -- Sort enemies by distance, making them predictable
                table.sort(state.enemies, function(a, b)
                    return self:distance_to_player(a) < self:distance_to_player(b)
                end)
            end
        },
        [":earlier 10s"] = {
            name = "Time Rewind",
            effect = function(state)
                -- Revert game state by 10 seconds
                state = self:load_checkpoint(os.time() - 10)
            end
        }
    }

    if spells[command] then
        spells[command].effect(self.game_state)
        vim.notify("🎯 Cast: " .. spells[command].name, vim.log.levels.INFO)
        return true
    end

    return false
end

-- Macro Recording Challenges
function VimMechanics:start_macro_challenge(challenge_id)
    local challenges = {
        {
            id = "repeat_pattern",
            description = "Record a macro to defeat 5 enemies in a pattern",
            validation = function(macro)
                -- Check if macro defeats exactly 5 enemies
                local test_state = vim.deepcopy(self.game_state)
                self:execute_macro(macro, test_state)
                return test_state.enemies_defeated == 5
            end
        },
        {
            id = "text_transform",
            description = "Record a macro to transform all text blocks",
            validation = function(macro)
                local test_text = "enemy
enemy
enemy"
                local result = self:apply_macro_to_text(macro, test_text)
                return result == "friend
friend
friend"
            end
        }
    }

    self.active_challenge = challenges[challenge_id]
    self.macro_recorder.recording = true
    vim.notify("📹 Recording macro for: " .. self.active_challenge.description)
end

-- Regex Dungeon System
function VimMechanics:create_regex_dungeon()
    local dungeon = {
        rooms = {},
        current_room = 1,
        completed = false
    }

    -- Generate regex puzzle rooms
    local puzzles = {
        {
            text = "The quick brown fox jumps over the lazy dog",
            pattern_required = "\<[qwerty]\w*",
            hint = "Match words starting with QWERTY row letters"
        },
        {
            text = "user@example.com admin@test.org guest@site.net",
            pattern_required = "\S\+@\S\+\.\(com\|org\)",
            hint = "Match only .com and .org emails"
        },
        {
            text = "Error at line 42: undefined
Warning at line 7: deprecated",
            pattern_required = "line \d\+",
            hint = "Extract all line numbers"
        }
    }

    for i, puzzle in ipairs(puzzles) do
        dungeon.rooms[i] = {
            puzzle = puzzle,
            solved = false,
            door_locked = true,
            enemies_spawned = false
        }
    end

    return dungeon
end

-- Visual Block Combat
function VimMechanics:visual_block_battle()
    local battle = {
        enemy_formation = self:generate_formation(),
        player_selection = {},
        combo_multiplier = 1
    }

    function battle:select_block(start_pos, end_pos)
        -- Calculate visual block selection
        local selection = {}
        for y = start_pos.y, end_pos.y do
            for x = start_pos.x, end_pos.x do
                table.insert(selection, {x = x, y = y})
            end
        end
        return selection
    end

    function battle:execute_block_action(action, selection)
        if action == "d" then
            -- Delete all enemies in selection
            self:remove_enemies_in_area(selection)
        elseif action == "c" then
            -- Change enemies to items
            self:transform_enemies_to_items(selection)
        elseif action == "y" then
            -- Copy enemy pattern for later paste
            self.copied_pattern = self:copy_formation(selection)
        end
    end

    return battle
end

-- Buffer Manipulation Puzzles
function VimMechanics:buffer_puzzle()
    local puzzle = {
        buffers = {},
        solution_buffer = nil,
        current_buffer = 1
    }

    -- Create multiple buffers with different parts
    puzzle.buffers[1] = {
        content = "function solve() {",
        modifiable = true
    }
    puzzle.buffers[2] = {
        content = "  return answer;",
        modifiable = true
    }
    puzzle.buffers[3] = {
        content = "}",
        modifiable = false
    }

    -- Player must arrange buffers correctly
    puzzle.solution = "function solve() {
  return answer;
}"

    function puzzle:check_solution()
        local combined = ""
        for _, buf in ipairs(self.buffers) do
            combined = combined .. buf.content .. "
"
        end
        return combined:match(self.solution)
    end

    return puzzle
end

-- Window Split Maze
function VimMechanics:create_split_maze()
    local maze = {
        layout = "complex",
        windows = {},
        player_window = 1,
        exit_window = 9
    }

    -- Create 3x3 grid of windows
    for i = 1, 9 do
        maze.windows[i] = {
            id = i,
            content = self:generate_maze_room(i),
            connections = self:get_valid_splits(i),
            items = math.random() > 0.7 and self:generate_item() or nil
        }
    end

    function maze:navigate(command)
        if command == "<C-w>h" then
            self:move_left()
        elseif command == "<C-w>j" then
            self:move_down()
        elseif command == "<C-w>k" then
            self:move_up()
        elseif command == "<C-w>l" then
            self:move_right()
        elseif command == "<C-w>s" then
            self:split_horizontal()
        elseif command == "<C-w>v" then
            self:split_vertical()
        end
    end

    return maze
end

return VimMechanics
