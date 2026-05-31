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
export PATH="/opt/homebrew/bin:$PATH"
```

## Python

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
sudo chsh -s $(command -v fish) "$USER"
```

Install and use starship prompt.

```bash
curl -sS https://starship.rs/install.sh | sh
```

Add starship to your shell config.

```fish
mkdir -p ~/.config/fish
touch ~/.config/fish/config.fish
echo 'starship init fish | source' >> ~/.config/fish/config.fish
```

Make sure to add the following line to add homebrew to your PATH in ~/.config/fish/config.fish

```fish
set -gx PATH "/opt/homebrew/bin:$PATH"
```

Few modern shell tools

```bash
brew install trash-cli fzf eza zoxide bat gh ripgrep tealdeer direnv fd jq bottom htop
```

If this is too cumbersome, use my script to setup what you need from this repo`s [README](https://github.com/pervezfunctor/mac-config)
