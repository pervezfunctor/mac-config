# Development Environment on Macos

## Package Manager(homebrew)

The `mac-setup` script requests the Xcode Command Line Tools installer when they are missing and exits. Run it again after installation completes. To install them manually:

```bash
xcode-select --install
```

Install homebrew, popular package manager for macos.

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
echo "starship init fish | source" >> ~/.config/fish/conf.d/custom.fish
echo "fish_add_path /opt/homebrew/bin" >> ~/.config/fish/conf.d/custom.fish
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
theme = Ayu Mirage
```

In Zed, press `cmd+option+,` to open settings file and configure font and theme.

```
{
  "auto_install_extensions": {
    "git-firefly": true,
  },
  "ui_font_size": 16,
  "buffer_font_family": "JetBrainsMono Nerd Font",
  "buffer_font_size": 15,
  "terminal": {
    "font_family": "JetBrainsMono Nerd Font",
    "font_size": 15,
  },
  "theme": {
    "mode": "dark",
    "light": "Ayu Mirage",
    "dark": "Ayu Mirage",
  },
}
```
