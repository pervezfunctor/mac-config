# Minimal MacOS Config

## Bootstrap

Run the bootstrap script:

```sh
curl -fsSL https://raw.githubusercontent.com/pervezfunctor/mac-config/main/mac-setup | sh
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
