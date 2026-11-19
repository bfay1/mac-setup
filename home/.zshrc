# Homebrew (Apple Silicon installs to /opt/homebrew, Intel to /usr/local)
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

export PATH="$HOME/.local/bin:$PATH"
# Prefer node@22 over the latest node, if it is installed (brew install node@22)
[ -d "$HOMEBREW_PREFIX/opt/node@22/bin" ] && export PATH="$HOMEBREW_PREFIX/opt/node@22/bin:$PATH"
export EDITOR=nvim

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# History: keep (practically) everything, with timestamps, shared across shells
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=1000000000
export SAVEHIST=1000000000
setopt EXTENDED_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS

# All standalone shell functions live here.
[ -f "$HOME/.zsh_functions" ] && source "$HOME/.zsh_functions"

# nvm, if installed
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Docker runs inside colima (installed by the Brewfile as a login service)
export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"

# Drop-in config: put your own *.zsh files in ~/.zshrc.d/ (not part of this
# repo). Sourced before the aliases: zsh expands aliases inside a function
# body when it parses the definition.
for _zshrc_d in "$HOME"/.zshrc.d/*.zsh(N); do source "$_zshrc_d"; done
unset _zshrc_d

# All aliases live here. Sourced last so PATH is complete: the `alert` alias
# picks its implementation with `command -v`.
[ -f "$HOME/.zsh_aliases" ] && source "$HOME/.zsh_aliases"

# Machine-local shell config (not part of this repo)
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
