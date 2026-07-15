# Minimal MacOS Config

## Bootstrap

Clone this repository. You might be asked to install xcode command line tools.

```sh
git -v
git clone --depth=1 https://github.com/pervezfunctor/mac-config.git ~/.mac-config
```

Run the bootstrap script. This installs recommended shell tools, vscode, kitty and ai tools.

If you don't want certain packages to be installed, you could remove them from `~/.mac-config/Brewfile` before running the bootstrap script.

Similarly if you don't want any your own config to be replaced, remove such directories from `~/.mac-config/config`. 
DO NOT remove `~/.mac-config/config/zsh`. This script won't replace, only add a line to your existing zsh config.

```bash
sh ~/.mac-config/mac-setup
```

This runs the full setup: brew packages, AstroNvim, and config sync. You can also run individual steps:

```bash
sh ~/.mac-config/mac-setup config   # sync config only; cheap, safe to rerun (backs up replaced files)
sh ~/.mac-config/mac-setup packages # brew update + install Brewfile packages
sh ~/.mac-config/mac-setup upgrade  # upgrade installed brew packages
sh ~/.mac-config/mac-setup nvim     # install AstroNvim
```

Restart your terminal. If all looks good you can delete the cloned repository (keep it if you plan to rerun `mac-setup config` later).

```sh
trash ~/.mac-config
```
