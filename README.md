# Minimal MacOS Config

## Bootstrap

Clone this repository. You might be asked to install xcode command line tools.

```sh
git clone --depth=1 https://github.com/pervezfunctor/mac-config.git ~/.mac-config
```

Run the bootstrap script. This installs recommended shell tools, vscode, kitty and ai tools. 

If you don't want certain packages to be installed, you could remove them from `~/.mac-config/Brewfile`.

Similarly if you don't want any your own config to be replaced, remove such directories from `~/.mac-config/config`. 
DO NOT remove `~/.mac-config/config/zsh` as this script won't replace, only add to your existing zsh config.

```bash
sh ~/.mac-config/mac-setup
```

Restart your terminal. If all looks good delete the cloned repository.

```sh
trash ~/.mac-config
```
