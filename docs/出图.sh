#!/bin/bash
# ============================================================
# docs/ 里的演示图：HTML → PNG   ⭐内部工具（两档都不发）
#
#   ./docs/出图.sh              重出全部
#   ./docs/出图.sh triggers     只出 term-triggers.html → images/21-triggers.png
#   ./docs/出图.sh --list       看有哪些
#
# 为什么这些图是 HTML 不是真机截图：像 ERROR/WARN 那种圆角药丸标签、箭头注释、
# 底部说明条，终端本身输出不了。真机截图另有其人 —— 见 docs/对比截图.sh。
#
# ⛔ 必须开独立无痕实例：`--incognito --user-data-dir=<临时唯一目录>`。
#    共享默认 profile 会把用户正开着的 Chrome 窗口顶掉/杀掉（2026-07-13 用户明确要求）。
# ⚠️ 这些 HTML 引的是 Google Fonts。断网/被墙时字体会静默回退成系统字体，
#    图看着"差不多"但字重字距全变。出图后**肉眼确认一眼**，别只看退出码。
# ============================================================
set -u
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$DIR/images"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
g='\033[1;32m'; r='\033[1;31m'; d='\033[2m'; o='\033[0m'

# 源 HTML → 目标 PNG
# ⛔ 宽度**别手填**：term-*.html 自己在 CSS 里写死了 `html,body{width:980px}`，
#    手填 1180 会让页面居中留出两条白边。脚本从 HTML 里读，读不到才用默认值。
# ⛔ 高度也别手填：填矮了裁掉底部说明条，填高了留一大块空白（第一版就是 700
#    截出来底下空了 40%）。做法是**先截高再自动裁掉末尾的纯色行**。
# ⛔ 10-doctor / 11-session 用**真机截图**（2026-07-23 用户重截），不由 HTML 渲染 ——
#    对应的 term-doctor.html / term-session.html 已删（它们还带着旧 skill 名的演示路径）。
#    别再把这两张加回本清单。40-workspace 同理：改用真机截图（3 个彩色 tab），不由 HTML 渲染。
MAP="
term-tmux|20-tmux
term-triggers|21-triggers
term-shell|22-shell
card-01-cover|01-cover
card-02-overview|02-overview
card-03-install|03-install
card-04-appearance|04-appearance
card-05-cli|05-cli
card-06-advanced|06-advanced
card-30-parity|30-ghostty-parity
"
DEFAULT_W=1280      # HTML 没声明宽度时用（card-*.html 是这种）
SHOOT_H=2400        # 先截这么高，之后自动裁

[ -x "$CHROME" ] || { printf "${r}✗ 没找到 Google Chrome${o}\n"; exit 1; }
mkdir -p "$OUT"

if [ "${1:-}" = "--list" ]; then
  printf "${d}%s${o}\n" "可出的图（源 → 产物）："
  printf '%s\n' "$MAP" | while IFS='|' read -r src dst; do
    [ -n "$src" ] || continue
    printf "  %-22s → images/%s.png\n" "$src.html" "$dst"
  done
  exit 0
fi

# render_one <html文件> <png文件> —— 出一张图（含尺寸探测与自动裁）
render_one() {
  local html="$1" png="$2" css w h shoot_h crop tmp sz
  # 宽高都从 CSS 读，别猜。⚠️ card-*.html 的尺寸不在自己文件里，在它 link 的
  #    _base.css（html,body{width:1280px;height:800px}）—— 只 grep 当前文件会漏。
  # ⛔ 只有真 link 了 _base.css 的才拼它。无条件拼会让 term-*.html（自己只声明宽度）
  #    读到 _base.css 的 height:800px，于是当成固定尺寸不裁 —— 实测踩过。
  css="$(cat "$html")"
  if grep -q '_base\.css' "$html" && [ -f "$DIR/_base.css" ]; then
    css="$css
$(cat "$DIR/_base.css")"
  fi
  w="$(printf '%s' "$css" | grep -oE 'html,body\{width:[0-9]+px' | grep -oE '[0-9]+' | head -1)"
  h="$(printf '%s' "$css" | grep -oE 'html,body\{width:[0-9]+px;height:[0-9]+px' | grep -oE '[0-9]+' | sed -n 2p)"
  w="${w:-$DEFAULT_W}"
  # 声明了固定高度就照着截、**不裁**：那是设计稿尺寸，底部留白是有意的
  if [ -n "$h" ]; then shoot_h="$h"; crop=0; else shoot_h="$SHOOT_H"; crop=1; fi
  # 每张图一个独立临时目录：共用会撞 Chrome 的 allocator，批量时挂死
  tmp="$(mktemp -d)"
  if "$CHROME" \
      --headless=new --incognito --user-data-dir="$tmp" \
      --allow-file-access-from-files --disable-gpu --no-sandbox \
      --hide-scrollbars --force-device-scale-factor=2 \
      --window-size="$w,$shoot_h" \
      --virtual-time-budget=4000 \
      --screenshot="$png" "file://$html" >/dev/null 2>&1 && [ -s "$png" ]; then
    # 自动裁掉底部纯背景：从最后一行往上找，第一行「和背景色不同的像素占比 >0.2%」处停
    # ⚠️ 声明了固定高度的（card-*.html 走 _base.css 的 800px）**不许裁** ——
    #    那是设计稿尺寸，底部留白是有意的。只有高度靠内容撑开的才需要裁。
    [ "$crop" = "1" ] && python3 - "$png" <<'PYCROP'
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGB")
W, H = im.size
px = im.load()
bg = px[W // 2, H - 2]                       # 底部中点即背景色
def content(y):
    hit = 0
    for x in range(0, W, 4):                 # 每 4 px 采样一次，够用且快
        r, g, b = px[x, y]
        if abs(r-bg[0]) + abs(g-bg[1]) + abs(b-bg[2]) > 24:
            hit += 1
            if hit > W / 4 * 0.002:          # >0.2% 即算有内容
                return True
    return False
y = H - 1
while y > 0 and not content(y):
    y -= 1
pad = int(40 * (W / 980))                    # 底部留和顶部相当的呼吸
bottom = min(H, y + pad)
if bottom < H - 4:
    im.crop((0, 0, W, bottom)).save(sys.argv[1])
PYCROP
    sz="$(sips -g pixelWidth -g pixelHeight "$png" 2>/dev/null \
          | awk '/pixelWidth/{a=$2}/pixelHeight/{b=$2}END{print a"×"b}')"
    printf "  ${g}·${o} %-24s → %s  ${d}%s${o}\n" "$(basename "$html")" "$(basename "$png")" "$sz"
  else
    printf "  ${r}✗ %s 出图失败${o}\n" "$(basename "$html")"
  fi
  rm -rf "$tmp"
}

FILTER="${1:-}"
printf '%s\n' "$MAP" | while IFS='|' read -r src dst; do
  [ -n "$src" ] || continue
  [ -n "$FILTER" ] && [[ "$src" != *"$FILTER"* ]] && continue
  [ -f "$DIR/$src.html" ] || { printf "  ${r}✗ 缺源文件 %s${o}\n" "$src.html"; continue; }
  render_one "$DIR/$src.html" "$OUT/$dst.png"
  # ⭐ 有英文变体就一并出：<src>.en.html → <dst>.en.png。中英同一个 MAP，
  #    加新卡片时不会漏配英文 —— 只要建了 .en.html，这里自动带上。
  [ -f "$DIR/$src.en.html" ] && render_one "$DIR/$src.en.html" "$OUT/$dst.en.png"
done

printf "${d}%s${o}\n" "出完记得肉眼看一眼：Google Fonts 没加载上时会静默回退，退出码照样是 0。"
