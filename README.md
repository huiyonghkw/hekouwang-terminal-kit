<h1 align="center">hekouwang-terminal-kit</h1>

<p align="center">
  <b>The terminal deserves one more round of setup in the AI era.</b><br>
  Borderless Minimal · automatic ERROR coloring · Shift+Enter for multi-line prompts<br>
  Config as code · safe to install, safe to remove
</p>

<p align="center">
  <a href="README.md">English</a> · <a href="README.zh-CN.md">简体中文</a>
  &nbsp;·&nbsp;
  <img src="https://img.shields.io/badge/license-MIT-00d4aa" alt="MIT">
</p>

<p align="center">
  <img src="docs/images/01-cover.en.png" width="88%" alt="A terminal workbench after install">
</p>

> Everything you run — installer, theme switcher, doctor, uninstaller — speaks English by
> default; `--lang zh` switches it (and everything after) to Chinese.

---

## Install in one minute

You need: a Mac, network access, and the ability to open Terminal.

```bash
git clone https://github.com/huiyonghkw/hekouwang-terminal-kit.git
cd hekouwang-terminal-kit

./install.sh --dry-run    # preview: which files change, which settings are written, what is never touched
./install.sh              # run for real once you are happy
```

On a mainland-China network (stuck on `portable-ruby` / `SSL_ERROR_SYSCALL`):

```bash
CN=1 ./install.sh
```

Already have your own `.zshrc`? Migrate first — do not overwrite it:

```bash
./migrate.sh              # report only
./migrate.sh --apply      # apply after you confirm
```

When you see `✅ 全部完成！` (or the English equivalent), quit Terminal.app and open **iTerm2**.
Details and common snags → [`docs/manual.md`](docs/manual.md)

---

## What you get

- **Looks right**: Minimal chrome · blur · three community dark themes
- **Works right**: colored `ls`/`cat`/`git diff` · `Ctrl+R` history · `z` jump · `Shift+Enter` newline without submit
- **Stays put**: ERROR/WARN auto-color · password-prompt → password manager · everything in files, restore by re-running on a new Mac
- **Removable**: `./uninstall.sh` restores from backup and resets GUI settings to factory

| Daily | What it does |
|---|---|
| `ls` / `cat` / `git diff` | Already aliased to eza / bat / delta — keep typing the old names |
| `Ctrl+R` / `Ctrl+T` / `z word` | Search history · search files · jump directories |
| `./theme.sh` | List / switch themes (3 community palettes in the open-source build) |
| `./doctor.sh` · `--fix` · `--profile` | Checkup · guided repair · name the plugin slowing startup |
| `./uninstall.sh` | Remove the whole kit cleanly |

Full commands & shortcuts → [`references/shortcuts.md`](references/shortcuts.md)

---

## Same machine, same command — the only difference is the tier

<table>
<tr>
<th width="50%">Open source (free · MIT)</th>
<th width="50%">Paid · ¥19.9</th>
</tr>
<tr>
<td><img src="docs/images/cmp-iterm2-free.png" alt="Free: eza / bat / git diff each speak their own color language"></td>
<td><img src="docs/images/cmp-iterm2-paid.png" alt="Paid: all four from one palette"></td>
</tr>
</table>

The left side is not "ugly colors" — three tools each speak their own dialect, and none match the terminal background.
On the right, all four are **generated from the same palette**, so they are family.

I learned this the hard way: a hand-maintained Warp theme whose comment said "identical to iTerm2" had **8 of 16 ANSI slots wrong**.

| | Open source | Paid |
|---|---|---|
| Install / theme / doctor / uninstall scripts | ✅ | ✅ |
| Minimal + blur + Triggers + Shift+Enter + modern CLI | ✅ | ✅ |
| Themes | 3 community | + 4 brand (including 2 light) |
| One palette → four terminals + bat/fzf/eza/git diff/tmux/VS Code | — | ✅ |
| Follow system light/dark · project tab colors · palette deriver / import | — | ✅ |
| Claude Code Skill (say "switch to a light theme" / "why is startup slow" and the agent runs it) | — | ✅ |

The open-source build is not a demo — every script ships, and you can keep using it forever.
What you pay for: **the palette walking out of iTerm2**, plus the Skill that teaches an agent the kit.

**Paid build** → [buy page](https://huiyonghkw.github.io/hekouwang-terminal-kit/) (7-day no-questions refund)
or WeChat **`hekouwang`** (note: terminal kit)

How to unlock, multi-terminal sync, and workspaces → in the paid package / private repo buyer homepage (not in this public repo)

---

## When something is wrong

```bash
./doctor.sh            # what failed
./doctor.sh --fix      # repair item by item after confirm
./doctor.sh --profile  # slow startup? names the plugin
./uninstall.sh         # walk it back
```

More troubleshooting → [`docs/manual.md`](docs/manual.md) FAQ section

---

## Docs

| Want | Go to |
|---|---|
| Install details / daily use / advanced / FAQ | [`docs/manual.md`](docs/manual.md) |
| Shortcuts | [`references/shortcuts.md`](references/shortcuts.md) |
| Changelog | [`CHANGELOG.md`](CHANGELOG.md) |
| 简体中文 | [`README.zh-CN.md`](README.zh-CN.md) · [`docs/manual.zh-CN.md`](docs/manual.zh-CN.md) |

## License

Open-source build: [MIT](LICENSE.txt). Paid pieces ship under the license inside the paid package.
