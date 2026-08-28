# Minimal MacOS Config

## Bootstrap

Make sure xcode command line tools are installed.

```sh
git -v
```

Clone this repository. 

```sh
git clone --depth=1 https://github.com/pervezfunctor/mac-config.git ~/.mac-config
```

Run the bootstrap script. This installs recommended shell tools, vscode, kitty and ai tools.

If you don't want certain packages to be installed, you could remove them from `~/.mac-config/Brewfile` before running the bootstrap script.

Similarly if you don't want any your own config to be replaced, remove such directories from `~/.mac-config/config`. 
DO NOT remove `~/.mac-config/config/zsh`. This script won't replace, only add a line to your existing zsh config.

```bash
sh ~/.mac-config/mac-setup
```

This runs the full setup: brew packages, AstroNvim, and config linking. Instead, you can also run individual steps:

```bash
sh ~/.mac-config/mac-setup config   # link config files; safe to rerun (backs up regular files)
sh ~/.mac-config/mac-setup packages # brew update + install Brewfile packages
sh ~/.mac-config/mac-setup upgrade  # upgrade installed brew packages
sh ~/.mac-config/mac-setup nvim     # install AstroNvim
```

## Theme switching

Run `theme-switcher` to choose a coordinated theme with `fzf`. The selection is
applied to Ghostty, Kitty, Zed, VS Code, Cursor, AstroNvim, tuicr, and Herdr.
The curated choices include Ayu Mirage, Gruvbox Dark, One Dark, every
Catppuccin flavor, and Tokyo Night Storm.

```bash
theme-switcher
theme-switcher --theme "Gruvbox Dark" # non-interactive
theme-switcher --list                 # show available themes
theme-switcher --dry-run              # preview the selected changes
```

The selected theme is saved in `.theme-current`, so `mac-setup config` reapplies
it on a new machine. The switcher synchronizes non-linked live Cursor and Kitty
files and reloads running Kitty and Ghostty instances. Existing Neovim sessions
still need a manual colorscheme reload or restart.
