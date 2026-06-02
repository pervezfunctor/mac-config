#!/usr/bin/env nu

use std/log
use std/util "path add"

$env.DOT_DIR = ($env.HOME | path join ".mac-config")

def has-cmd [cmd: string] {
  (which $cmd | is-not-empty)
}

def dir-exists [path: string] {
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

def die [msg: string] {
  log critical $msg

  error make {
    msg: $msg
    label: { text: "fatal error", span: (metadata $msg).span }
  }
}

def sln [src: string, dst: string] {
  if not ($src | path exists) {
    log error $"($src) does not exist. Skipping linking."
    return
  }

  if (($src | path type) == "dir") {
    log error $"($src) is a directory. Skipping linking."
    return
  }

  do -i { trash $dst }
  log info $"linking ($src) -> ($dst)"
  ln -sf $src $dst
}

def stow-any [src: string, dst: string] {
  let root = ($src | path expand)

  for f in (glob $"($root)/**/*" --no-dir) {
    let p = ($f | path expand)
    let rel = ($p | path relative-to $root)
    let target = ($dst | path join $rel)
    let parent = ($target | path dirname)
    if not ($parent | path exists) {
      mkdir $parent
    }
    sln $p $target
  }
}

def "main stow" [package: string] {
  let root = (($env.DOT_DIR | path join $package) | path expand)
  let target = ($env.HOME | path join ".config" $package)
  stow-any $root $target
}

def "main stow home" [package: string] {
  let root = (($env.DOT_DIR | path join $package) | path expand)
  stow-any $root $env.HOME
}

def --env bootstrap [] {
  path add $env.DOT_DIR
  path add "/opt/homebrew/bin"

  [
    "bin"
    ".local/bin"
    ".cargo/bin"
    ".local/bin"
  ] | each {|p| path add ($env.HOME | path join $p) }
}

def "main vscode install" [] {
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
  ] | each { |ext| try {
    code --install-extension $ext
    } catch { |e|
      log warning $"Failed to install ($ext): ($e.msg)"
    }
  }

  do -i {
    log+ "Copying settings"
    cp ~/.mac-config/vscode/settings.json $"($env.HOME)/Library/Application Support/Code/User/settings.json"
  }
}

def "main vscode" [] {
  main vscode install
  main vscode config
}

def "main cpp" [] {
  log+ "Installing C++ tools"
  brew install -q make cmake boost catch2 ccache clang-format cpp-gsl ninja watchexec pkg-config
}

def "main rust" [] {
  if (has-cmd rustup) {
    log+ "rustup is already installed"
    return
  }

  log+ "Installing Rust"
  http get https://sh.rustup.rs | sh -s -- -y
}

def "main zed" [] {
  log+ "Installing Zed"
  brew install -q zed
  main stow "zed"
}

def "main ghostty fix" [] {
    let ghostty_config = $"($env.HOME)/Library/Application Support/com.mitchellh.ghostty/config.ghostty"

    mkdir ($ghostty_config | path dirname)

    'config-file = ~/.config/ghostty/config'
    | save --force $ghostty_config
}

def "main ghostty" [] {
  log+ "Installing ghostty"
  brew install -q ghostty
  do -i { main ghostty fix }
  main stow "ghostty"
}

def set-fish-as-default-shell [] {
  if not (has-cmd fish) {
    die "fish not found. Quitting."
  }

  let fish_path = (which fish | first | get path)

  if (($env.SHELL? | default "") == $fish_path) {
    log+ "fish is already the default shell."
    return
  }

  if not ($fish_path in (open /etc/shells | lines)) {
    log warning $"Adding ($fish_path) to /etc/shells."
    try {
      $"($fish_path)\n" | sudo tee -a /etc/shells | ignore
    } catch {
      log warning $"Failed to add ($fish_path) to /etc/shells."
      return
    }
  } else {
    log+ $"($fish_path) is already in /etc/shells."
  }

  log+ "Setting fish as default shell..."
  try {
    chsh -s $fish_path
    log+ $"Default shell set to fish \(($fish_path)\). Re-login to apply."
  } catch {
    log warning $"Failed to set fish as default shell. Try running 'chsh -s ($fish_path)' manually."
  }
}

def fish-config [] {
  if not (has-cmd fish) {
    die "fish not installed. Quitting."
  }

  set-fish-as-default-shell

  let src = ($env.DOT_DIR | path join "fish/config.fish")
  let dst = ($env.HOME | path join ".config/fish/config.fish")

  if (($dst | path exists)
    and (($dst | path type) == "symlink")
    and ((readlink $dst) == $src)) {
    log+ "fish config is already symlinked. Skipping."
    return
  }

  mkdir ($dst | path dirname)
  sln $src $dst
}

def "main shell" [] {
  brew install -q ...[
    bat
    bottom
    carapace
    direnv
    eza
    fd
    fish
    font-monaspace-nerd-font
    fzf
    gh
    jq
    ripgrep
    shellcheck
    shfmt
    starship
    tealdeer
    unar
    unzip
    xh
    zellij
    zip
    zoxide
    zstd
  ]

  fish-config
  do -i { tldr --update }
}

def "main vp" [] {
  if (has-cmd vp) {
    log info "vp is already installed"
    return
  }

  log info "Installing vp"
  http get https://vite.plus | bash

  log info "Installing node"
  ~/.vite-plus/bin/vp env install latest
  path add $"($env.HOME)/.vite-plus/bin"
}

def "main apps" [] {
  log+ "Installing apps"
  brew install -q --cask obsidian telegram-desktop
}

def "main ai" [] {
  log+ "Installing codex, claude and opencode"
  brew install ...[
    antigravity
    antigravity-cli
    claude
    claude-code
    codex
    codex-app
    google-chrome
    opencode
  ]
}

let COMMANDS = {
  ghostty: {
    desc: "Install and configure ghostty"
    run: {|| main ghostty }
  }
  cpp: {
    desc: "Install C++ tooling"
    run: {|| main cpp }
  }
  rust: {
    desc: "Install Rust with rustup"
    run: {|| main rust }
  }
  vscode: {
    desc: "Install vscode and extensions"
    run: {|| main vscode }
  }
  zed: {
    desc: "Install and configure Zed editor"
    run: {|| main zed }
  }
  ai: {
    desc: "Install ai apps: claude, codex, opencode"
    run: {|| main ai }
  }
  apps: {
    desc: "Install apps like telegram, obsidian"
    run: {|| main apps }
  }
  shell: {
    desc: "fish as default + modern shell tools"
    run: {|| main shell }
  }
  vp: {
    desc: "Install vp"
    run: {|| main vp }
  }
}

def run-command [cmd: string] {
  let key = ($cmd | str trim)
  if not ($key in $COMMANDS) {
    log warning $"Unknown command: ($key)"
    return
  }
  do ($COMMANDS | get $key).run
}

def select-install [] {
  $COMMANDS | columns
  | input list --multi "Select commands to run"
  | each {|cmd| run-command $cmd }
  | ignore
}

def "main help" [] {
  print ""
  print "Usage:"
  print "  setup.nu"
  print "  setup.nu <command>"
  print ""
  print "Commands:"

  $COMMANDS | items {|k, v| print $"  ($k | fill -w 16) ($v.desc)" }

  print ""
}

def main [] {
  bootstrap
  select-install
}
