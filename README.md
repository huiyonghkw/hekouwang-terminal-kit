<h1 align="center">hekouwang-terminal-kit</h1>

<p align="center">
  <b>The terminal deserves one more round of setup in the AI era.</b><br>
  The free build makes your iTerm2 look right.<br>
  The paid build makes that same palette walk out of iTerm2 — four terminals and the whole command-line tool chain change together.
</p>

<p align="center">
  <a href="README.md">English</a> · <a href="README.zh-CN.md">简体中文</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/paid%20tier-4%20terminals%3A%20iTerm2%20%C2%B7%20Ghostty%20%C2%B7%20Warp%20%C2%B7%20Terminal.app-6a45e0">
  <img src="https://img.shields.io/badge/paid%20tier-one%20palette%3A%20terminal%2Bbat%2Bfzf%2Beza%2Bgit%20diff%2Btmux%2BVS%20Code-6a45e0">
  <img src="https://img.shields.io/badge/open%20source-a%20properly%20configured%20iTerm2%20%C2%B7%20MIT-06a88c">
  <img src="https://img.shields.io/badge/license-MIT-00d4aa">
</p>

<p align="center">
  <img src="docs/images/01-cover.en.png" width="88%" alt="Turning a dark, ugly terminal into a workbench that fits your hand">
</p>

> Everything you run — installer, theme switcher, doctor, uninstaller — speaks English by
> default; `--lang zh` switches it (and everything after) to Chinese.

---

## Same machine, same command — the only difference is the tier

<table>
<tr>
<th width="50%">Open source (free)</th>
<th width="50%">Paid</th>
</tr>
<tr>
<td><img src="docs/images/cmp-iterm2-free.png" alt="Free: eza / bat / git diff each speak their own color language"></td>
<td><img src="docs/images/cmp-iterm2-paid.png" alt="Paid: all four in one color family"></td>
</tr>
</table>

Not one command changed: `eza` lists the directory, `cat` reads the code, `git diff` shows the changes.

The left side is **not "ugly colors"** — Monokai is a classic, delta's red/green is factory default.
The problem is that **three tools each speak their own dialect**, and none match the terminal background.
On the right, all four are **generated from the same palette**, so they are family.

I learned this the hard way: a hand-maintained Warp theme whose comment said "identical to iTerm2" had **8 of 16 ANSI slots wrong**.

iTerm2 only → the free build is enough (looks right + AI details + safe uninstall).
Also using Ghostty / Warp / Terminal.app, or wanting `cat`/`ls`/`git diff` to match the terminal → the paid tier is "one palette walks out".

---

## 1. What you may be going through

Since CLI agents like Claude Code showed up, the time I spend in the terminal roughly doubled.

It used to be a place you typed two commands and left. Now it is the main surface where I work with AI: four tabs, four jobs, output scrolling by, and I need to see at a glance which one errored, which finished, which is still spinning.

Then I noticed my five-year-old terminal setup was built for "typing commands", not for "watching AI work":

- Four tabs look identical — I cannot tell which job is which
- Agents dump hundreds of log lines; `ERROR` and normal output share one color
- A multi-line prompt for the AI — Enter submits instead of newline
- Daylight by the window, or a projector in a meeting — a dark background is unreadable
- Once it finally feels right, a new Mac means starting the clicks over

This kit is aimed at those gaps. **Whatever I can do with AI, I run first, then show you** — this is the terminal I use every day, not a demo.

## 2. How this differs from the dotfiles repos out there

1. **One palette, four terminals** 〔paid〕. Most theme switches only recolor one app. Here `./theme.sh` reskins iTerm2, Ghostty, Warp, and **macOS Terminal**, plus `cat` (bat), `Ctrl+T` (fzf), `ls` (eza), `git diff` (delta), tmux, and VS Code — because their colors are **generated from one palette**, not hand-copied.
2. **Details for AI workflows** 〔open source〕. `Shift+Enter` newline without submit; `ERROR/WARN/SUCCESS` auto-color; **Cmd-click** `path:line` / Git SHA / `localhost:port`; `Password:` prompts open the password manager; follow system light/dark 〔paid〕.
3. **Safe to install, safe to remove** 〔open source〕. `install.sh --dry-run` lists every file and setting; existing `.zshrc` goes through `migrate.sh` into `~/.zshrc.local`; `uninstall.sh` restores from backup.
4. **A checkup that can fix itself** 〔open source〕. `doctor.sh --status` shows the pinned state dashboard; `--fix` repairs after confirm; `--profile` names the plugin slowing startup (on my machine it was `compinit`, 258ms).
5. **It is a Claude Code Skill** 〔paid〕. After it lives in `~/.claude/skills/`, you say "switch to a light theme" / "why is startup slow" and the agent picks the script, runs it, and explains — **you describe the outcome, not the command**.

After install you get:

- **Looks right**: no chrome, blur, two-line prompt; dark and light themes
- **Works right**: icon `ls`, highlighted `cat`, `Ctrl+R` history search, `z` jump
- **Stays put**: everything in files — **re-run on a new Mac and it all comes back**

> No CLI background required: copy → paste → Enter is enough.

---

## 3. Free build / paid build

Two axes:

1. **How far the palette goes** — free makes iTerm2 look right; paid makes that palette **leave iTerm2**.
2. **Who drives** — free: you run `./theme.sh` and `./doctor.sh --fix`; paid: install the Skill and talk to the agent.

The open-source build is not a demo: 3 palettes, blur, log coloring, `Shift+Enter`, modern CLI, self-repairing checkup, one-command uninstall — **every script ships**. Axis two is not more features; it is "you do not have to memorize commands".

| | Open source (MIT · free) | Paid · ¥19.9 |
|---|---|---|
| Install / migrate / theme / doctor / update / sync / uninstall | ✅ | ✅ |
| Minimal chrome · blur · Triggers · Semantic Cmd-click · Shift+Enter | ✅ | ✅ |
| Modern CLI set · `doctor.sh --status/--fix/--profile` · `.zshrc` migrate | ✅ | ✅ |
| **Themes** | 3 community | + 4 brand (**2 light**) |
| **Claude Code Skill** | — | ✅ |
| **Multi-terminal sync** + **ecosystem match** (bat/fzf/eza/git diff/tmux/VS Code) | — | ✅ |
| Follow system appearance · project tab colors · palette deriver / import · A4 cheat sheet | — | ✅ |
| Updates & support | GitHub Issues | 1 year updates + chat support |

**What you pay for**: four brand themes, the generator that fans one palette across the tool chain, and the Skill that teaches an agent the kit.

**Paid build** → [buy page](https://huiyonghkw.github.io/hekouwang-terminal-kit/) (¥19.9, 7-day no-questions refund)
or WeChat **`hekouwang`** (note: terminal kit). Trying the open-source build for a couple of days first is fine.

<details>
<summary>How to get and install the paid build (two paths)</summary>

**Path A · zip** (default, no GitHub account needed)

```bash
cd ~/hekouwang-terminal-kit
./unlock.sh ~/Downloads/hekouwang-terminal-kit-paid-*.zip
```

**Path B · private repo** (easier if you use git)

Send your GitHub username after purchase; once added to `hekouwang-terminal-kit-pro`:

```bash
git clone git@github.com:huiyonghkw/hekouwang-terminal-kit-pro.git
cd hekouwang-terminal-kit-pro && ./install.sh
```

The private repo is a superset of the free one — clone that alone. Buyer homepage lives in the paid package / private repo (not in this public tree).
</details>

File-level split and how brand themes are derived → [`docs/manual.md`](docs/manual.md) section 3

---

## 4. Installing

<p align="center">
  <img src="docs/images/02-overview.en.png" width="88%" alt="Four steps: install → look · tools · advanced">
</p>

### Prerequisites

1. A Mac (Apple Silicon or Intel)
2. Network access (mainland China: see `CN=1` below)
3. Open Terminal: `Command + Space` → `Terminal`. Install here first; switch to iTerm2 afterwards

### Which case are you

| Your situation | Use |
|---|---|
| New Mac, or no custom `~/.zshrc` | `./install.sh` |
| **Already have your own `.zshrc`** | `./migrate.sh` first |

`install.sh` **overwrites** `~/.zshrc` (after backup). Years of aliases belong in migrate → `~/.zshrc.local`, then the template.

```bash
./migrate.sh            # report only
./migrate.sh --apply    # apply after you confirm
```

### Install

```bash
git clone https://github.com/huiyonghkw/hekouwang-terminal-kit.git
cd hekouwang-terminal-kit

./install.sh --dry-run    # preview files, settings, and hard no-touch list
./install.sh
```

Mainland China network stuck (`portable-ruby` / `SSL_ERROR_SYSCALL`):

```bash
CN=1 ./install.sh
```

Roughly: Homebrew → iTerm2 + fonts → CLI → oh-my-zsh → theme (**ecosystem match is paid**) → `.zshrc` → three GUI settings → checkup.

When you see success, `doctor.sh` runs automatically:

<p align="center">
  <img src="docs/images/10-doctor.png" width="62%" alt="doctor.sh all green">
</p>

> ⚠️ This screenshot is a **paid-tier** machine — the "ecosystem match" section is all green.
> **On the open-source build that section will not be all green; that is not a broken install.**
> Missing paid pieces are not treated as failures. Open-source success = sections 1–4 and 6–8 green.

**Quit Terminal.app, open iTerm2.** Scripts are idempotent; re-runs are safe.

---

## 5. Why it looks right afterwards

<p align="center">
  <img src="docs/images/04-appearance.en.png" width="88%" alt="Three settings that make the look">
</p>

You do nothing here — the installer already wrote them with `defaults write`:

1. **Theme = Minimal**: no title bar, border, or scrollbar — one canvas + blur
2. **Colors**: lightness solved from WCAG contrast (body 5.5:1 / accent 9:1)
3. **Font = Maple Mono NF CN** (open-source default): monospace + Nerd icons + CJK; **this kit ships no font files**. The paid build has a font priority table that can pick up Operator Mono you already bought

---

## 6. The handful of commands you use daily

<p align="center">
  <img src="docs/images/05-cli.en.png" width="88%" alt="Modern CLI set">
</p>

| Tool | One line | How |
|---|---|---|
| **starship** | A useful prompt | directory / git branch / last command duration |
| **eza** (replaces `ls`) | Colored icons in listings | just type `ls` |
| **bat** (replaces `cat`) | Syntax highlight + line numbers | `cat filename` |
| **delta** (replaces git diff) | Highlighted diffs | `git diff` |
| **fzf** | Fuzzy-find everything | `Ctrl+T` files, `Alt+C` fuzzy cd |
| **zoxide** (replaces `cd`) | Jump by a word | `z keyword` |
| **atuin** | Full-text command history | `Ctrl+R` |

One more for AI: **`Shift + Enter` newline without submit** — multi-line prompts feel natural.

<p align="center">
  <img src="docs/images/11-session.png" width="62%" alt="Live session: eza + bat + z">
</p>

All shortcuts → [`references/shortcuts.md`](references/shortcuts.md)

---

## 7. Switching themes

```bash
./theme.sh                 # gallery with true-color 16-swatch bars
./theme.sh tokyo-night     # switch (open source: 3 community palettes)
./theme.sh --preview NAME  # preview without switching
```

Open source switches **iTerm2** (Dynamic Profile, applies on save).
Paid: the same command also updates Ghostty / Warp / Terminal.app, plus bat / fzf / eza / git diff / tmux / VS Code — **one generated palette, not hand copies**.

Paid extras: `./theme.sh --auto` follows system appearance; project workspaces (tab color on `cd`); palette deriver / import. See the paid buyer homepage and [`docs/manual.md`](docs/manual.md) sections 7–8.

---

## 8. Maintenance: checkup / update / uninstall

```bash
./doctor.sh            # checkup (section 0 = state dashboard)
./doctor.sh --status   # dashboard only: theme / auto / node / semantic / Ghostty reload
./doctor.sh --fix      # repair item by item after confirm
./doctor.sh --profile  # slow startup? names the plugin

./update.sh            # update (git install)
./sync.sh              # multi-machine notes in the manual

./uninstall.sh         # restore from backup + GUI factory reset
./uninstall.sh --dry-run
```

Put personal aliases / PATH in `~/.zshrc.local` (the template loads it). Do not edit the overwritten template sections.

---

## 9. Advanced & FAQ

tmux `-CC`, Triggers, **Semantic Interaction Layer** (Cmd-click), Shell Integration, multi-terminal differences, full FAQ (font `?` glyphs, `cat` color after theme switch, the `cat | head` color trap, …) →

**[`docs/manual.md`](docs/manual.md)** (中文：[`docs/manual.zh-CN.md`](docs/manual.zh-CN.md)) · docs site: [Semantic layer](https://huiyonghkw.github.io/hekouwang-terminal-kit/guide/semantic.html)

| Also | Go to |
|---|---|
| Shortcuts | [`references/shortcuts.md`](references/shortcuts.md) |
| Changelog | [`CHANGELOG.md`](CHANGELOG.md) |
| 简体中文 | [`README.zh-CN.md`](README.zh-CN.md) |

## License

Open-source build: [MIT](LICENSE.txt). Paid pieces ship under the license inside the paid package.
