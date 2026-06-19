#!/usr/bin/env nu

use std/log
use std/util "path add"

export-env {
  $env.DOT_DIR = ($env.HOME | path join ".mac-config")
}

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

def "main stow" [package: string, --root: string] {
  let stow_root = ($root | default ($env.HOME | path join ".config"))
  let src = ($env.DOT_DIR | path join $package | path expand)
  let target = ($stow_root | path join $package)

  for f in (glob $"($src)/**/*" --no-dir) {
    let p = ($f | path expand)
    let rel = ($p | path relative-to $src)
    let dst = ($target | path join $rel)

    mkdir ($dst | path dirname)
    sln $p $dst
  }
}

def --env bootstrap [] {
  path add ($env.DOT_DIR | path join "scripts")
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
    log info "Installing vscode"
    brew install -y -q visual-studio-code
  }
}

def "main vscode config" [] {
  log info "Installing vscode extensions"

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
    log info "Copying settings"
    cp ~/.mac-config/vscode/settings.json $"($env.HOME)/Library/Application Support/Code/User/settings.json"
  }
}

def "main vscode" [] {
  main vscode install
  main vscode config
}

def "main cpp" [] {
  log info "Installing C++ tools"
  brew install -y -q make cmake boost catch2 ccache clang-format cpp-gsl ninja watchexec pkg-config
}

def "main rust" [] {
  if (has-cmd rustup) {
    log info "rustup is already installed"
    return
  }

  log info "Installing Rust"
  http get https://sh.rustup.rs | sh -s -- -y
}

def "main zed" [] {
  log info "Installing Zed"
  brew install -y -q zed
  main stow "zed"
}

def "main ghostty fix" [] {
    let ghostty_config = $"($env.HOME)/Library/Application Support/com.mitchellh.ghostty/config.ghostty"

    mkdir ($ghostty_config | path dirname)

    'config-file = ~/.config/ghostty/config'
    | save --force $ghostty_config
}

def "main ghostty" [] {
  log info "Installing ghostty"
  brew install -y -q ghostty
  do -i { main ghostty fix }
  main stow "ghostty"
}

def "main fish shells" [] {
  let fish_path = (which fish | first | get path)

  if (($env.SHELL? | default "") == $fish_path) {
    log info "fish is already the default shell."
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
    log info $"($fish_path) is already in /etc/shells."
  }
}

def "main fish default" [] {
  main fish shells

  log info "Setting fish as default shell..."
  try {
    sudo chsh -s (which fish | first | get path) $env.USER
    log info $"Default shell set to fish. Re-login to apply."
  } catch {
    log warning $"Failed to set fish as default shell. Try running 'chsh -s (which fish | first | get path)' manually."
  }
}

def "main fish" [] {
  log info "Installing fish"
  brew install -y -q fish

  main stow "fish"
  main fish default
}

def "main scroller" [] {
  log info "Installing scroller for mac"
  brew tap BarutSRB/tap
  brew trust --cask barutsrb/tap/omniwm
  brew install -y -q omniwm
}

def "main shell" [] {
  log info "Installing shell tools"
  brew install -y -q ...[
    bat
    bottom
    carapace
    direnv
    eza
    fd
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
  do -i { tldr --update }
  main fish
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
  log info "Installing apps"
  brew install -y -q --cask obsidian telegram-desktop
}

def "main ai" [] {
  log info "Installing codex, claude and opencode"

  brew install -y -q ...[
    antigravity
    antigravity-cli
    antigravity-ide
    claude
    claude-code
    codex
    codex-app
    google-chrome
    opencode
    opencode-desktop
  ]
}

let COMMANDS = {
  shell: {
    desc: "fish as default + modern shell tools"
    run: {|| main shell }
  }
  ghostty: {
    desc: "Install and configure ghostty"
    run: {|| main ghostty }
  }
  zed: {
    desc: "Install and configure Zed editor"
    run: {|| main zed }
  }
  ai: {
    desc: "Install ai apps: claude, codex, opencode"
    run: {|| main ai }
  }
  vscode: {
    desc: "Install vscode and extensions"
    run: {|| main vscode }
  }
  cpp: {
    desc: "Install C++ tooling"
    run: {|| main cpp }
  }
  rust: {
    desc: "Install Rust with rustup"
    run: {|| main rust }
  }
  apps: {
    desc: "Install apps like telegram, obsidian"
    run: {|| main apps }
  }
  vp: {
    desc: "Install vp"
    run: {|| main vp }
  }
  scroller: {
    desc: "Install omniwm and borders for niri like scroller"
    run: {|| main scroller }
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
  print "  setup.nu                    Interactive selection"
  print "  setup.nu <command>          Run a command"
  print ""
  print "Commands:"

  $COMMANDS | items {|k, v| print $"  ($k | fill -w 16) ($v.desc)" }

  print ""
  print "  stow             Symlink a package: main stow <package> [--root <dir>]"
  print "  vscode install   Install vscode"
  print "  vscode config    Copy vscode settings & install extensions"
  print "  ghostty fix      Fix ghostty config path"
  print "  fish shells      Add fish to /etc/shells"
  print "  fish default     Set fish as the default shell"
  print ""
}

def main [] {
  bootstrap
  select-install
}
