# Minimal MacOS Config

## Bootstrap

Run the bootstrap script:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/pervezfunctor/mac-config/main/mac-setup)"
```

The bootstrap script clones the repo to `~/.mac-config`, installs homebrew and configures shell.

Reboot your computer and make sure `fish` is your default shell.

```sh
echo $SHELL
```

## Nushell setup commands

You could install and configure additional tools(like vscode, uv) using the following interactive script.

```sh
setup.nu
```

## Known Issues

If ghostty font or theme does not look right, then execute the following

```bash
trash "$HOME/Library/Application\ Support/com.mitchellh.ghostty/config.ghostty" 2>/dev/null
```
