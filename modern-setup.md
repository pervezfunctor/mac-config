# Development Environment on Macos

## Package Manager(homebrew)

First install xcode command line tools. Required for homebrew.

```bash
xcode-select --install
```

Install homebrew, the most popular package manager for macos(similar to apt on ubuntu)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
```

## Shell (Optional)

Install modern shell packages

```bash
brew install fish starship fzf eza zoxide bat gh ripgrep tealdeer direnv fd jq bottom htop
```

Set fish as the default shell. This is an excellent interactive shell with near perfect defaults.

```bash
printf '%s\n' "$(command -v fish)" | sudo tee -a /etc/shells
sudo chsh -s $(command -v fish) "$USER"
```

Add starship to your shell config and homebrew to your PATH.

```fish
mkdir -p ~/.config/fish/conf.d
touch ~/.config/fish/conf.d/custom.fish
echo 'starship init fish | source' >> ~/.config/fish/conf.d/custom.fish
echo 'set -gx PATH "/opt/homebrew/bin:$PATH"' >> ~/.config/fish/conf.d/custom.fish
```

## UI Tools

Install Zed editor and Ghostty terminal

```bash
brew install zed ghostty font-jetbrains-mono-nerd-font 
```

In Ghostty, press `cmd+,` to open settings file and configure font and theme.

```
font-family = "JetBrainsMono Nerd Font Mono"
font-size = 15
theme = light:Ayu Light, dark:Catppuccin Mocha
```

In Zed, press `cmd+option+,` to open settings file and configure font and theme.

```
{
  "auto_install_extensions": {
    "catppuccin": true,
    "catppuccin-icons": true,
    "git-firefly": true,
  },
  "ui_font_size": 16,
  "buffer_font_family": "JetBrainsMono Nerd Font Mono",
  "buffer_font_size": 15,
  "theme": {
    "mode": "system",
    "light": "Ayu Light",
    "dark": "Catppuccin Mocha",
  },
}
```
