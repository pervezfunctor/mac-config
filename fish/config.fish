set -x MANROFFOPT "-c"
set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"

if test -f ~/.fish_profile
  source ~/.fish_profile
end

set -gx DOT_DIR $HOME/.mac-config

fish_add_path --global --move \
    $DOT_DIR \
    $HOME/bin \
    $HOME/.cargo/bin \
    $HOME/.local/bin

eval "$(/opt/homebrew/bin/brew shellenv)"

function has_cmd
    type -q $argv[1]
end

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
    alias ls  'eza --icons --group-directories-first'
end

if has_cmd bat
    alias cat 'bat'
end

if has_cmd uvx
    alias uv-marimo-standalone 'uvx --with pyzmq --from "marimo[sandbox]" marimo edit --sandbox'
end

if has_cmd zed
    set -gx VISUAL zed
else if has_cmd zeditor
    set -gx VISUAL zeditor
else if has_cmd code
    set -gx VISUAL code
else if has_cmd antigravity
    set -gx VISUAL antigravity
end

if has_cmd nvim
    set -gx EDITOR nvim
else if has_cmd micro
    set -gx EDITOR micro
else if has_cmd emacs
    set -gx EDITOR emacs
else if has_cmd vim
    set -gx EDITOR vim
else
    set -gx EDITOR $VISUAL
end
