# Minimal MacOS Config

## Bootstrap

Run the bootstrap script:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/pervezfunctor/mac-config/main/scripts/mac-setup)"
```

The bootstrap script clones the repo to `~/.mac-config`, installs homebrew and configures zsh.

You could install and configure additional tools(like vscode, fish, ghostty) using the following interactive script.

```sh
setup.nu
```

## Known Issues

If ghostty font or theme does not look right, then execute the following

```bash
setup.nu ghostty fix
```
