#!/usr/bin/env nu

use std/log

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

export def stow [package: string, --root: string] {
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
