# 🗡️ nvim-zelda

A lightweight, Zelda-inspired game plugin for Neovim that teaches you vim motions and commands through gameplay!

![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg)
![Lua](https://img.shields.io/badge/Lua-5.1+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-yellow.svg)

## ✨ Features

- 🎮 **Learn by Playing**: Master vim commands while playing a fun game
- 🗺️ **Quest System**: Progressive tutorials teaching vim concepts
- ⚔️ **Combat System**: Use vim delete commands to defeat enemies
- 💎 **Item Collection**: Practice yank and put commands
- 🏃 **Movement Training**: Master hjkl, word jumps, and line navigation
- 📚 **Teaching Mode**: Get tips and explanations as you play
- 🎯 **Lightweight**: Minimal dependencies, pure Lua implementation

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "jthom233/nvim-zelda",
  cmd = { "Zelda", "ZeldaStart" },
  config = function()
    require("nvim-zelda").setup({
      teach_mode = true,     -- Show vim tips while playing
      difficulty = "normal", -- easy, normal, hard
      width = 60,           -- Game window width
      height = 20,          -- Game window height
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'jthom233/nvim-zelda',
  config = function()
    require('nvim-zelda').setup()
  end
}
```

## 🎮 How to Play

### Starting the Game

```vim
:Zelda         " Start the game
:ZeldaStart    " Alternative command
:ZeldaQuit     " Quit the game
```

### Controls

#### Basic Movement (Level 1)
- `h` - Move left
- `j` - Move down
- `k` - Move up
- `l` - Move right

#### Advanced Movement (Level 2)
- `w` - Jump forward by word (5 spaces)
- `b` - Jump backward by word (5 spaces)
- `gg` - Jump to top of map
- `G` - Jump to bottom of map

#### Actions
- `d` - Attack/Delete enemies (when adjacent)
- `y` - Yank/Collect items
- `p` - Put/Place items
- `/` - Search for items (starts search tutorial)
- `q` - Quit game

### Game Elements

- `@` - You (the player)
- `E` - Enemy (defeat with 'd')
- `*` - Item (collect by moving over it)
- `#` - Wall (impassable)
- `.` - Grass (walkable)
- `C` - Chest (contains treasure)
- `K` - Key (opens doors)
- `D` - Door (requires key)

## 📖 Quest System

The game includes progressive quests that teach vim concepts:

1. **Basic Movement** - Master hjkl navigation
2. **Word Jumping** - Learn w and b movements
3. **Line Navigation** - Use gg, G, 0, and $
4. **Delete Operations** - Practice d, dd, and dw
5. **Yank and Put** - Master copying and pasting
6. **Search Commands** - Learn /, n, and N

Each completed quest rewards points and provides vim tips!

## ⚙️ Configuration

```lua
require('nvim-zelda').setup({
  -- Game window dimensions
  width = 60,
  height = 20,

  -- Enable teaching mode (shows vim tips)
  teach_mode = true,

  -- Difficulty: "easy", "normal", "hard"
  difficulty = "normal",
})
```

## 🎯 Learning Goals

This game helps you learn:

- **Basic Navigation**: Comfortable with hjkl movement
- **Word Motion**: Efficient movement with w, b, e
- **Line Motion**: Quick jumps with gg, G, 0, $
- **Operators**: Understanding d (delete), y (yank), p (put)
- **Search**: Using / for searching, n/N for navigation
- **Vim Philosophy**: Thinking in motions and operators

## 🛠️ Development

### Project Structure

```
nvim-zelda/
├── lua/
│   └── nvim-zelda/
│       ├── init.lua      # Main game logic
│       └── quests.lua    # Quest/tutorial system
├── plugin/
│   └── nvim-zelda.lua    # Plugin entry point
├── doc/
│   └── nvim-zelda.txt    # Help documentation
└── README.md
```

### Adding New Features

1. New game elements: Edit `sprites` table in `init.lua`
2. New commands: Add to `setup_mappings()` function
3. New quests: Add to `quests.lua`

## 🤝 Contributing

Contributions are welcome! Feel free to:

- Add new quests/tutorials
- Improve game mechanics
- Add new vim concepts to teach
- Fix bugs or improve performance

## 📄 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

- Inspired by classic Zelda games
- Built to make learning vim fun
- Created with MLRSA-NG framework

## 🎮 Tips for New Vim Users

1. **Start with hjkl**: Don't use arrow keys, build muscle memory
2. **Think in motions**: Combine operators (d, y) with motions (w, $)
3. **Use word jumps**: w and b are much faster than repeated h/l
4. **Search is powerful**: / is faster than navigating manually
5. **Practice makes perfect**: The more you play, the more natural it becomes!

---

*Happy gaming and vim learning! 🎮✨*