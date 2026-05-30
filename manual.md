# Development Environment on Macos

## Package Manager(homebrew)

First install xcode command line tools. Required for homebrew.

```bash
xcode-select --install
```

Then install Rosetta. Needed for some older apps.

```bash
/usr/sbin/softwareupdate --install-rosetta --agree-to-license
```

Install homebrew, the most popular package manager on macos(similar to apt on ubuntu)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

# Python

Install some of these recommended packages. Ghostty is the best terminal on macos and vscode editor is excellent for python. uv is required for python development.

```bash
brew install ghostty uv visual-studio-code font-jetbrains-mono-nerd-font
```

Use `Catppuccin Mocha` theme and `Jetbrains Mono Nerd Font` font in ghostty terminal and vscode editor. Use `cmd+,` to open settings(both ghostty and vscode).

## Shell (Optional)

Install and set fish as the default shell. This is an excellent interactive shell with near perfect defaults.

Install using

```bash
brew install fish
```

and set as default with the following commands.

```bash
printf '%s\n' "$(command -v fish)" | sudo tee -a /etc/shells
chsh -s $(command -v fish)
```

Install and use starship prompt.

```bash
curl -sS https://starship.rs/install.sh | sh
```

If absent, add the following line to ~/.config/fish/config.fish

```fish
starship init fish | source
```

Few modern shell tools

```bash
brew install trash-cli fzf eza zoxide bat gh ripgrep tealdeer direnv fd jq bottom htop
```

If this is too cumbersome, use my script to setup what you need from this repo`s [README](https://github.com/pervezfunctor/mac-config)
