#!/bin/bash
# One-command Mac setup: zsh, git, tmux, Neovim (LazyVim) and kitty config,
# plus the Homebrew packages they rely on.
#
#   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/bfay1/mac-setup/main/install.sh)"
#
# Safe to re-run: it updates the checkout and relinks anything missing.
# Anything it would replace is moved to ~/.mac-setup-backup-<timestamp>/ first.
#
# Options (environment variables):
#   SKIP_BREW=1                 don't install Homebrew or run `brew bundle`
#   MAC_SETUP_DIR=<path>        where to keep the checkout (default ~/.mac-setup)
#   GIT_NAME=..., GIT_EMAIL=... git identity to use without prompting
#
# Written for the macOS system bash (3.2): no associative arrays or mapfile.
set -euo pipefail

REPO_URL="https://github.com/bfay1/mac-setup.git"
DIR="${MAC_SETUP_DIR:-$HOME/.mac-setup}"
BACKUP_DIR="$HOME/.mac-setup-backup-$(date +%Y%m%d-%H%M%S)"

# Paths under $HOME that become symlinks into $DIR/home/
LINKS=(
  .zshrc
  .zsh_aliases
  .zsh_functions
  .tmux.conf
  .vimrc
  .config/git/ignore
  .config/nvim
  .config/kitty
)

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# Read a line from the terminal even when stdin is a pipe. Prints nothing if
# there is no terminal, so callers fall back to defaults.
ask() {
  local prompt=$1 default=${2:-} reply=""
  if [ -r /dev/tty ] && { : </dev/tty; } 2>/dev/null; then
    printf '%s' "$prompt${default:+ [$default]}: " >/dev/tty
    IFS= read -r reply </dev/tty || reply=""
  fi
  printf '%s' "${reply:-$default}"
}

backup() {  # move $HOME/<rel> into the backup dir, keeping its path
  local rel=$1
  mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
  mv "$HOME/$rel" "$BACKUP_DIR/$rel"
  echo "    backed up ~/$rel"
}

[ "$(uname -s)" = Darwin ] || die "this script is for macOS"

# --- Homebrew (also installs the Xcode Command Line Tools, which bring git) ---
if [ "${SKIP_BREW:-}" != 1 ]; then
  if ! command -v brew >/dev/null 2>&1; then
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
      [ -x "$b" ] && eval "$("$b" shellenv)" && break
    done
  fi
  if ! command -v brew >/dev/null 2>&1; then
    say "Installing Homebrew (it will ask for your password)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
      [ -x "$b" ] && eval "$("$b" shellenv)" && break
    done
    command -v brew >/dev/null 2>&1 || die "Homebrew install did not finish"
  fi
fi

if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install >/dev/null 2>&1 || true
  die "git needs the Xcode Command Line Tools. Finish the installer that just opened, then re-run this command."
fi

# --- Get or update the repo ---
if [ -d "$DIR/.git" ]; then
  say "Updating $DIR"
  git -C "$DIR" pull --ff-only --quiet || warn "could not update $DIR (local changes?); using it as is"
elif [ -e "$DIR" ]; then
  die "$DIR exists and is not a git checkout. Move it away or set MAC_SETUP_DIR."
else
  say "Cloning into $DIR"
  git clone --quiet "$REPO_URL" "$DIR"
fi

# --- Packages ---
if [ "${SKIP_BREW:-}" != 1 ]; then
  say "Installing packages from the Brewfile (this can take a while)"
  brew bundle install --file="$DIR/Brewfile" || warn "some Brewfile entries failed; re-run later with: brew bundle --file=$DIR/Brewfile"
fi

# --- Symlink config files ---
say "Linking config files"
for rel in "${LINKS[@]}"; do
  src="$DIR/home/$rel"
  dst="$HOME/$rel"
  [ -e "$src" ] || { warn "missing in repo: $rel"; continue; }
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    continue  # already linked
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    backup "$rel"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "    linked ~/$rel"
done

# --- Git: include the shared settings, keep identity in ~/.gitconfig ---
say "Configuring git"
touch "$HOME/.gitconfig"
include_path="$DIR/git/shared.gitconfig"
if ! git config --global --get-all include.path 2>/dev/null | grep -qxF "$include_path"; then
  # Put the include first so the user's own settings below it win.
  tmp=$(mktemp)
  printf '[include]\n\tpath = %s\n' "$include_path" | cat - "$HOME/.gitconfig" >"$tmp"
  cat "$tmp" >"$HOME/.gitconfig" && rm -f "$tmp"
fi
name=$(git config --global user.name 2>/dev/null || true)
email=$(git config --global user.email 2>/dev/null || true)
[ -n "$name" ]  || name=${GIT_NAME:-$(ask "Your name for git commits")}
[ -n "$email" ] || email=${GIT_EMAIL:-$(ask "Your email for git commits")}
[ -n "$name" ]  && git config --global user.name "$name"
[ -n "$email" ] && git config --global user.email "$email"
[ -n "$name" ] && [ -n "$email" ] || warn "git name/email not set. Run: git config --global user.name 'You'; git config --global user.email you@example.com"

# --- tmux plugin manager ---
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  say "Installing the tmux plugin manager"
  git clone --quiet --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# --- Default shell ---
if [ "$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')" != /bin/zsh ]; then
  warn "your login shell isn't zsh. Switch with: chsh -s /bin/zsh"
fi

echo
say "Done."
[ -d "$BACKUP_DIR" ] && echo "    Files that were replaced are in $BACKUP_DIR"
cat <<EOF
    Next steps:
      - Open a new terminal (or run: exec zsh)
      - Run nvim once; LazyVim installs its plugins on first start
      - In tmux, press Ctrl-b then I (capital i) to install tmux plugins
      - Put your own shell settings in ~/.zshrc.local or ~/.zshrc.d/*.zsh
      - To update later, re-run the install command
EOF
