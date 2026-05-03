#!/usr/bin/env nu

use std/log
use std/util "path add"

export-env {
  $env.DOT_DIR = ($env.HOME | path join ".mac-config")
}

export def has-cmd [cmd: string] {
  (which $cmd | is-not-empty)
}

export def dir-exists [path: string] {
  if not ($path | path exists) {
    return false
  }

  ($path | path type) == "dir"
}

def is-mac [] {
    $nu.os-info.name == "macos"
}

def log+ [msg: string] {
  log info $msg
}

export def die [msg: string] {
  log critical $msg

  error make {
    msg: $msg
    label: { text: "fatal error", span: (metadata $msg).span }
  }
}

export def ensure-dir [path: string] {
  if not (dir-exists $path) {
    log+ $"creating directory: ($path)"
    mkdir $path
  }
}

export def ensure-parent-dir [path: string] {
  let parent = ($path | path dirname)
  ensure-dir $parent
}

export def sln [src: string, dst: string] {
  if not (($src | path exists) and (($src | path type) != "dir")) {
    log error $"($src) does not exist or is a directory. Skipping linking."
    return
  }

  do -i { ^trash $dst e> /dev/null }
  log info $"linking ($src) -> ($dst)"
  ^ln -sf $src $dst
}

export def "main stow" [package: string] {
  let root = (($env.DOT_DIR | path join $package) | path expand)

  for f in (glob $"($root)/**/*" --no-dir) {
    let src = ($f | path expand)
    let rel = ($src | path relative-to $root)
    let dst = ($env.HOME | path join ".config" $package $rel)
    ensure-parent-dir $dst
    sln $src $dst
  }
}

def cmd-check [...cmd: string] {
  $cmd
  | where {|c| not (has-cmd $c) }
  | each {|c| die $"command not found: ($c)" }
}

def --env bootstrap [] {
  path add $env.DOT_DIR
  path add "/opt/homebrew/bin"

  [
    "bin"
    ".local/bin"
    ".cargo/bin"
  ] | each {|p| path add ($env.HOME | path join $p) }
}


def "main fonts" [] {
  log+ "Installing fonts"
  brew install -q font-jetbrains-mono-nerd-font
}

def "main vscode install" [] {
  main fonts

  if not (has-cmd code) {
    log+ "Installing vscode"
    brew install -q visual-studio-code
  }
}

def "main vscode config" [] {
  log+ "Installing vscode extensions"

  [
    "Catppuccin.catppuccin-vsc"
    "charliermarsh.ruff"
    "llvm-vs-code-extensions.vscode-clangd"
    "marimo-team.vscode-marimo"
    "ms-python.debugpy"
    "ms-python.python"
    "ms-python.vscode-python-envs"
    "ms-toolsai.jupyter"
    "ms-vscode.cmake-tools"
    "ms-vscode.cpptools"
    "rust-lang.rust-analyzer"
  ] | each {|ext| do -i { ^code --install-extension $ext }}

  main stow "Code"
}

def "main vscode" [] {
  main vscode install
  main vscode config
}

def is-shell-default [shell_path: string] {
  open /etc/passwd
  | lines
  | parse "{user}:{rest}"
  | where user == $env.USER
  | first
  | get rest
  | str ends-with $shell_path
}

def "main fish default" [] {
  log+ "Setting fish as default shell"
  let fish_path = (which fish | get 0.path)
  if not (open /etc/shells | lines | any {|l| $l == $fish_path }) {
    $fish_path | sudo tee -a /etc/shells
  }
  if not (is-shell-default $fish_path) {
    do -i { chsh -s $fish_path $env.USER }
  }
}

def "main fish" [] {
  log+ "Installing fish"

  brew install -q fish
  main stow "fish"
}

export def "main brew" [] {
  if (has-cmd brew) { return }

  log+ "Installing brew"
  http get "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" | bash
}

def "main cpp" [] {
  log+ "Installing C++ tools"
  brew install -q make cmake boost catch2 ccache clang-format cpp-gsl ninja
}

def "main rust" [] {
  if (has-cmd rustup) {
    log+ "rustup is already installed"
    return
  }

  log+ "Installing Rust"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
}

def "main zed" [] {
  log+ "Installing Zed"
  brew install -q zed
  main stow "zed"
}

def "main uv" [] {
  log+ "Installing uv"
  brew install -q uv
}

def "main kitty" [] {
  log+ "Installing kitty"
  brew install -q kitty
  main fonts
  main stow "kitty"
}

def "main apps" [] {
  log+ "Installing apps"
  brew install -q --cask obsidian telegram-desktop
  brew install -q unar zip zstd
}

def "main fish autostart" [] {
  let rc_file = ".zshrc"
  let rc_path = ($env.HOME | path join $rc_file)
  let marker = "exec fish"

  let snippet = '
# Auto-start fish for interactive shells
if [[ $- == *i* ]] && [[ -z "$FISH_LAUNCHED" ]]; then
  if command -v fish >/dev/null 2>&1; then
    export FISH_LAUNCHED=1
    exec fish || echo "Failed to start fish"
  fi
fi
'

  if not ($rc_path | path exists) {
    error make {msg: $"($rc_file) not found"}
  }
  if not (open $rc_path | str contains $marker) {
    $snippet | save --append $rc_path
    log+ $"Added fish auto-start to ($rc_file)"
  } else {
    log+ $"Fish auto-start already in ($rc_file), skipping"
  }
}

let COMMANDS = {
  shell: {
    desc: "Install shell tools"
    run: {|| main shell }
  }
  fish: {
    desc: "Install and configure fish shell"
    run: {|| main fish }
  }
  kitty: {
    desc: "Install and configure kitty"
    run: {|| main kitty }
  }
  uv: {
    desc: "Install uv for Python tooling"
    run: {|| main uv }
  }
  cpp: {
    desc: "Install C++ tooling"
    run: {|| main cpp }
  }
  rust: {
    desc: "Install Rust tooling"
    run: {|| main rust }
  }
  vscode: {
    desc: "Install vscode and extensions"
    run: {|| main vscode }
  }
  zed: {
    desc: "Install Zed"
    run: {|| main zed }
  }
  apps: {
    desc: "Install apps telegram, obsidian"
    run: {|| main apps }
  }
  "fish default": {
    desc: "Set fish as the default shell"
    run: {|| main fish default }
  }
  "fish autostart": {
    desc: "fish auto starts with (through ~/.zshrc)"
    run: {|| main fish autostart }
  }
}

def commands [] {
  $COMMANDS | transpose name value
}

def options [] {
  commands | get name
}

def run-command [cmd: string] {
  let key = ($cmd | str trim)
  let action = (
    commands
    | where name == $key
    | get value
    | first
  )

  if ($action | is-empty) {
    log warning $"Unknown command: ($key)"
    return
  }

  do $action.run
}

const DEFAULT_INSTALL = ["uv", "vscode"]

def gum-select-install [] {
  if not (has-cmd gum) {
    die "gum is required for interactive selection"
  }

  let defaults = ($DEFAULT_INSTALL | str join ",")

  options
  | str join "\n"
  | ^gum choose --no-limit --selected $defaults
  | lines
  | each {|cmd| run-command ($cmd | str trim) }
}

def "main help" [] {
  print ""
  print "Usage:"
  print "  setup.nu"
  print "  setup.nu <command>"
  print ""

  print "Commands:"

  commands
  | each {|row|
      print $"  ($row.name | fill -w 16) ($row.value.desc)"
    }

  print ""
}

def "main shell" [] {
  brew install -q nushell gum fish bat carapace direnv eza fd fzf gh jq xh \
    ripgrep tealdeer trash-cli zoxide starship make tmux unzip

  tldr --update

  main stow "tmux"
}

def "main fish setup" [] {
  let config = ($env.HOME | path join ".config/fish/config.fish")
  let target = ($env.DOT_DIR | path join "fish/config.fish")

  if (($config | path type) == "symlink" and (^readlink $config) == $target) {
    log+ "fish config already linked, skipping"
    return
  }

  ^trash $config
  ^ln -sf $target $config
  log+ "fish config linked"
}

def main [...cmds: string] {
  if not (is-mac) {
    die "Only Mac supported. Quitting."
  }

  bootstrap
  main brew

  if ($cmds | is-empty) {
    gum-select-install
  } else {
    $cmds | each {|cmd| run-command $cmd } | ignore
  }
}
