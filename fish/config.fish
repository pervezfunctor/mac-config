function has_cmd
    type -q $argv[1]
end

set -x MANROFFOPT "-c"

if has_cmd bat
  set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"
end

if test -f ~/.fish_profile
  source ~/.fish_profile
end

set -gx DOT_DIR $HOME/.mac-config

fish_add_path --global --move \
  $DOT_DIR/scripts \
  $HOME/bin \
  $HOME/.cargo/bin \
  $HOME/.local/bin

eval "$(/opt/homebrew/bin/brew shellenv)"

if status is-interactive
  if has_cmd zoxide
    zoxide init fish | source
  end

  if has_cmd fzf
    fzf --fish | source
  end

  if has_cmd starship
    starship init fish | source
  end

  if has_cmd carapace
    set -gx CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense' # optional
    carapace _carapace | source
  end
end

function fish_greeting
end

alias gs 'git stash'
alias gp 'git push'
alias gb 'git branch'
alias gbc 'git checkout -b'
alias gsl 'git stash list'
alias gst 'git status'
alias gsu 'git status -u'
alias gcan 'git commit --amend --no-edit'
alias gsa 'git stash apply'
alias gfm 'git pull'
alias gcm 'git commit -m'
alias gia 'git add'
alias gco 'git checkout'
function git-tree
    git status --short | awk '{print $2}' | tree --fromfile
end
alias gtree 'git-tree'

if has_cmd eza
  alias ls 'eza --icons --group-directories-first'
  alias ll 'eza --icons --long --group-directories-first'
  alias la 'eza --icons --all --group-directories-first'
  alias lt 'eza --icons --tree'
end

if has_cmd uvx
  function pn
    uvx --with pyzmq --from "marimo[sandbox]" marimo edit --sandbox "$argv"
  end
end

if has_cmd zed
  set -gx VISUAL zed --wait
end

if has_cmd nvim
  set -gx EDITOR nvim
else if has_cmd $VISUAL
  set -gx EDITOR $VISUAL
end
