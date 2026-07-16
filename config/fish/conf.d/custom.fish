set -gx DOT_DIR $HOME/.mac-config
fish_add_path --global $DOT_DIR $HOME/.cargo/bin $HOME/.local/bin $HOME/bin /opt/homebrew/bin /usr/local/bin

set -q XDG_CONFIG_HOME; or set -gx XDG_CONFIG_HOME $HOME/.config
set -q XDG_DATA_HOME; or set -gx XDG_DATA_HOME $HOME/.local/share
set -q XDG_CACHE_HOME; or set -gx XDG_CACHE_HOME $HOME/.cache

function has_cmd
  type -q $argv[1]
end

if ! status is-interactive
  return
end

if has_cmd brew
  eval (brew shellenv)
end

alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'

alias gst 'git status'
alias gsu 'git status -u'
alias gsh 'git stash'
alias gia 'git add'
alias gcm 'git commit -m'
alias gp 'git push'
alias gl 'git log --oneline -20'
alias gd 'git diff'
alias gb 'git branch'
alias gco 'git checkout'
alias gpl 'git pull'
alias gbc 'git checkout -b'
alias gsl 'git stash list'
alias gsa 'git stash apply'
alias gcan 'git commit --amend --no-edit'

function gtree
  git status --short | awk '{print $2}' | tree --fromfile
end

if has_cmd carapace
  set -gx CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'
  carapace _carapace fish | source
end

if has_cmd starship
  starship init fish | source
end

if has_cmd eza
  alias l 'eza --icons --group-directories-first'
  alias ll 'eza -l --icons --group-directories-first'
  alias la 'eza -la --icons --group-directories-first'
  alias lt 'eza --tree --icons --group-directories-first'
end

if has_cmd zoxide
  zoxide init fish | source
end

if has_cmd fzf
  fzf --fish | source
end

if has_cmd uvx
  function pn
    uvx --with pyzmq --from "marimo[sandbox]" marimo edit --sandbox $argv
  end
end

if not set -q EDITOR
  if has_cmd code
    set -gx EDITOR 'code --wait'
  else if has_cmd nvim
    set -gx EDITOR nvim
  end
end

if not set -q VISUAL
  if has_cmd code
    set -gx VISUAL 'code --wait'
  else if has_cmd nvim
    set -gx VISUAL nvim
  end
end
