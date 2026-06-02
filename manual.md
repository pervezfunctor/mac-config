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
eval "$(/opt/homebrew/bin/brew shellenv)"
```

## Shell (Optional)

Install packages for the shell.

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
mkdir -p ~/.config/fish
touch ~/.config/fish/config.fish
echo 'starship init fish | source' >> ~/.config/fish/config.fish
echo 'set -gx PATH "/opt/homebrew/bin:$PATH"' >> ~/.config/fish/config.fish
```

## UI Tools

Install Visual Studio Code and Ghostty

```bash
brew install ghostty visual-studio-code font-jetbrains-mono-nerd-font 
```

Use `Catppuccin Mocha` theme and `Jetbrains Mono Nerd Font` font in your terminal and vscode editor. Use `cmd+,` to open settings(both terminal and vscode).
