#!/bin/bash
# 词条表 · 英文 · install.sh
# ⚠️ 值里的 % 一律写 %%（整串走 printf 格式串）。

# ---- 长块：help / dry-run 清单 ----------------------------------
# 这两块以前是「打印脚本自己的头部注释」（sed -n '3,13p' $0）。
# 双语之后那条路走不通了，正文搬到这里 —— 一个语言一份、单一同源，-h 和文档不会漂。
blk_install_help() {
  cat <<'EOF'
hekouwang-terminal-kit — one-shot install

Usage:
  ./install.sh              install everything
  ./install.sh --dry-run    list every file and setting it would touch, write nothing
  ./install.sh --lang zh    run in Chinese (remembered for later runs)
  CN=1 ./install.sh         use China mirrors (Tsinghua TUNA) end to end

Idempotent: safe to re-run, anything already installed is skipped.
Your ~/.zshrc is backed up to ~/.zshrc.bak.<timestamp> before it gets replaced.
Already using your own .zshrc? Run ./migrate.sh first — it moves your aliases /
PATH / env vars into ~/.zshrc.local instead of overwriting them.
Changed your mind: ./uninstall.sh (restores .zshrc, resets the GUI settings)
EOF
}

M_INSTALL_DRY_HEAD="═══ DRY-RUN — nothing below is actually executed ═══"
M_INSTALL_DRY_TAIL="Drop --dry-run to run it for real."

blk_install_dryrun() {
  cat <<EOF

Will install (skipped if already there)
  Homebrew (if missing) · iTerm2
  Fonts: Maple Mono NF CN (SIL OFL, free for commercial use) + Symbols Nerd Font
  CLI: starship eza bat fzf fd zoxide ripgrep atuin fnm tmux git-delta
       zsh-autosuggestions zsh-syntax-highlighting
  oh-my-zsh (if missing) · iTerm2 Shell Integration

Will write these files
  ~/.zshrc                                    <- backed up to ~/.zshrc.bak.<timestamp> first
  ~/.zshrc.local                              <- created only if absent, never overwritten
  ~/.config/starship.toml
  ~/.config/hekouwang-terminal/current/        <- ecosystem colors (colors.sh/delta/tmux)
  ~/Library/Application Support/iTerm2/DynamicProfiles/hekouwang-active-theme.json
  ~/.config/bat/themes/hekouwang-*.tmTheme    <- plus one bat cache --build
  ~/.config/ghostty/{config,themes/hekouwang-*}   <- only if Ghostty is installed; old config backed up
  ~/.warp/themes/*.yaml                        <- only if Warp is installed
  ~/.vscode|.cursor/extensions/hekouwang-terminal-themes-*/  <- only if that editor is installed

Will append one line to config you already own (each is backed up first)
  ~/.gitconfig    adds [include] path=.../delta.gitconfig   (git diff colors)
  ~/.tmux.conf    adds source-file .../tmux.conf            (tmux colors)

Will write these system settings (defaults)
  com.googlecode.iterm2: Minimal theme, no scrollbar, default profile,
                         Shift+Enter for newline, status bar position, toolbelt
  global: ApplePressAndHoldEnabled=false (key repeat on hold — vim users need it)

Will not touch
  your ~/.ssh/, an existing ~/.zshrc.local, other Homebrew packages you installed

Default theme: $DEFAULT_THEME
How to undo: ./uninstall.sh (has --dry-run too)
EOF
}

# ---- 正常安装流程 ----------------------------------------------
M_INSTALL_CN_MIRROR="China mirrors enabled (Tsinghua TUNA) — Homebrew will use domestic sources..."
M_INSTALL_BREW="Installing Homebrew..."
M_INSTALL_ITERM_FONTS="Installing iTerm2 + fonts (Maple Mono NF CN / Symbols Nerd Font / JetBrains Mono fallback)..."
M_INSTALL_CASK_SKIP_MANUAL="%s already installed (installed by hand, not tracked by brew), skipped"
M_INSTALL_CASK_FAIL="⚠ %s failed to install (on a China network try CN=1 ./install.sh)"
M_INSTALL_CLI="Installing the CLI set (one by one — a single failure will not abort the run)..."
M_INSTALL_PKG_FAIL="⚠ %s failed to install, skipping it for now"
M_INSTALL_PKG_FAILED_SUM="⚠ These did not install, run brew install for them later:%s"
M_INSTALL_OMZ="Installing oh-my-zsh..."
M_INSTALL_CONFIG="Deploying config files..."
M_INSTALL_GHOSTTY_BAK="Backed up your Ghostty config → ~/.config/ghostty/config.bak.*"
M_INSTALL_GHOSTTY_OK="✓ Ghostty themes and config deployed (press Cmd+Shift+, in Ghostty to reload)"
M_INSTALL_WARP_OK="✓ Warp themes deployed (pick the matching name in Warp → Settings → Appearance)"
M_INSTALL_BAT="Installing bat syntax themes (all of them, once)..."
M_INSTALL_BAT_OK="✓ %s bat themes installed and cached"
M_INSTALL_BAT_CACHE_FAIL="⚠ bat cache --build failed (cat highlighting falls back to default colors, nothing else affected)"
M_INSTALL_BAT_MISSING="⚠ bat is not installed, skipping its themes"
M_INSTALL_THEME="Deploying theme + ecosystem colors (default: %s)..."
M_INSTALL_GIT_SKIP="git diff colors already wired up, skipped"
M_INSTALL_GIT_OK="✓ git diff colors wired into ~/.gitconfig (delta)"
M_INSTALL_TMUX_SKIP="tmux colors already wired up, skipped"
M_INSTALL_TMUX_OK="✓ tmux colors wired into ~/.tmux.conf"
M_INSTALL_TMUX_MARK="# hekouwang-terminal-kit colors (content updates itself when you switch themes)"
M_INSTALL_VSC_OK="✓ Editor theme installed → %s (restart the editor, then pick it in the theme list)"
M_INSTALL_ZSHRC_BAK="Backed up your ~/.zshrc → %s"
M_INSTALL_ZSHRC_HINT_MIGRATE="💡 Your old .zshrc has alias/export lines — to keep them, hit Ctrl+C and run ./migrate.sh instead"
M_INSTALL_SI="Installing iTerm2 Shell Integration (imgcat / it2copy and friends)..."
M_INSTALL_SI_OK="✓ Shell Integration installed"
M_INSTALL_SI_FAIL="⚠ Shell Integration failed to install (no imgcat/it2copy, nothing else affected)"
M_INSTALL_DEFAULTS="System setting: key repeat on press-and-hold (vim users need this)..."
M_INSTALL_GUI="Writing the iTerm2 GUI settings (Minimal theme / default profile / Shift+Enter newline)..."
M_INSTALL_DOCTOR="Running the environment check..."
M_INSTALL_DONE="✅ All done!"
M_INSTALL_TAIL_LOCAL="Put private config (SSH aliases, proxies) in ~/.zshrc.local"
M_INSTALL_TAIL_OPEN="Open iTerm2 and it is live."
M_INSTALL_TAIL_THEME="Switch theme (bat/fzf/git diff follow along): ./theme.sh"
M_INSTALL_TAIL_AUTO="Follow the system light/dark switch: ./theme.sh --auto"
M_INSTALL_TAIL_UNDO="Changed your mind: ./uninstall.sh (supports --dry-run)"
M_INSTALL_TAIL_CN="💡 On a China network, if it dies on portable-ruby / download errors, use: CN=1 ./install.sh"
M_INSTALL_GUI_FAIL="! GUI setup did not finish (everything else is installed). Run it later: ./setup-gui.sh"
