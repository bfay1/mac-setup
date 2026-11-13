# mac-setup

A terminal setup for macOS: zsh, git, tmux, Neovim ([LazyVim](https://www.lazyvim.org)) and the [kitty](https://sw.kovidgoyal.net/kitty/) terminal, with a gruvbox theme throughout.

## Install

Paste this into Terminal:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/bfay1/mac-setup/main/install.sh)"
```

It will:

1. Install [Homebrew](https://brew.sh) if you don't have it (it asks for your password), then the packages in the [`Brewfile`](Brewfile).
2. Clone this repo to `~/.mac-setup`.
3. Symlink the config files in [`home/`](home) into your home folder. **Anything it would replace is moved to `~/.mac-setup-backup-<timestamp>/` first**, so nothing is lost.
4. Add the shared git settings to your `~/.gitconfig` and ask for your git name and email if they aren't set yet.
5. Install the tmux plugin manager.

It's safe to run again. Re-running is also how you update.

Options, set before the command (e.g. `SKIP_BREW=1 /bin/bash -c "$(curl ...)"`):

| Variable | Effect |
|---|---|
| `SKIP_BREW=1` | Don't install Homebrew or any packages |
| `MAC_SETUP_DIR=path` | Keep the checkout somewhere other than `~/.mac-setup` |
| `GIT_NAME`, `GIT_EMAIL` | Set your git identity without being asked |

## After installing

- Open a new terminal window, or run `exec zsh`.
- Open kitty, which uses Hack Nerd Font and gruvbox.
- Run `nvim` once. LazyVim downloads its plugins on first start.
- In tmux, press `Ctrl-b` then `I` (capital i) to install the tmux plugins.

## What's included

| File | What it does |
|---|---|
| `.zshrc` | Homebrew on the PATH, big shared history, loads the files below |
| `.zsh_aliases` | `ll`, `la`, `vim`→`nvim`, `lg`→lazygit, `ez`/`sz` to edit/reload zsh, `alert` notification after long commands |
| `.zsh_functions` | `lls` (ls with headers), `dict` (search the system dictionary) |
| `git/shared.gitconfig` | Short aliases (`st`, `co`, `br`…), `main` as default branch, auto-upstream on push, rerere, rebase autostash, git-lfs |
| `.tmux.conf` | Mouse on, `\|` and `-` to split, `Ctrl-h/j/k/l` to move between tmux panes *and* nvim splits, gruvbox status bar, session save/restore |
| `.config/nvim` | LazyVim with Python, TypeScript, Tailwind, JSON and C/C++ support, gruvbox, tmux navigation, Claude Code integration (`<leader>a…`) |
| `.config/kitty` | Hack Nerd Font, gruvbox colors, copy on select |
| `.config/git/ignore` | Global gitignore (`.DS_Store`, editor swap files…) |

## Make it yours

Your own settings go in files this repo doesn't touch, so updates never overwrite them:

- **Shell:** `~/.zshrc.local`, or any `~/.zshrc.d/*.zsh` file
- **Git:** `~/.gitconfig` (your settings there override the shared ones)

To change the shared files themselves, edit them in `~/.mac-setup/home/`. They're symlinked, so changes apply right away. If you change them, `git pull` (and re-running the installer) may stop with a conflict, so fork the repo first if you plan to customize a lot.

## Uninstall

```sh
cd ~ && for f in .zshrc .zsh_aliases .zsh_functions .tmux.conf .vimrc .config/git/ignore .config/nvim .config/kitty; do
  [ -L "$f" ] && rm "$f"
done
```

Then remove the `[include]` of `.mac-setup/git/shared.gitconfig` from the top of `~/.gitconfig`, copy back anything you want from `~/.mac-setup-backup-*`, and delete `~/.mac-setup`.
