#!/usr/bin/env nu

use std/log

def die [msg: string] {
  log critical $msg

  error make {
    msg: $msg
    label: { text: "fatal error", span: (metadata $msg).span }
  }
}

def backup-dir [] {
  $env.HOME | path join ".local/share/mac-config-backup"
}

def timestamp-dir [prefix: string = "sync"] {
  (backup-dir) | path join $"($prefix)-(date now | format date '%Y-%m-%d_%H-%M-%S_%f')"
}

def sync-dir [rel_path: string, src: string, stamp: string] {
  if not ($src | path exists) {
    die $"Source directory does not exist: ($src)"
  }

  let dst = ($env.HOME | path join $rel_path)

  log info $"Syncing ($rel_path)/"
  rsync -avh -b --backup-dir=($stamp | path join $rel_path) $"($src)/" $"($dst)/"
}

def "main apply" [--yes (-y)] {
  if not $yes {
    log info "This will overwrite ~/.local/bin/ and .config/ with repo content."
    let answer = (input "Continue? [y/N] " | str trim | str downcase)
    if $answer != "y" {
      log info "Aborted."
      return
    }
  }

  let stamp = (timestamp-dir "sync")
  mkdir $stamp

  sync-dir ".local/bin" ($env.DOT_DIR | path join ".local/bin") $stamp
  sync-dir ".config" ($env.DOT_DIR | path join ".config") $stamp
}

def "main restore" [backup?: string] {
  let backups = (backup-dir)

  let dirs = try {
    ls $backups | where type == dir | get name
  } catch {
    []
  }
  if ($dirs | length) == 0 {
    die $"No backups found at ($backups)"
  }

  let names = ($dirs | each {|d| $d | path basename })

  let chosen = if ($backup | is-empty) {
    $names | input list "Select a backup to restore"
  } else if ($backup not-in $names) {
    die $"Backup not found: ($backup)"
  } else {
    $backup
  }
  if ($chosen | is-empty) {
    log info "No backup chosen. Aborted."
    return
  }

  let stamp = (timestamp-dir "pre-restore")
  mkdir $stamp

  let paths = [".local/bin" ".config"]
  for p in $paths {
    let src = ($backups | path join $chosen | path join $p)
    if ($src | path exists) {
      sync-dir $p $src $stamp
    }
  }
}

def main [] {
  main apply -y
}
