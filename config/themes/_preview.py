#!/usr/bin/env python3
# ============================================================
# hekouwang-terminal-kit — 主题画廊 / 预览渲染器
#
# 用法（一般由 theme.sh 调用，也可以直接跑）:
#   python3 _preview.py --gallery [--current <名字>]   全部主题：一行一套 + 16 色条
#   python3 _preview.py --card <名字>                  单套主题：整块「假终端」预览
#   python3 _preview.py --banner <名字>                换肤回执的抬头（名字 + 色条）
#   python3 _preview.py --strip <名字>                 单行 16 色条
#
# 为什么要它：卖配色的产品，列表里不给人看颜色是最伤的一处。
# 这里用 24 位真彩色（38;2;r;g;b）直接画，**不依赖当前终端是哪套主题**，
# 所以在任何终端里截出来都是同一张图 —— 这就是给付费仓截主题图的那把工具。
#
# 色值不从色板 .py 读，从**生成出来的 iTerm2 .json** 读：
# 开源版没有 brand.py，但只要主题 JSON 在，预览就在。少一个分档分支。
#
# ⚠️ 宽度：本文件只用 ASCII + 中日韩（宽 2）+ 制表符/箭头这类「歧义宽度」字符。
#    歧义宽度一律按 1 算（iTerm2 / Ghostty / 自带终端默认都是 1）。
#    **别往对齐的行里加 emoji 或 Nerd Font 图标** —— 它们宽度按终端而变，边框会错位。
# ============================================================
import json
import os
import sys

sys.path.insert(0, os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "lib"))
from i18n import t, LANG  # noqa: E402

# 显示名边表：产物里烧的是英文名，装成中文时这里换成中文名。
# 读不到就用 JSON 里那个名字兜底 —— 预览永远不该因为少个边表就渲染不出来。
_NAMES = {}
try:
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "names.json"),
              encoding="utf-8") as _f:
        _NAMES = json.load(_f)
except (OSError, ValueError):
    pass


def _display(name, fallback):
    entry = _NAMES.get(name) or {}
    return entry.get(LANG) or entry.get("en") or fallback

NO_COLOR = bool(os.environ.get("NO_COLOR"))
# NO_COLOR 要把**加粗和重置也一起关掉**，不只是关颜色 —— 只关颜色的话
# 输出里还剩一地 \033[1m / \033[0m，那正是 NO_COLOR 想避免的东西。
R = "" if NO_COLOR else "\033[0m"
BOLD = "" if NO_COLOR else "\033[1m"


# ---- 色值 ----------------------------------------------------
def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def fg(h):
    if NO_COLOR:
        return ""
    r, g, b = rgb(h)
    return f"\033[38;2;{r};{g};{b}m"


def bg(h):
    if NO_COLOR:
        return ""
    r, g, b = rgb(h)
    return f"\033[48;2;{r};{g};{b}m"


def mix(a, b, t):
    """把 a 按比例 t 混进 b（t=0 全是 b，t=1 全是 a）。"""
    x, y = rgb(a), rgb(b)
    return "".join(f"{round(x[i] * t + y[i] * (1 - t)):02x}" for i in range(3))


def luma(h):
    r, g, b = (c / 255 for c in rgb(h))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def cw(s):
    """显示宽度。中日韩算 2，其余（含歧义宽度）算 1。"""
    n = 0
    for ch in s:
        o = ord(ch)
        if (0x1100 <= o <= 0x115F or 0x2E80 <= o <= 0x303E or 0x3041 <= o <= 0x33FF
                or 0x3400 <= o <= 0x4DBF or 0x4E00 <= o <= 0x9FFF or 0xA000 <= o <= 0xA4CF
                or 0xAC00 <= o <= 0xD7A3 or 0xF900 <= o <= 0xFAFF or 0xFE30 <= o <= 0xFE6F
                or 0xFF00 <= o <= 0xFF60 or 0xFFE0 <= o <= 0xFFE6):
            n += 2
        else:
            n += 1
    return n


# ---- 读主题 ---------------------------------------------------
def _c(d):
    """iTerm2 的 {Red Component: 0.1, ...} → 'rrggbb'"""
    return "".join(f"{round(d[k] * 255):02x}"
                   for k in ("Red Component", "Green Component", "Blue Component"))


def load_one(path):
    with open(path, encoding="utf-8") as f:
        prof = json.load(f)["Profiles"][0]
    if "Background Color" not in prof:      # 无配色的 minimal 骨架，跳过
        return None
    p = {
        "name": os.path.basename(path)[:-5],
        "display": _display(os.path.basename(path)[:-5], prof.get("Name", "?")),
        "bg": _c(prof["Background Color"]),
        "fg": _c(prof["Foreground Color"]),
        "cursor": _c(prof["Cursor Color"]),
        "selbg": _c(prof.get("Selection Color", prof["Background Color"])),
        "ansi": [_c(prof[f"Ansi {i} Color"]) for i in range(16)],
    }
    p["light"] = luma(p["bg"]) > 0.5
    # 派生：暗调文字。暗底用 bright black（够亮）、亮底用 normal black（够浅）。
    p["dim"] = p["ansi"][8] if not p["light"] else p["ansi"][0]
    # 派生：比底色略高一档的「面」，给标题栏 / 代码块用
    p["surface"] = mix(p["fg"], p["bg"], 0.06 if not p["light"] else 0.05)
    return p


def load_all(themes_dir):
    out = []
    for fn in sorted(os.listdir(themes_dir)):
        if not fn.endswith(".json"):
            continue
        try:
            p = load_one(os.path.join(themes_dir, fn))
        except (KeyError, ValueError, OSError):
            continue
        if p:
            out.append(p)
    # 暗底在前、亮底在后；组内按名字
    out.sort(key=lambda p: (p["light"], p["name"]))
    return out


# ---- 画行 -----------------------------------------------------
def row(segs, bgc, width, indent=2):
    """把 [(文字, 前景色, 加粗)] 铺成一整行，右边用底色补满到 width。

    ⚠️ 底色必须**补满**再收尾，不能靠 \\033[K —— 那个清到的是屏幕宽度，
    在窄窗口里会把整行拉断。"""
    used = 0
    body = ""
    for text, color, bold in segs:
        body += (BOLD if bold else "") + (fg(color) if color else "") + text + (R + bg(bgc) if not NO_COLOR else "")
        used += cw(text)
    pad = max(0, width - used)
    return " " * indent + bg(bgc) + body + " " * pad + R


def strip(p, cell=2):
    """16 色条：8 normal + 8 bright，用底色块画（空格宽度最稳）。"""
    s = ""
    for i in range(16):
        s += bg(p["ansi"][i]) + " " * cell
        if i == 7:
            s += R + " "
    return s + R


# ---- 画廊：一行一套 -------------------------------------------
def gallery(themes, current=None):
    ink, sub = "e8e8e8", "8a8a8a"
    if NO_COLOR:
        ink = sub = "000000"
    out = []
    n_paid = sum(1 for p in themes if p["name"].startswith(("v1-", "v2-", "v3-")))
    out.append("")
    out.append(f"  {BOLD}{fg(ink)}{t('PRE_TITLE')}{R}"
               f"    {fg(sub)}{t('PRE_COUNT', len(themes))}"
               + (t("PRE_BRAND", n_paid) if n_paid else "")
               + (t("PRE_CURRENT_SUM", current) if current else "") + R)
    out.append("")
    # 列宽按实际内容算，别写死 —— 写死的那版被「Catppuccin Mocha」这个长名字顶爆过，
    # 色条被推得参差不齐。自己加主题时也不用回来改数字。
    w_name = max(cw(p["name"]) for p in themes) + 2
    w_disp = max(cw(p["display"]) for p in themes) + 2
    group = None
    for p in themes:
        g = t("PRE_TONE_LIGHT") if p["light"] else t("PRE_TONE_DARK")
        if g != group:
            group = g
            out.append(f"  {fg(sub)}── {g} {'─' * 62}{R}")
        mark = f"{fg(p['cursor'])}●{R}" if p["name"] == current else " "
        name = p["name"] + " " * max(0, w_name - cw(p["name"]))
        disp = p["display"] + " " * max(0, w_disp - cw(p["display"]))
        line = (f"  {mark} {fg(ink) if p['name'] == current else fg(sub)}{name}{R}"
                f"{fg(ink)}{disp}{R}  {strip(p)}")
        if p["name"] == current:
            line += f"  {fg(p['cursor'])}{t('PRE_CURRENT')}{R}"
        out.append(line)
    out.append("")
    return "\n".join(out)


# ---- 单套：整块「假终端」预览 ---------------------------------
W = 74   # 卡片内宽


def card(p):
    a = p["ansi"]
    black, red, green, yellow, blue, purple, cyan, white = a[0:8]
    bred, bgreen, byellow, bblue, bpurple, bcyan = a[9], a[10], a[11], a[12], a[13], a[14]
    B, F, D = p["bg"], p["fg"], p["dim"]
    SUR = p["surface"]
    plus_bg = mix(green, B, 0.14)
    minus_bg = mix(red, B, 0.14)

    L = []

    def line(segs=(), bgc=None):
        L.append(row(list(segs), bgc or B, W))

    def blank(bgc=None):
        line([("", None, False)], bgc)

    # ---- 标题栏：三个灯 + 主题名 + 明暗标 ----
    tone = t("PRE_TONE_LIGHT") if p["light"] else t("PRE_TONE_DARK")
    right = f"{p['name']} · {tone}"
    head = [("  ", None, False),
            ("●", "ff5f57", False), ("  ", None, False),
            ("●", "febc2e", False), ("  ", None, False),
            ("●", "28c840", False),
            ("     ", None, False),
            (p["display"], F, True)]
    used = sum(cw(t) for t, _, _ in head)
    head.append((" " * max(1, W - used - cw(right) - 2), None, False))
    head.append((right, D, False))
    L.append(row(head, SUR, W))
    L.append(row([("", None, False)], mix(F, B, 0.12), W))   # 一像素分隔线

    blank()
    # ---- 提示符（和 starship.toml 出来的一模一样，别改成好看的假样子）----
    path_parent, path_leaf = "~/Dashboard/Github/", "hekouwang-factory"
    meta = "1.2s · 22:14"
    left = [("  ", None, False), (path_parent, D, False), (path_leaf, blue, True),
            ("  ", None, False), ("main", D, False), (" ", None, False),
            ("+1", green, False), (" ", None, False), ("!2", yellow, False),
            (" ", None, False), ("?1", D, False)]
    used = sum(cw(t) for t, _, _ in left)
    left.append((" " * max(1, W - used - cw(meta) - 2), None, False))
    left.append((meta, D, False))
    line(left)
    line([("  ", None, False), ("❯", p["cursor"], True), (" eza -l --icons --git", F, False)])
    for perm, size, who, nm, color, tail in [
        (".rw-r--r--", " 2.1k", "huiyong", "README.md", byellow, ""),
        ("drwxr-xr-x", "   - ", "huiyong", "config", bblue, "/"),
        (".rwxr-xr-x", " 8.4k", "huiyong", "theme.sh", bgreen, "*"),
        ("lrwxr-xr-x", "  12 ", "huiyong", "current", bcyan, " -> ../v2-mihei"),
    ]:
        line([("   ", None, False), (perm, D, False), ("  ", None, False),
              (size, D, False), ("  ", None, False), (who, D, False),
              ("  ", None, False), (nm, color, True), (tail, D, False)])
    blank()

    # ---- git diff（delta 的样子）----
    line([("  ", None, False), ("❯", p["cursor"], True), (" git diff", F, False)])
    line([("   ", None, False), ("config/themes/_generate.py", blue, True)])
    line([("   ", None, False), ("─" * 68, D, False)])
    L.append(row([("  ", None, False), ("@@ -204,7 +204,9 @@ def build(p):", purple, False)],
                 mix(purple, B, 0.10), W))
    L.append(row([(" 204 ", D, False), ("-    \"Bold Color\": col(p[\"fg\"]),", red, False)], minus_bg, W))
    L.append(row([(" 204 ", D, False), ("+    \"Bold Color\": col(p[\"ansi\"][15]),", green, False)], plus_bg, W))
    L.append(row([(" 205 ", D, False), ("+    \"Tab Color\": col(p[\"cursor\"]),", green, False)], plus_bg, W))
    blank()

    # ---- 语法高亮（bat 的样子）----
    line([("  ", None, False), ("❯", p["cursor"], True), (" bat theme.py", F, False)])
    L.append(row([("   1 ", D, False), ("def ", purple, False), ("apply", blue, True),
                  ("(theme: ", F, False), ("str", cyan, False), (") -> ", F, False),
                  ("bool", cyan, False), (":", F, False)], SUR, W))
    L.append(row([("   2 ", D, False), (t("PRE_CODE_COMMENT"), D, False)], SUR, W))
    L.append(row([("   3 ", D, False), ("    return ", purple, False),
                  ("write", blue, False), ("(", F, False), ("\"~/.config/current\"", green, False),
                  (", ", F, False), ("240", yellow, False), (")", F, False)], SUR, W))
    blank()

    # ---- Triggers：错误/警告/成功自动标色 ----
    line([("  ", None, False), ("❯", p["cursor"], True), (" ./deploy.sh", F, False)])
    L.append(_hl(B, red, " ERROR ", t("PRE_LOG_ERROR"), F))
    L.append(_hl(B, yellow, " WARN  ", t("PRE_LOG_WARN"), F))
    L.append(_hl(B, green, " OK    ", t("PRE_LOG_OK"), F))
    blank()

    line([("  ", None, False), ("❯", p["cursor"], True), (" ", None, False),
          ("█", p["cursor"], False)])
    blank()

    # ---- 色板尺 ----
    L.append(row([("", None, False)], mix(F, B, 0.12), W))
    L.append(" " * 2 + bg(SUR) + " " * 2 + strip(p) + bg(SUR)
             + " " * max(0, W - 2 - (16 * 2 + 1)) + R)
    hexes = f"bg {p['bg']}   fg {p['fg']}   cursor {p['cursor']}"
    L.append(row([("  ", None, False), (hexes, D, False)], SUR, W))

    return "\n".join(L)


def banner(p, width=74):
    """换肤回执的抬头：主题名 + 明暗标 + 色条。

    右对齐要按显示宽度算，中文占 2 —— 所以这行由 Python 出，
    别在 bash 里用 printf %-Ns 拼（那个按字节数，中文一定歪）。"""
    tone = t("PRE_TONE_LIGHT") if p["light"] else t("PRE_TONE_DARK")
    right = f"{p['name']} · {tone}"
    left = f"{p['display']}"
    pad = max(2, width - cw(left) - cw(right) - 2)
    return (f"  {fg(p['cursor'])}●{R} {BOLD}{fg(p['fg'] if p['light'] else 'e8e8e8')}{left}{R}"
            f"{' ' * pad}{fg(p['dim'])}{right}{R}\n"
            f"    {strip(p)}")


def _hl(B, tag_bg, tag, text, F):
    """Trigger 高亮行：只标匹配到的词（深色字 + 彩底），不整行涂。"""
    return (" " * 2 + bg(B) + "   " + bg(tag_bg) + fg(B) + BOLD + tag + R
            + bg(B) + fg(F) + text + " " * max(0, W - 3 - cw(tag) - cw(text)) + R)


# ============================================================
def err(msg):
    print(msg, file=sys.stderr)


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    args = sys.argv[1:]
    if not args:
        err(t("PRE_USAGE"))
        return 1
    mode = args[0]
    themes = load_all(here)
    if not themes:
        err(t("PRE_NO_THEMES"))
        return 1
    if mode == "--gallery":
        cur = None
        if "--current" in args:
            i = args.index("--current")
            cur = args[i + 1] if i + 1 < len(args) else None
        print(gallery(themes, cur))
        return 0
    if mode in ("--card", "--strip", "--banner"):
        if len(args) < 2:
            err(t("PRE_NEED_NAME"))
            return 1
        want = next((p for p in themes if p["name"] == args[1]), None)
        if not want:
            err(t("PRE_NO_SUCH", args[1]))
            return 1
        if mode == "--card":
            print("\n" + card(want) + "\n")
        elif mode == "--banner":
            print(banner(want))
        else:
            print("  " + strip(want))
        return 0
    err(f"  不认识的参数 '{mode}'")
    return 1


if __name__ == "__main__":
    sys.exit(main())
