# Minimal MacOS Config

## Bootstrap

Run the bootstrap script:

```sh
curl -fsSL https://raw.githubusercontent.com/pervezfunctor/mac-config/main/mac-setup | sh
```

The bootstrap script clones the repo to `~/.mac-config`, installs homebrew and configures shell.

## Nushell setup commands

After the repo is available locally, run the Nushell entrypoint directly:

```sh
setup.nu
```

Available commands include:

```sh
nu setup.nu help
nu setup.nu kitty
nu setup.nu vscode
```

## Dotfile layout

`setup.nu stow` is intentionally simple.

- Pass a package name like `kitty`, or `niri`
- The package is resolved from `$DOT_DIR/<package>`
- Files are linked into `~/.config/<package>/...`

Example:

```sh
nu setup.nu stow kitty
```

This links files from `$DOT_DIR/kitty` into `~/.config/kitty`.
