---
name: hekouwang-iterm2-skill
version: 2.2.0
description: >
  macOS terminal environment as code (iTerm2 first; the same palette also drives Ghostty and Warp).
  iTerm2 (Minimal theme + Dynamic Profile + blur + Triggers) + oh-my-zsh + Starship + the modern CLI
  set (eza/bat/fzf/fd/zoxide/ripgrep/atuin/delta). The core idea is **one palette drives the whole
  tool chain**: a single PALETTES source generates the colors for iTerm2 / Ghostty / Warp / **the
  built-in macOS Terminal** / bat / fzf / eza / git diff (delta) / tmux / VS Code, so one command
  reskins four terminals and every tool at once. Fonts are detected through a priority table against
  what is actually installed (including commercial fonts you bought, such as Operator Mono); this kit
  ships no font files. Seven themes (3 community + 4 brand, two of them light), default v2-mihei.
  Runs in English by default and switches to Chinese with --lang zh or HKW_LANG=zh.
  Use it when you need to: (1) restore the whole terminal setup on a brand-new Mac; (2) adopt an
  existing .zshrc (migrate rather than overwrite); (3) explain or tune a ~/.zshrc; (4) debug zsh
  plugin conflicts or slow startup (timing + zprof naming names); (5) change terminal colors, switch
  themes, add a theme; (6) make bat/fzf/eza/git diff match the terminal; (7) follow the system
  light/dark switch; (8) tune terminal blur/transparency; (9) sync themes and fonts to Ghostty /
  Warp / the built-in Terminal; (10) uninstall and restore everything; (11) update to the latest
  version or sync across machines; (12) export the open-source build or package the paid theme pack.
  Triggers: iTerm2 / Ghostty / Ghostty colors / Warp theme / terminal colors / terminal theme /
  theme.sh / terminal blur / zshrc tuning / zshrc migration / slow shell startup / starship prompt /
  bat colors / git diff colors / follow system appearance / Terminal.app colors / Operator Mono /
  change terminal font / uninstall terminal config / v2-mihei / v1-keji / v2-mibai / v3-caijing-bai.
  中文触发词：iTerm2 配色 / 终端配色 / 终端换肤 / 终端毛玻璃 / zshrc 优化 / zshrc 迁移 /
  终端启动慢 / starship 提示符 / bat 配色 / git diff 配色 / 跟随系统深浅色 / 自带终端配色 /
  换终端字体 / 卸载终端配置。
---

# hekouwang-terminal-kit — a terminal, configured as code (iTerm2 first, every terminal in sync)

> **English** · [简体中文](SKILL.zh-CN.md)

A macOS terminal environment kept as code:

- **Window**: Minimal theme — no title bar, no border, no scrollbar; one canvas plus blur
- **Colors**: seven themes generated from one `PALETTES` source, default **v2-mihei** (`#19191a` warm dark + the brand's warm orange cursor)
- **Across terminals**: the same palette outputs iTerm2 / Ghostty / Warp / the built-in macOS Terminal
- **Across tools**: bat / fzf / eza / delta / tmux / VS Code all match
- **Fonts**: detected against what is installed, in the priority order of `config/font.conf` (commercial fonts you own included). **No font files are distributed**
- **Automation**: Triggers ship with the profile (errors red / warnings yellow / success green / password manager), and their colors follow the theme
- **Built for AI CLIs**: `Shift+Enter` inserts a newline instead of submitting (multi-line prompts in Claude Code)
- **Language**: everything runs in English by default; `--lang zh` (or `HKW_LANG=zh`) switches to Chinese and is remembered

---

## 1. Tiers (read this first when asked "can this be open-sourced / which tier is this in")

**The line is drawn by capability, not by file**: open source = a properly configured iTerm2; paid = that same palette walking out of iTerm2.

**Free (in the open-source repo)**: the complete iTerm2 theme (3 community palettes + blur + Triggers + Shift+Enter), the CLI set, doctor / migrate / uninstall, and the install / theme / check scripts themselves.

⛔ **The implementation of paid features lives in the paid pack too** (tightened 2026-07-23): it used to be "all scripts open, only the config content gated", which left the full multi-terminal implementation and the per-app format notes sitting in the free repo — anyone could add three generators and reproduce the paid tier. Now `import.sh` / `workspace.sh` / `palette.sh` are ~22-line stubs in the free repo (an ad slot plus `exec` into the paid engine), and `theme.sh` handles iTerm2 only, with the other half in `config/themes/_apply_pro.sh`.

**Paid**: 4 brand themes (2 of them light) + multi-terminal sync + whole-ecosystem color + the font priority table + follow-the-system light/dark + the cheat sheet + a year of updates and support.

| Free (open-source repo) | Paid (paid pack) |
|---|---|
| `_generate.py`, the complete iTerm2 theme | `generators/pro.py`, multi-terminal + ecosystem generator |
| `palettes/community.py`, 3 community palettes | `palettes/brand.py`, 4 brand palettes |
| `config/keymap.json`, global key map | `config/font.conf`, font priority table |
| `theme.sh`, switch iTerm2 themes / gallery / preview | `_apply_pro.sh`, Ghostty · Warp · Terminal.app · ecosystem |
| `import.sh` · `workspace.sh` · `palette.sh` ad slots | `_import.py` · `_workspace_pro.sh` · `_derive.py` engines |
| — | `references/terminals.md`, per-app formats and pitfalls |

When the paid parts are absent, the generator still emits **the complete iTerm2 theme** and prints "the following belong to the paid pack and are not generated" — no errors, no half-built state.

- `./release.sh --oss <dir>` exports the open-source build (strips paid files → runs the generator to verify → scans for leaks)
- `./release.sh --pack <zip>` builds the paid pack
- `./release.sh --check` self-checks the scripts and scans the working tree **and git history** for real IPs / home paths / secrets

⚠️ **Never just flip the master repo to public**: `--check` will show you which commits in its history contain real server details. The correct move is `--oss` into a clean copy and `git init` in a **new** repo.

---

## 2. Layout

```
hekouwang-iterm2-skill/
├── install.sh      one-shot install (--dry-run previews every change first)
├── migrate.sh      ⭐ adopt an existing .zshrc (move it into .zshrc.local, do not overwrite)
├── uninstall.sh    ⭐ restore everything (--dry-run; restores from backup, defaults delete for GUI)
├── theme.sh        switch theme (bat/fzf/eza/delta/tmux/four terminals all at once); --auto follows the system
│                   ⭐ --preview <name> full single-theme preview / --gallery all of them (for screenshots)
├── doctor.sh       self-check (read-only); --fix asks item by item; --profile names the slow plugins
├── update.sh       update (--check only shows what changed)
├── sync.sh         drift check / --pull realign / --export package for a second machine
├── workspace.sh    ⭐paid project workspaces: cd into a project, the tab recolors and prints its name
├── palette.sh      ⭐paid derive a whole theme from one brand color
├── setup-gui.sh    GUI automation (Minimal theme / default profile / key map)
├── release.sh      ⭐ tiered export: --oss / --pack / --check
├── lib/
│   ├── i18n.sh                 ⭐ runtime language layer for the shell scripts
│   ├── i18n.py                 ⭐ the same for the Python generators
│   └── i18n/{en,zh}/*.sh       message catalogs, one file per script
├── config/
│   ├── zshrc.template[.zh]     .zshrc template (sources the ecosystem colors, hard-codes no hex)
│   ├── zshrc.local.example[.zh] private config template (SSH aliases / proxies)
│   ├── keymap.json             global key map (Shift+Enter and friends)
│   ├── font.conf               ⭐paid font priority table
│   ├── starship.toml           Starship (uses ANSI color names, so it follows the theme)
│   ├── ghostty.config          Ghostty main config template
│   └── themes/
│       ├── _generate.py        ⭐ single source of truth: palette → complete iTerm2 theme
│       ├── _preview.py         ⭐ gallery / full preview renderer (true color, independent of the current theme)
│       ├── names.json          ⭐ theme display names per language (generated)
│       ├── generators/pro.py   ⭐paid multi-terminal + ecosystem generator
│       ├── palettes/           palettes (community.py free / brand.py paid)
│       │   └── _derive.py      ⭐paid palette deriver (brand color → whole theme)
│       ├── <theme>.json        iTerm2 Dynamic Profile
│       ├── ghostty/ warp/      ⭐paid
│       └── ecosystem/          ⭐paid colors.sh / bat / delta / tmux / Terminal.app / VS Code
├── docs/速查卡.html|.pdf        ⭐paid A4, printable
│   └── 录制手册.md · 录制沙盒.sh  internal: content production, shipped in neither tier
└── references/
    ├── terminals.md            ⭐ per-terminal implementation notes and pitfalls (fonts / Ghostty / Warp / Terminal.app)
    ├── zshrc-explained.md      .zshrc block by block + known issues
    ├── iterm2-gui-settings.md  GUI checklist + advanced features (Triggers/Hotkey/tmux -CC)
    └── shortcuts.md            keyboard shortcuts
```

---

## 3. How it is used

### 3.1 Restore everything on a brand-new Mac

```bash
./install.sh --dry-run   # see which files and system settings it would touch
./install.sh             # on a China network: CN=1 ./install.sh
```

Installs in this order: iTerm2 + fonts + the CLI set → theme and ecosystem colors → bat themes → wire into git/tmux → editor theme → `.zshrc` → Shell Integration → GUI settings → `doctor.sh`. About 3 minutes.

On the first interactive run it asks once for a language and remembers the answer in `~/.config/hekouwang-terminal/lang`. Non-interactive runs never block on that question — they use English.

### 3.2 The user already has their own .zshrc

**Do not run `install.sh`** (it overwrites). Run `./migrate.sh` for the report first, then `--apply`.

Decisions are made **per paragraph**, not per line — per line would cut `for…done` and continued commands in half and produce a file that does not parse. It runs `zsh -n` before writing, and after writing it **actually starts a shell**; if that fails it rolls back automatically (both `~/.zshrc` and `~/.zshrc.local`, each backed up first). If the existing `.zshrc` overlaps the template by ≥60% it refuses to migrate at all — that means they are already on this template and should run `install.sh`.

### 3.3 Explain or tune a machine's .zshrc

Read `references/zshrc-explained.md` for the block-by-block explanation; pay attention to the "known issues" list at the end (two Node managers loaded, double loading, plugin order). Or just run `./doctor.sh`.

### 3.4 Slow terminal startup

```bash
./doctor.sh --profile
```

Section 7 runs `zsh -i -c exit` seven times and takes the median (<300ms fast / <600ms noticeably slow / above that, laggy). `--profile` uses a temporary `ZDOTDIR` to load `zmodload zsh/zprof` and then sources the user's real `.zshrc`, naming the top 8 time sinks. The usual culprits are `compinit` / `compdump`.

### 3.5 Switch, add or change themes

- `./theme.sh` shows the gallery (each theme with a true-color 16-swatch strip) → `./theme.sh <name>`: **one command reskins four terminals and the whole tool chain**
- `./theme.sh --preview <name>` renders a whole fake terminal: prompt / eza file listing / git diff / syntax highlighting / ERROR·WARN coloring in one image; `--gallery` renders every theme in turn. **This is the tool used to shoot the theme screenshots for the paid repo** — it paints in 24-bit true color regardless of which theme the current terminal uses, so screenshots are identical anywhere and you never have to reskin seven times just to capture them. The renderer is `config/themes/_preview.py`, and it reads colors from the **generated `.json`** rather than the palette `.py`, so previews work in the open-source build with no brand.py.
- Switching prints a **grouped receipt** (terminal / tool chain), not one flat wall of lines. The right-aligned header line comes from `_preview.py --banner` — bash's `printf %-Ns` pads by bytes, so a CJK title always ends up crooked.
- Follow the system light/dark switch: `./theme.sh --auto [dark light]` / `--auto off` (a launchd `WatchPaths` agent watches `~/Library/Preferences/.GlobalPreferences.plist`, and `RunAtLoad` makes sure login gets it right too)
- **To change colors, change `palettes/*.py` and re-run `_generate.py`.** Never hand-edit generated JSON/YAML/tmTheme
- To add your own theme: create `palettes/mine.py` with `PALETTES = {...}` and it is discovered automatically
- Display names are bilingual: generated artifacts always carry the **English** name, and the Chinese name is injected at deploy time from `config/themes/names.json`. That is why two languages share one set of artifacts instead of two sets that drift apart.

**How a theme is derived from brand tokens** (all four brand themes came from this; details in the `brand.py` comments):

1. **Take the hue from the brand token, never copy a community theme** — hue is identity
2. **Solve lightness backwards from WCAG contrast**: normal → 5.5:1, bright → 9:1. ⚠️ Brand colors **cannot go straight into ANSI slots** (on a dark background they usually land at 3.7–4.3:1, which turns to mush as body text). **Light themes run the other way**: higher contrast means darker, so on a light theme bright is *darker* than normal
3. **Saturation follows each version's character**: V2 editorial 42% (ink), V1 tech 89% (neon is the identity), V3 finance 72% (Material level)
4. **normal and bright must differ** — `ls`, `git diff` and syntax highlighting all rely on that pair to express emphasis

### 3.6 Make bat / fzf / eza / git diff match the terminal

`_generate.py` + `pro.py` generate `ecosystem/<theme>/` for every theme → `theme.sh` copies it into `~/.config/hekouwang-terminal/current/` → `.zshrc` sources that one fixed path. Switching themes never touches `.zshrc`.

- bat themes are installed **all at once during `install.sh`, with a single `bat cache --build`**. ⚠️ bat indexes themes by the `name` field inside the file, not the filename, and **when it cannot find a theme it silently falls back to its default colors without an error** — hence the self-healing step in `theme.sh` and the check in `doctor.sh` that asks whether **the current theme specifically** is present (asking "is there any hekouwang-*" cannot tell the two cases apart)
- delta is wired in through `[include]` in `~/.gitconfig`; tmux through `source-file` in `~/.tmux.conf`. Both are **the user's own files**, so install backs them up and adds exactly one line, and uninstall can remove exactly that line
- **starship is not generated**: its styles use ANSI color names, so it follows the palette by nature. Generating hex would pin it down instead

### 3.7 Multiple terminals / fonts

**Usage is here; the implementation notes and pitfalls are all in [`references/terminals.md`](references/terminals.md)** (read that before touching this area):

- On switch, `theme.sh` **refreshes the theme file itself**, not just the `theme =` line (changing only the line leaves Ghostty quietly using the old colors — a real bug fixed in 2.0)
- Fonts are detected in the priority order of `config/font.conf`. **iTerm2 wants the PostScript name; Ghostty wants the family name plus font-style** — the two apps disagree
- The built-in macOS Terminal **has only one font field** and no Symbols Nerd Font fallback layer → `APPLE_TERMINAL_FONT=icons|match` picks which you keep (icons, or one consistent font)
- ⚠️ **Neither Ghostty nor Terminal.app applies changes on save**, and **both overwrite settings from memory when they quit** — so verify against the running app, not the config file

### 3.8 Three things built for AI workflows (all paid)

All three come from the same scene: **four tabs running four agents at once**.

- **Project workspaces** `./workspace.sh add <path>` — cd into a project and the tab recolors and prints the project name. The tab color is taken from the current palette, so it always stays in the same family, and `theme.sh` rebuilds them after a reskin. Implementation and pitfalls are in the header of the paid `config/themes/_workspace_pro.sh`. ⚠️ It depends on Shell Integration (Automatic Profile Switching reports the path through it) plus the `EnableAutomaticProfileSwitching` master switch; `workspace.sh` checks both for the user. `theme.sh` calls `workspace.sh --rebuild` after switching, and the registry at `~/.config/hekouwang-terminal/workspaces.conf` is the single source of truth. ⚠️ Deliberately not built on Triggers: that route has a fixed layout, cannot get rid of "A trigger fired…", and cannot report the duration or the command name. Foreground detection costs an osascript call (~50ms), but only commands that already ran long enough get that far, so everyday typing pays nothing.
- **Palette deriver** `./palette.sh --from "#hex" --name X [--light] [--preset editorial|tech|data]` — the derivation method from section 3.5, turned into a tool. What is sold is therefore not "4 themes" but **unlimited themes plus a method**.

> ⛔ **Do not try the "speed up startup" direction again**: it was tried and reverted on 2026-07-22. The "compinit is 86%" that zprof reports is inflated by zprof's own instrumentation; the real baseline is only ~175ms. The correct fix (own `compinit -C` plus stubbing out the one oh-my-zsh does) measured 175→168ms, which is inside the noise. The wrong fix (running compinit yourself without stopping oh-my-zsh's) runs compinit twice and is **twice as slow** (189→400ms).

### 3.9 Uninstall / restore

`./uninstall.sh --dry-run` for the list, then `./uninstall.sh`. Four rules (read before changing it):

1. Only removes what this kit installed. Homebrew itself, oh-my-zsh, `~/.zshrc.local` and the user's own git/ssh config are untouched
2. `~/.zshrc` is **restored** from the `.bak`, not deleted; if no backup exists it says so instead of pretending it worked
3. GUI settings go back to **factory defaults** via `defaults delete`, not to "the default we think is right"
4. `Default Bookmark Guid` is only removed while it still points at this kit's Guid; only the two keys we added are removed from `GlobalKeyMap`

⚠️ Both `uninstall.sh` and `setup-gui.sh` **refuse to quit the terminal they are running inside** (that would close the window running the script and leave the user halfway). The test uses `$ITERM_SESSION_ID` / `$TERM_PROGRAM`, not `pgrep` (which cannot see GUI processes in a sandbox).

### 3.10 Language

- Everything defaults to English. `--lang zh` or `HKW_LANG=zh` switches, and `install.sh` persists the choice to `~/.config/hekouwang-terminal/lang`
- Message catalogs live in `lib/i18n/{en,zh}/<script>.sh`, one file per script, loaded **en first and then the current language on top** — so a missing translation falls back to English rather than printing an empty line
- ⚠️ macOS ships bash 3.2, which has **no associative arrays**. The catalogs are plain variables plus `${!name}` indirection on purpose. Do not "tidy them up" into `declare -A`; that only runs on machines with bash 5
- ⚠️ Every message goes through `printf --`. Without the `--`, any message starting with `-` (`"--check mode, nothing was touched"`) makes printf treat it as an option and print nothing
- Help text lives in the catalogs, not in the script header comments. The old `sed -n '3,13p' "$0"` trick cannot be bilingual and would drift

---

## 4. Principles

1. **Config as code**: profiles are managed as Dynamic Profile JSON, GUI items are written with `defaults write`, nothing is clicked by hand
2. **One palette for the whole chain**: several hand-maintained palettes always drift (a hand-maintained Warp theme was measured with 8 of 16 slots wrong)
3. **Many themes, one Guid**: switching theme swaps the active file without changing the Guid, so the default-profile binding never breaks
4. **Freely licensed fonts only**: the default is Maple Mono NF CN (SIL OFL). ⚠️ 1.x used to pull Operator Mono (an H&Co commercial font) from a third-party repo — grey for personal use, **plain infringement when shipped with a product**. Removed in 2.0
5. **Load order**: omz → plugins → starship → ecosystem colors → CLI set → **syntax-highlighting second to last** → iTerm2 integration last. ⚠️ Ecosystem colors must come **before** the CLI set (the `HEKOUWANG_SOLO_NF` it exports decides whether eza gets icons)
6. **Adapt to the brew prefix**: detect with `brew --prefix`, works on both Apple Silicon and Intel
7. **Privacy line**: SSH aliases, proxy addresses and other private content never go into git — they live in `~/.zshrc.local`
8. **One Node manager only**: fnm is recommended; never mix nvm / fnm / brew node
9. **Never `killall cfprefsd` after writing defaults**: it discards writes that have not been flushed yet
10. **Anything installable must be uninstallable**: every write has a matching restore path, and each can be previewed with `--dry-run`
11. ⛔ **Never follow `$var` directly with a full-width character** (`"$FOO）"`): it gets absorbed into the variable name, raises unbound variable and **kills the whole script on the spot**. Write `${FOO}`. This was hit three times while building 2.0 and is now a hard check in `release.sh --check`
