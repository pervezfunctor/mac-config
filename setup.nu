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
  if not (($src | path exists) and (($src | path type) != "dir")) {
    log error $"($src) does not exist or is a directory. Skipping linking."
    return
  }

  do -i { ^trash $dst e> /dev/null }
  log info $"linking ($src) -> ($dst)"
  ^ln -sf $src $dst
}

def "main stow" [package: string] {
  let root = (($env.DOT_DIR | path join $package) | path expand)

  for f in (glob $"($root)/**/*" --no-dir) {
    let src = ($f | path expand)
    let rel = ($src | path relative-to $root)
    let dst = ($env.HOME | path join ".config" $package $rel)
    mkdir $dst
    sln $src $dst
  }
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
  brew install -q font-jetbrains-mono-nerd-font font-monaspace-nerd-font
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

let COMMANDS = {
  kitty: {
    desc: "Install and configure kitty"
    run: {|| main kitty }
  }
  uv: {
    desc: "Install uv(Python)"
    run: {|| main uv }
  }
  cpp: {
    desc: "Install C++ tooling"
    run: {|| main cpp }
  }
  rust: {
    desc: "Install Rust(rustup)"
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
  apps: {
    desc: "Install apps like telegram, obsidian"
    run: {|| main apps }
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
