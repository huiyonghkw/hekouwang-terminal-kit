#!/bin/bash
# ============================================================
# hekouwang-terminal-kit — 分档导出
#
# 用法:
#   ./release.sh --oss  <目录> [--update]   导出开源版 → public 仓（MIT，剔付费件）
#   ./release.sh --pro  <目录> [--update]   导出付费版 → private 仓（全量，商业授权）
#   ./release.sh --pack [文件.zip]          打付费包 zip（给不用 git 的买家）
#   ./release.sh --meta [oss|pro]           把仓库 description / topics 推上 GitHub
#   ./release.sh --tag  [子仓目录...]        按 VERSION 给母版+子仓打 tag 并推（幂等）
#   ./release.sh --release [版本号]          按 CHANGELOG-OSS 发公开仓的 GitHub Release
#   ./release.sh --check                    只检查：有没有夹带不该带出去的东西
#
#   不带 --update = 第一次建仓，目标必须是空目录
#   带   --update = 更新已有仓，rsync --delete 同步（保 .git），**不自动提交**
#
# 为什么要有这个脚本：
# 这个目录是**母版**，什么都有（品牌色板、速查卡、还有历史提交里的一些真实
# 服务器信息）。直接把它设成 public 是不行的 —— git 历史会一起公开。
# 正确做法是从母版**导出**一份干净的开源版，作为新公开仓的第一个提交。
#
# ⚠️ 分档**不是**「代码开源 / 只卖数据包」——2026-07-22 把边界从「只有品牌色板」
# 扩到「品牌色板 + 多终端生态生成器」之后，付费侧就含了 792 行 Python 代码
# （generators/pro.py 605 + palettes/_derive.py 187）。对外别再说「代码全部开源」，
# 会被开源用户当场挑出来。
#
# 真实的分界线是**能力**，不是文件类型：
#   免费 = 一个配好看的 iTerm2 —— 3 套社区配色 + 毛玻璃 + Triggers + Shift+Enter
#          + CLI 全家桶 + 体检 / 迁移 / 卸载 + 生成器核心 _generate.py
#   付费 = 让这份色板走出 iTerm2 —— Ghostty / Warp / 自带终端 / bat / fzf / eza /
#          git diff / tmux / VS Code + 4 套品牌主题 + 色板推导器 + 字体表 + 速查卡 + 服务
#
# 付费件缺席时全部脚本优雅降级、不报错：生成器只出 iTerm2 并打印「以下属付费包」；
# 付费件不在时生成器照常出完整 iTerm2 主题。开源版拿到手就是完整可用的产品，
# 不是阉割演示版 —— 这条由下面 --oss 的「降级验证」逐项真跑守住，不是口头承诺。
# ============================================================
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

g='\033[1;32m'; r='\033[1;31m'; y='\033[1;33m'; b='\033[1;34m'; d='\033[2m'; o='\033[0m'

# ============================================================
# 两个子仓的 GitHub 侧元数据（description / topics）
#
# ⚠️ 为什么要写在这儿：description 和 topics **不是文件**，是 GitHub 服务端字段。
#    直接 `gh repo edit` 改完，母版里查无此事 —— 没有版本记录、没法复现、
#    仓库一重建就没了，过半年也想不起当初为什么那么写。所以收进母版当唯一真相源，
#    用 `./release.sh --meta` 推上去。改文案改这里，别去网页上点。
#
# ⛔ 公开仓的文案别写付费能力。这里原来写的是「换肤一条命令**全链同步**」——
#    那是付费才有的（免费版只同步 iTerm2），挂在公开仓等于钓鱼。2026-07-23 改掉。
# ============================================================
OSS_REPO="huiyonghkw/hekouwang-terminal-kit"
PRO_REPO="huiyonghkw/hekouwang-terminal-kit-pro"

# 仓库页右侧 About 栏的 Website 字段 —— 又一个**非文件**的服务端状态，同样收进母版。
# 它是 GitHub 白送的转化位：任何人点进仓库都看得见，不用翻到 README 第三节。
# ⛔ 地址从 lib/links.sh 取，别在这儿写第二份（--check 的一致性门管不到硬编码在本文件里的）。
# shellcheck disable=SC1091
. "$SCRIPT_DIR/lib/links.sh"
OSS_HOMEPAGE="$HKW_URL_BUY"
PRO_HOMEPAGE=""   # 付费仓的读者已经是买家，挂个还在卖东西的落地页很怪（同「首页换成 README-PRO」）

# GitHub Pages 的 source 同样是**非文件**的服务端状态 —— 落地页整个靠它上线。
# 仓库一重建、或者谁在网页 Settings 里把 source 改了，页面就没了，而母版里查无此事，
# 偏偏所有 CTA（换肤回执 / doctor / install / README / FUNDING）都在往那儿送人。
# ⛔ 只管公开仓：付费仓是 private，不该有 Pages。
OSS_PAGES_BRANCH="main"
OSS_PAGES_PATH="/docs"

# 只服务落地页（＝只对**还没买**的人有意义）的东西：付费仓一律不带。
# ⛔ 必须是**一份清单**。2026-07-27 我先把两张收款码写成两行 rm，隔半小时加第三张
#    （加好友码）时忘了同步，那张就跟着进了付费仓 —— 跟 PAID_PATHS 被硬编码三份、
#    同一天漂两次是同一个病。下面 build_tree 按这个数组删，删完还要逐项验一遍。
SITE_ONLY_PATHS=(
  ".github"                       # Sponsor 按钮，冲已付过钱的买家弹很怪
  "docs/index.html"               # 落地页正文
  "docs/fonts"                    # 落地页专用中文字体子集
  "docs/images/pay-wechat.png"
  "docs/images/pay-alipay.png"
  "docs/images/wechat-qr.png"
)

# 上面那条的**镜像**：只服务**付费仓首页**的东西，公开仓一律不带。
# 起因（2026-07-27 体检）：40-workspace.png 展示的是付费的项目工作区，
# 只有 README-PRO 引用它 —— 却一直跟着发进公开仓，在那儿是一张没人引用的图。
# ⚠️ 我一度以为它是孤儿直接 `git rm`，结果付费仓导出当场红（图裂门抓到了）。
#    **判「孤儿」必须两个仓都扫**：公开仓没引用 ≠ 没人用。
PRO_ONLY_PATHS=(
  "docs/images/40-workspace.png"  # 付费首页的项目工作区截图
)

# ⚠️ GitHub 的 description 上限是 **350 字符**，超一个字符整次调用报 HTTP 422、
#    什么都不改。原来这两条是 529 / 418 字符 —— 也就是说 2026-07-23 改成英文之后，
#    `--meta` 一次都没成功过，线上一直是更早的中文版，而错误被 `>/dev/null 2>&1` 藏住了。
#    2026-07-27 缩到限内，并在 --check 里加了长度门（改文案时会当场红，不用等推）。
OSS_DESC="A macOS terminal reconfigured for the AI era: iTerm2 Minimal with no borders, blur, automatic ERROR/WARN coloring and Shift+Enter for multi-line prompts, on top of oh-my-zsh / Starship / the modern CLI set. Config as code, safe to install and safe to remove. English by default, --lang zh for Chinese."
# 公开仓**不打** ghostty / warp —— 那两个是付费能力，打了会把搜这两个词的人骗进来
OSS_TOPICS="iterm2,macos,terminal,zsh,dotfiles,color-scheme,color-palette,starship,oh-my-zsh"

PRO_DESC="The complete paid build: 4 brand themes (two of them light) and one palette syncing iTerm2 + Ghostty + Warp + the built-in macOS Terminal, with bat / fzf / eza / git diff / tmux / VS Code in the same colors. Palette deriver, font table, workspaces, cheat sheet, plus the Claude Code Skill that lets an agent drive it. Manual: docs/manual.md."
# claude-code / agent-skill 只打在付费仓：Skill 是付费能力，公开仓打上就是钓鱼
PRO_TOPICS="iterm2,macos,terminal,zsh,dotfiles,color-scheme,color-palette,starship,oh-my-zsh,ghostty,warp,tmux,claude-code,agent-skill"

# 付费包独占的东西（导出开源版时逐条剔掉）
BRAND_THEMES="v2-mihei v1-keji v2-mibai v3-caijing-bai"
# 付费边界（2026-07-22 起从「只有品牌色板」扩大到「品牌色板 + 多终端/生态生成器 + 字体表」）：
#   开源版 = 全部脚本 + 生成器核心 + 3 套社区色板 → 只同步 iTerm2，字体用推荐默认
#   付费版 = 再加 4 套品牌主题 + 多终端同步 + 全生态同色 + 字体优先级表 + 速查卡 + 服务
# 分界线：免费 = 一个配好看的 iTerm2（3 套社区配色 + 毛玻璃 + Triggers + Shift+Enter）
#         付费 = 让这份色板走出 iTerm2（多终端 + 全生态）+ 4 套品牌主题 + 字体表 + 服务
PAID_PATHS=(
  "config/themes/palettes/brand.py"
  "config/themes/generators/pro.py"
  "config/font.conf"
  "config/themes/palettes/_derive.py"
  "config/themes/palettes/_import.py"
  # ⭐ 2026-07-23 收紧分档：以前「脚本全部开源、只门控配置内容」，结果免费仓里
  #    躺着多终端同步的完整实现和各 App 的格式踩坑手册 —— 别人补三个生成器就复刻了。
  #    现在按能力划线：付费能力的**实现**也进付费包，免费仓只留广告位 + exec。
  "config/themes/_apply_pro.sh"          # theme.sh 的「iTerm2 之外」那半边
  "config/themes/_workspace_pro.sh"      # workspace.sh 的实现
  # 三个付费入口脚本本身也不进公开仓（2026-07-23 二次收紧）。
  # 它们收成 22 行广告位之后仍然出现在仓库文件列表里，用户看着别扭 ——
  # "免费仓里摆着三个我不能用的脚本" 比 "根本没有" 更像半成品。
  # 买家解压付费包时脚本跟引擎一起进来，路径不变、用法不变。
  "import.sh"
  "palette.sh"
  "workspace.sh"
  # ⭐ 2026-07-27 三次收紧：**Claude Code Skill 整个归付费档**。
  #    这套目录本身就是一个 Agent Skill —— 装进 ~/.claude/skills/ 之后，「换个亮色主题」
  #    「我的终端为什么开得慢」这类话 AI 能直接驱动整套脚本跑完。那是这个产品最贵的
  #    一层能力（不是配色，是让 AI 会用它），跟「多终端 + 全生态」并列，不该白送。
  #    免费档＝人自己敲 ./theme.sh、./doctor.sh，脚本一个不少、功能一个不缺。
  # ⛔ 两份一起加（英文 + 中文镜像）。剔了英文那份、漏了中文那份，等于原样发出去。
  "SKILL.md"
  "SKILL.zh-CN.md"
  "references/terminals.md"              # 各 App 的格式口径与踩坑（核心 know-how）
  # ⛔ 双语之后每份付费文档都多出一个 .zh-CN.md 镜像 —— 剔了英文那份、漏了中文那份，
  #    等于核心 know-how 原样进了公开仓。新增付费文档时**两份一起加**。
  "references/terminals.zh-CN.md"
  # CHANGELOG 是开发流水账，逐条记着付费实现是怎么调出来的。买家看得，公开仓不给。
  # 公开仓改发 CHANGELOG-OSS.md（下面 build_tree 会把它改名成 CHANGELOG.md）。
  "CHANGELOG.md"
  "docs/速查卡.html"
  "docs/速查卡.pdf"
  "config/themes/ghostty"
  "config/themes/warp"
  "config/themes/ecosystem"
)

# 内部生产文件：既不进开源版，也不进付费包 —— 这是我自己做内容用的，不是产品的一部分
INTERNAL_PATHS=(
  "docs/泄漏指纹.txt"
  "docs/录制手册.md"
  "docs/录制沙盒.sh"
  "docs/对比截图.sh"
)
# ⚠️ release.sh 自己**故意**留在开源版里，别把它当「卖家工具、买家用不上」剔掉：
#    README 第三节把「技术上怎么分的，摆在明面上，不搞解锁码」当卖点，兑现它的就是本文件；
#    README 的脚本清单里也白纸黑字列了 release。剔掉＝承诺落空。
#    它在公开仓里的行为也是合理的：--pack 因缺 brand.py 直接报错退出，
#    --check / --oss 对想二次开发的人反而有用。
# ⛔ 但 palette.sh / workspace.sh / import.sh **不**留在开源版（07-23 改）：
#    它们曾被收成 22 行广告位留着，可仓库文件列表里摆着三个用不了的脚本，
#    观感是「半成品」而不是「有付费档」。现在整个不发，付费能力只在 README 分档表里提。
#    以前的写法是：检测到付费件不在时打印一段说明再 exit 0，
#    是有意的广告位，不是漏剔。改这里前先想清楚是不是又把「广告位」误判成「泄漏」了。

# 不该出现在公开仓里的模式（导出后逐条扫，命中就拒绝导出）
declare -a SECRET_PATTERNS=(
  '([0-9]{1,3}\.){3}[0-9]{1,3}'      # 真实 IP
  '/Users/[a-z]'                      # 硬编码家目录
  '(ghp|gho|github_pat)_[A-Za-z0-9]{20,}'
  'sk-[A-Za-z0-9]{20,}'
  'AKIA[0-9A-Z]{16}'
  'BEGIN (RSA|OPENSSH|EC) PRIVATE KEY'
)
# 豁免：这些是明确安全的（本机回环、版本号、占位符）
# ⛔ 这里原来有 `^\s*#` —— **注释行整行跳过扫描**，等于在注释里写 IP 就漏。
#    注释正是最容易顺手贴一条 ssh 连接示例的地方，豁免它等于把门开在最常走的那条路上。
#    2026-07-23 去掉；去掉后全树复扫 0 误报（唯一一处 /Users/ 在 docs/录制手册.md，
#    那是 INTERNAL_PATHS，两个仓都不导出）。别再加回来。
SECRET_ALLOW='127\.0\.0\.1|0\.0\.0\.0|<[^>]*>|[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?\s*$|version|Version|v[0-9]+\.[0-9]+'

scan_dir() {   # scan_dir <目录> → 有命中返回 1
  # 内部生产文件不参与扫描：它们既不进开源版也不进付费包，
  # 里面出现本机路径是正常的（那是给我自己看的操作手册），
  # 扫它们只会制造永远修不掉的假警报，让真警报失去意义。
  local dir="$1" hit=0 pat ex=()
  local ip
  for ip in "${INTERNAL_PATHS[@]}"; do ex+=(--exclude="$(basename "$ip")"); done
  for pat in "${SECRET_PATTERNS[@]}"; do
    local out
    out="$(grep -rInE "$pat" "$dir" --exclude-dir=.git "${ex[@]}" 2>/dev/null | grep -vE "$SECRET_ALLOW" || true)"
    if [ -n "$out" ]; then
      printf "  ${r}✗ 命中 %s${o}\n" "$pat"
      printf '%s\n' "$out" | head -5 | sed 's/^/      /'
      hit=1
    fi
  done
  return $hit
}

# ============================================================
# 导出：把母版摘成一份能进公开 / 私有仓的干净副本
#
#   oss = 公开仓 hekouwang-terminal-kit        （MIT，剔付费件）
#   pro = 私有付费仓 hekouwang-terminal-kit-pro（全量，换商业授权条款）
#
# ⚠️ 两种模式**都**必须走导出，不能把母版仓直接改可见性或加 collaborator：
#    母版的 git 历史里有旧版本 references 留下的真实服务器 IP 与家目录
#    （--check 现在能扫出 5 + 3 个提交）。付费仓虽然是 private，
#    但买家是掏了钱的陌生人 —— 拿服务器 IP 换 ¥19.9 不划算。
#    导出副本不带 .git，历史污染因此天然带不出去；当前工作区本身是干净的
#    （2026-07-23 用「去掉注释行豁免」的严格口径全树复扫过，0 处）。
# ============================================================
build_tree() {   # build_tree <oss|pro> <目标目录>
  local mode="$1" dest="$2" p t
  mkdir -p "$dest"

  # 取「仓库该有的文件」：跟踪的 + 未被 ignore 的新文件。
  # 别用 git archive HEAD（漏未提交的改动），也别 cp -R（会把 .git 一起搬走）。
  git ls-files --cached --others --exclude-standard -z 2>/dev/null \
    | while IFS= read -r -d '' f; do
        [ -f "$f" ] || continue
        mkdir -p "$dest/$(dirname "$f")"
        cp "$f" "$dest/$f"
      done

  printf "\n${b}剔除内部生产文件${o}\n"
  for p in "${INTERNAL_PATHS[@]}"; do
    [ -e "$dest/$p" ] && rm -rf "$dest/$p" && printf "  ${d}- %s${o}\n" "$p"
  done

  # ⛔ 我本机 ./import.sh 导进来的主题**两档都不能带出去** —— 买家也不该收到
  #    我个人试色留下的 rose-pine / claude-code-light。imported.py 本身被
  #    .gitignore 挡住了，但**它生成的产物没有**：json / ghostty / warp /
  #    ecosystem 会照常出现在 git ls-files --others 里，一路跟进公开仓。
  #    2026-07-23 实测：导出后 config/themes/ 里躺着我的两套导入主题，且是待提交状态。
  if [ -f "$SCRIPT_DIR/config/themes/palettes/imported.py" ]; then
    local imp
    imp="$(python3 - "$SCRIPT_DIR/config/themes/palettes/imported.py" <<'PYIMP'
import ast, pathlib, re, sys
src = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
m = re.search(r"PALETTES\s*=\s*(\{.*\})\s*$", src, re.S)
print(" ".join(sorted(ast.literal_eval(m.group(1)))) if m else "")
PYIMP
)"
    if [ -n "$imp" ]; then
      printf "\n${b}剔除本机导入的主题（个人试色，不随产品分发）${o}\n"
      for t in $imp; do
        rm -rf "$dest/config/themes/$t.json" \
               "$dest/config/themes/ghostty/hekouwang-$t" \
               "$dest/config/themes/warp/${t//-/_}.yaml" \
               "$dest/config/themes/ecosystem/$t" \
               "$dest/config/themes/ecosystem/vscode/themes/hekouwang-$t-color-theme.json"
        printf "  ${d}- %s${o}\n" "$t"
      done
    fi
  fi

  if [ "$mode" = "pro" ]; then
    printf "\n${b}付费仓：保留全部付费件，换授权条款${o}\n"
    # ⛔ 付费仓绝不能带 MIT —— MIT 明确允许再分发和转售，
    #    等于你亲手授权买家合法把付费包挂出去。必须换成 LICENSE-PRO。
    rm -f "$dest/LICENSE"
    if [ -f "$dest/LICENSE-PRO.txt" ]; then
      mv "$dest/LICENSE-PRO.txt" "$dest/LICENSE.txt"
      printf "  ${d}~ LICENSE(MIT) → LICENSE.txt（付费包授权条款）${o}\n"
    fi
    # unlock.sh 是「拿 zip 的买家」用的；走 private 仓的人 git pull 就够了
    rm -f "$dest/unlock.sh"
    rm -f "$dest/CHANGELOG-OSS.md"   # 付费仓用完整版 CHANGELOG.md
    printf "  ${d}- unlock.sh（zip 渠道专用）${o}\n"
    # 两样只对**还没买**的人有意义的东西，不进付费仓：
    #   .github/FUNDING.yml → 仓库页顶部的 Sponsor 按钮，冲已经付过钱的买家弹很怪
    #   docs/index.html     → 落地页（含收款码和分档表），买家点进来看到有人
    #                         向他推销他已经买了的东西，跟上面换 README 是同一个道理
    # 落地页那一套：按 SITE_ONLY_PATHS 单一清单删，删完逐项验 —— 光删不验，
    # 漏一项照样零报错发出去（wechat-qr.png 就是这么漏进付费仓的）。
    local sp leak=0
    for sp in "${SITE_ONLY_PATHS[@]}"; do
      rm -rf "$dest/$sp"
      printf "  ${d}- %s${o}\n" "$sp"
    done
    for sp in "${SITE_ONLY_PATHS[@]}"; do
      if [ -e "$dest/$sp" ]; then
        printf "  ${r}✗ 落地页专用件没删掉：%s${o}\n" "$sp"; leak=1
      fi
    done
    if [ "$leak" = "1" ]; then
      printf "  ${r}→ 付费仓不该带只服务未购买者的东西${o}\n"; return 1
    fi
    printf "  ${g}✓ 落地页专用件已全部剔除（%s 项）${o}\n" "${#SITE_ONLY_PATHS[@]}"
    # 首页换成写给买家看的那份。公开版 README 开头就是免费/付费对比表和 ¥19.9 ——
    # 买家点进来看到有人向他推销他已经买的东西，很怪。
    # ⚠️ 但**不要**为此维护两份 30k 手册：正文只留一份母本（README.md），
    #    在这里改名进 docs/ 即可，双份必然漂移。
    if [ -f "$dest/README-PRO.md" ]; then
      mkdir -p "$dest/docs"
      mv "$dest/README.md" "$dest/docs/manual.md"
      # ⚠️ 中文版 README 也得跟着搬：它开头同样是免费/付费对比表 + ¥19.9。
      #    只搬英文那份的话，买家在首页旁边就看到一份向他推销他已经买了的东西的文档。
      [ -f "$dest/README.zh-CN.md" ] && mv "$dest/README.zh-CN.md" "$dest/docs/manual.zh-CN.md"
      # 付费首页也做成双语（跟免费仓一致）：英文那份当主 README.md、中文当 .zh-CN.md。
      # ⚠️ 顺序要紧——上面刚把免费版的 README.md / README.zh-CN.md 搬进 docs/manual*，
      #    这里的两个 mv 目标名才空出来，能安全落位。
      if [ -f "$dest/README-PRO.en.md" ]; then
        mv "$dest/README-PRO.en.md" "$dest/README.md"
        mv "$dest/README-PRO.md" "$dest/README.zh-CN.md"
      else
        mv "$dest/README-PRO.md" "$dest/README.md"   # 没英文版就退回单中文首页
      fi
      # ⛔ 手册原来在仓根，图片写的是 `src="docs/images/x.png"`。搬进 docs/ 之后
      #    这个相对路径会去找 `docs/docs/images/`，**12 张图全裂**（2026-07-23 实测踩到，
      #    买家先看到的就是一片碎图标）。挪文件必须同时改它内部的相对路径。
      #    只做这一处字面替换，不用正则改结构 —— 改结构容易顺手吃掉别的东西。
      # ⛔ 手册从仓根搬进 docs/ 之后，**所有相对路径都深了一层**，不只是图片。
      #    老代码只 sed 了 `src="docs/images/`，于是 12 张图修好了，而
      #    `](references/…)`、`](config/…)`、`](SKILL.md)`、`](LICENSE)` 这一二十条
      #    markdown 链接全指向不存在的位置 —— 点一条 404 一条，从来没人发现。
      #    这里统一改：图片走 images/（已在 docs/ 里），其余相对链接前面补 ../。
      for _m in "$dest/docs/manual.md" "$dest/docs/manual.zh-CN.md"; do
        [ -f "$_m" ] || continue
        python3 - "$_m" <<'PYLINK'
import re, sys
p = sys.argv[1]
src = open(p, encoding="utf-8").read()

# 图片：docs/images/x → images/x（手册自己已经在 docs/ 里了）
src = src.replace('src="docs/images/', 'src="images/')


def fix(m):
    label, target = m.group(1), m.group(2)
    # 外链 / 纯锚点 / 已经相对上级的，不动
    if re.match(r'^(https?:|mailto:|#|\.\./)', target):
        return m.group(0)
    # 两份手册互指：它们是 docs/ 里的邻居，改名不改层级
    if target in ("README.md", "README.zh-CN.md"):
        return f'[{label}]({{}})'.format(
            "manual.md" if target == "README.md" else "manual.zh-CN.md")
    # images/ 已经在 docs/ 里，别再往上跳
    if target.startswith("images/"):
        return m.group(0)
    return f'[{label}](../{target})'


src = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', fix, src)
open(p, "w", encoding="utf-8").write(src)
PYLINK
        # 付费仓的 MIT LICENSE 已被换成 LICENSE.txt（付费授权条款），
        # 手册里那句「代码：MIT，见 LICENSE」的链接得跟着改，否则指向一个不存在的文件。
        sed -i '' 's|(\.\./LICENSE)|(../LICENSE.txt)|g' "$_m"
      done
      printf "  ${d}~ README.md → docs/manual.md（中英两份，图片相对路径已跟着改），首页换成付费版${o}\n"
    fi
    return 0
  fi

  printf "\n${b}剔除付费包内容${o}\n"
  for p in "${PAID_PATHS[@]}"; do
    [ -e "$dest/$p" ] && rm -rf "$dest/$p" && printf "  ${d}- %s${o}\n" "$p"
  done
  # 品牌四套的 iTerm2 Profile 是付费内容；3 套社区配色留在开源版
  for t in $BRAND_THEMES; do
    rm -f "$dest/config/themes/$t.json"
    printf "  ${d}- %s（iTerm2 主题）${o}\n" "$t"
  done
  # 付费仓专用的授权条款与首页不进公开仓
  rm -f "$dest/LICENSE-PRO.txt" "$dest/README-PRO.md" "$dest/README-PRO.en.md"
  # 只服务付费仓首页的素材同理 —— 删完逐项验，别只删不验
  local po poleak=0
  for po in "${PRO_ONLY_PATHS[@]}"; do
    [ -e "$dest/$po" ] && rm -rf "$dest/$po" && printf "  ${d}- %s（付费首页专用）${o}\n" "$po"
  done
  for po in "${PRO_ONLY_PATHS[@]}"; do
    [ -e "$dest/$po" ] && { printf "  ${r}✗ 付费首页专用件没删掉：%s${o}\n" "$po"; poleak=1; }
  done
  [ "$poleak" = "1" ] && return 1
  # 公开仓的更新日志用精简版（只写用户看得见的变化，不写实现怎么调出来的）
  if [ -f "$dest/CHANGELOG-OSS.md" ]; then
    mv "$dest/CHANGELOG-OSS.md" "$dest/CHANGELOG.md"
    printf "  ${d}~ CHANGELOG-OSS.md → CHANGELOG.md（精简版）${o}\n"
  fi

  # ⛔ ghostty.config 里的 `theme = hekouwang-…` 指向的是**付费**配色文件
  #    （config/themes/ghostty/ 整个是付费件，上面刚剔掉）。原样发出去，
  #    装了 Ghostty 的免费用户会拿到一份指向不存在主题的配置。
  #    2026-07-23 查出来的：install.sh 的 Warp 分支有 `&& [ -d …/warp ]` 守卫，
  #    Ghostty 分支漏了，两边不一致导致的漏网。
  #    在这里注释掉，免费版就退回 Ghostty 自带配色 —— 而字体/毛玻璃/光标/回滚/
  #    ssh-terminfo 那些**非配色**设置照常生效（它们本来就不是付费能力）。
  if [ -f "$dest/config/ghostty.config" ]; then
    python3 - "$dest/config/ghostty.config" <<'PY'
import sys, pathlib, re
p = pathlib.Path(sys.argv[1]); s = p.read_text(encoding="utf-8")
s = re.sub(r'(?m)^theme = .*$',
           '# 配色主题属付费包（config/themes/ghostty/）。开源版不带，\n'
           '# 这里留空即用 Ghostty 自带配色；下面的字体/质感/回滚设置照常生效。\n'
           '# theme =',
           s, count=1)
p.write_text(s, encoding="utf-8")
PY
    printf "  ${d}~ ghostty.config 的 theme 行已注释（配色属付费件）${o}\n"
  fi

  # 开源仓的 .gitignore 要把付费件挡在外面 —— 买家把付费包解压进来后不会被误提交。
  # ⛔ 这份清单**从 PAID_PATHS 生成，不许再手写一份**：
  #    以前是硬编码副本，往 PAID_PATHS 加了 _import.py 之后两边就漂了（imported.py 写了两遍）。
  #    重复行只是难看，**漏行**才要命 —— 漏掉的那个付费件在公开仓里就是可提交状态，
  #    一次 git add -A 就把它推上 GitHub 了。
  {
    printf '\n# 付费包内容：不进公开仓（本段由 release.sh 从 PAID_PATHS 生成，别手改）\n'
    for p in "${PAID_PATHS[@]}"; do
      # ⛔ CHANGELOG.md 必须跳过：母版那份完整流水账确实属付费，但**这个文件名在
      #    开源树里被复用了** —— 上面刚把 CHANGELOG-OSS.md 改名成 CHANGELOG.md。
      #    照抄进 .gitignore 等于它自己忽略掉自己刚生成的精简版：文件在磁盘上、
      #    日志还打「~ CHANGELOG-OSS.md → CHANGELOG.md（精简版）」，看着完全成功，
      #    但 git 从头到尾没跟踪过它 —— 公开仓从建仓起就没有 CHANGELOG，零报错。
      #    2026-07-27 才发现。付费那份的真正防线是上面按 PAID_PATHS 逐个 rm 的那一层，
      #    .gitignore 只是第二道保险，对这个被复用的名字必须让位。
      [ "$p" = "CHANGELOG.md" ] && continue
      # 目录补尾斜杠，连里面的产物一起挡掉
      if [ -d "$SCRIPT_DIR/$p" ]; then printf '%s/\n' "$p"; else printf '%s\n' "$p"; fi
    done
    # 只列 PAID_PATHS 覆盖不到的：warp/ ghostty/ ecosystem/ 本身就在 PAID_PATHS 里，
    # imported.py 母版 .gitignore 已经写了并随树拷过来 —— 再写一遍就是刚修掉的那种重复。
    printf '\n# 付费色板生成出来的 iTerm2 Profile（色板不在＝这些也不该在）\n'
    for t in $BRAND_THEMES; do printf 'config/themes/%s.json\n' "$t"; done
  } >> "$dest/.gitignore"

  # ---- 同名碰撞门：.gitignore 不许挡掉开源版真要发的文件 ----
  # 上面那个 CHANGELOG.md 的坑属于一整类：**付费件和开源件重名**时，
  # 从 PAID_PATHS 生成的 ignore 行会连开源那份一起挡掉，而且是完全静默的
  # ——文件躺在磁盘上、导出日志一切正常，只有 git 不认它。
  # 判据是「开源版必须发的文件，不许在 .gitignore 里有精确匹配行」。
  # ⚠️ 以后往 PAID_PATHS 加东西，如果名字和这里任何一项撞上，这道门会当场红。
  # ⚠️ SKILL.md 从 2.4.0 起**不在这张表里**了 —— 它归付费档，开源树里压根没有这个文件。
  #    VERSION 顶上它的位置：版本号真相源，两档都必须发（update.sh 读它）。
  local must_ship=(CHANGELOG.md README.md README.zh-CN.md LICENSE.txt VERSION
                   lib/links.sh docs/index.html .github/FUNDING.yml)
  local ms clash=0
  for ms in "${must_ship[@]}"; do
    [ -e "$dest/$ms" ] || continue
    if grep -qxF "$ms" "$dest/.gitignore" 2>/dev/null; then
      printf "  ${r}✗ .gitignore 挡掉了开源版要发的 %s${o}\n" "$ms"; clash=1
    fi
  done
  if [ "$clash" = "1" ]; then
    printf "  ${r}→ 多半是 PAID_PATHS 里有个同名文件。开源树里这个名字是另一份东西，\n"
    printf "     照抄进 .gitignore 会静默吃掉它（CHANGELOG.md 就这么丢了半年）。${o}\n"
    return 1
  fi
  printf "  ${g}✓ .gitignore 没挡掉该发的文件${o}\n"

  # SkillHub 之类的平台拒收无扩展名文件，LICENSE 顺手改名
  [ -f "$dest/LICENSE" ] && mv "$dest/LICENSE" "$dest/LICENSE.txt"
  return 0
}

# ------------------------------------------------------------
# 验证：导出树在**它自己那一档**下是不是真的能跑
#
# ⛔ 这里原来写的是 `if (cd ... && python3 _generate.py | sed 's/^/  /'); then`——
#    **管道的退出码是 sed 的，恒为 0**，那道门从上线起没拦住过任何东西。
#    跟 --check 里 `git log -S` 不带 --pickaxe-regex 是同一个坑：
#    一个永远报平安的检查比没有检查更危险。
#    ⚠️ 改动本段后**必须种一个假故障**验证它真能红（拆掉 palette.sh 的存在性守卫
#       是现成的种法：干净树 exit 0，故障树 exit 1）。
# ------------------------------------------------------------
V_DEST=""; V_BAD=0
vrun() {   # vrun <说明> <相对 V_DEST 的目录> <命令...>
  local label="$1" dir="$2"; shift 2
  local out rc
  out="$(cd "$V_DEST/$dir" 2>/dev/null && "$@" 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ]; then
    printf "  ${g}✓${o} %s\n" "$label"
  else
    printf "  ${r}✗ %s ${d}(退出码 %s)${o}\n" "$label" "$rc"
    printf '%s\n' "$out" | tail -6 | sed 's/^/      /'
    V_BAD=1
  fi
}

verify_tree() {  # verify_tree <oss|pro> <目录> → 不通过返回 1
  local mode="$1" f syn=0 n
  V_DEST="$2"; V_BAD=0

  # 1) 语法：动过文件之后脚本本身仍要能解析
  for f in "$V_DEST"/*.sh; do
    [ -f "$f" ] || continue
    bash -n "$f" 2>/dev/null || { printf "  ${r}✗ 语法错误：%s${o}\n" "$(basename "$f")"; syn=1; V_BAD=1; }
  done
  [ "$syn" = "0" ] && printf "  ${g}✓${o} 全部脚本语法通过\n"

  if [ "$mode" = "oss" ]; then
    # 2) 生成器：缺 brand.py / pro.py 时只出 iTerm2，不崩、不留半成品
    vrun "生成器降级（只出 iTerm2）"           "config/themes" python3 _generate.py
    # 3) 付费入口必须**优雅**退场（打说明 + exit 0），不能因为缺文件炸掉
    # 三个付费入口脚本必须**不在**开源版里（以前是留成广告位，07-23 改成整个不发）。
    # 两份 SKILL 同理（2.4.0 起 Claude Code Skill 归付费档）：判据是**文件不存在**。
    # ⚠️ 判据是「文件不存在」，不是「跑起来会打印广告」—— 后者在文件被误发时同样是绿的。
    local gone=1 f
    for f in import.sh palette.sh workspace.sh SKILL.md SKILL.zh-CN.md; do
      if [ -e "$V_DEST/$f" ]; then
        printf "  ${r}✗ %s 不该出现在开源版${o}\n" "$f"; gone=0; V_BAD=1
      fi
    done
    [ "$gone" = "1" ] && printf "  ${g}✓${o} 付费入口脚本与两份 SKILL 都没跟出去\n"

    # ⛔ 版本号：SKILL.md 走了，免费版的版本号必须还有地方读。
    #    没这道门的话，update.sh 会安安静静打「版本未知」——功能没坏、没人报错，
    #    但用户看不出自己是哪一版，也就不知道该不该更新。这是典型的静默降级。
    if [ -s "$V_DEST/VERSION" ]; then
      printf "  ${g}✓${o} 版本号真相源在（VERSION = %s）\n" "$(tr -d '[:space:]' < "$V_DEST/VERSION")"
    else
      printf "  ${r}✗ 开源树里没有 VERSION —— update.sh 会打「版本未知」且零报错${o}\n"; V_BAD=1
    fi
    # 顺带盯住「谁在读 SKILL.md」：只扫**可执行文件**（.sh/.py），别扫 md ——
    # README 里正常会提到这个名字，扫文档只会制造假警报。
    # ⚠️ 两条免疫：
    #   1. release.sh 自己 —— 它随开源版分发，而 PAID_PATHS 里**本来就写着** SKILL.md
    #      （分档逻辑摆在明面上是卖点）。不排就是自指误报，天天红、最后没人看。
    #   2. 注释行 —— 判据是「有没有真去读它」，不是「有没有提到这个名字」。
    #      update.sh 里那句「⛔ 别改回读 SKILL.md」正是防复发的提醒，把它判红
    #      等于逼人删掉提醒。⚠️ 这跟密钥扫描**不许**豁免注释是相反的两件事：
    #      注释里的密钥照样泄漏，注释里的文件名不会被执行。
    local vsrc="" vf
    while IFS= read -r vf; do
      [ -n "$vf" ] || continue
      if sed 's/#.*//' "$vf" | grep -q 'SKILL\.md'; then vsrc="$vsrc $vf"; fi
    done <<EOF_VSRC
$(find "$V_DEST" -name .git -prune -o \( -name '*.sh' -o -name '*.py' \) -print 2>/dev/null | grep -v '/release\.sh$')
EOF_VSRC
    if [ -n "$vsrc" ]; then
      printf "  ${r}✗ 开源树里还有脚本在读 SKILL.md，而那个文件不在这一档${o}\n"
      printf '%s\n' $vsrc | sed "s|$V_DEST/|      |"
      V_BAD=1
    else
      printf "  ${g}✓${o} 没有脚本再从 SKILL.md 取东西\n"
    fi

    # ⛔ 付费 know-how 指纹扫描 —— 这次收紧分档的**回归闸门**。
    #    2026-07-23 之前免费仓里躺着多终端同步的完整实现、各 App 的格式踩坑手册，
    #    别人补三个生成器就复刻了付费档。删掉不算完，得有个门盯着别再长回来。
    #    ⚠️ 选的字串必须**只出现在付费实现里**：像 background-opacity 这种
    #    Ghostty 官方文档就有的公开键不算泄漏，放进来只会天天误报把门吵瞎。
    # 指纹表放在 docs/泄漏指纹.txt（INTERNAL_PATHS，两档都不发）。
    # ⛔ 别把字串写回本文件 —— release.sh 是发进公开仓的，写在这儿等于把
    #    「付费档在处理哪些东西」的路线图一起发出去，而且扫描会全部自指误报。
    # ⛔ 报平安要用**自己的**标志位。这里原来写的是 `[ "$V_BAD" = "1" ] || 打绿字`——
    #    V_BAD 是整个 verify_tree 共用的，前面任何一项挂了都会把这行绿字吞掉，
    #    看起来像「指纹扫描静默跳过了」。一个检查的结论不该被别的检查的结论污染。
    local SIGFILE="$SCRIPT_DIR/docs/泄漏指纹.txt" sig hits n_sig=0 sig_bad=0
    if [ -f "$SIGFILE" ]; then
      printf "  ${d}付费 know-how 指纹${o}\n"
      while IFS= read -r sig; do
        case "$sig" in ''|'#'*) continue ;; esac
        n_sig=$((n_sig + 1))
        hits="$(grep -rl --exclude-dir=.git -F "$sig" "$V_DEST" 2>/dev/null | sed "s|$V_DEST/||" | tr '\n' ' ')"
        if [ -n "$hits" ]; then
          printf "    ${r}✗ 泄漏在：%s${o}\n" "$hits"
          sig_bad=1; V_BAD=1
        fi
      done < "$SIGFILE"
      [ "$sig_bad" = "1" ] || printf "    ${g}✓${o} %s 个指纹字串一个都没出现\n" "$n_sig"
    fi

    # 本机导入的主题不许随产品分发（我试色留下的 rose-pine 之类）
    if [ -f "$SCRIPT_DIR/config/themes/palettes/imported.py" ]; then
      local leak=""
      for sig in $(python3 - "$SCRIPT_DIR/config/themes/palettes/imported.py" <<'PYI'
import ast, pathlib, re, sys
src = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
m = re.search(r"PALETTES\s*=\s*(\{.*\})\s*$", src, re.S)
print(" ".join(sorted(ast.literal_eval(m.group(1)))) if m else "")
PYI
); do
        [ -e "$V_DEST/config/themes/$sig.json" ] && leak="$leak $sig"
      done
      if [ -n "$leak" ]; then
        printf "    ${r}✗ 本机导入的主题泄漏：%s${o}\n" "$leak"; V_BAD=1
      else
        printf "    ${g}✓${o} 本机导入的主题没跟出去\n"
      fi
    fi
    # ⛔ 开源版的配置文件不许引用付费主题：ghostty.config 若留着未注释的
    #    `theme = hekouwang-…`，装了 Ghostty 的免费用户就拿到一份指向不存在主题的配置。
    if grep -qE '^theme = ' "$V_DEST/config/ghostty.config" 2>/dev/null; then
      printf "  ${r}✗ ghostty.config 还有生效的 theme= 行，但开源版没有配色文件${o}\n"
      grep -nE '^theme = ' "$V_DEST/config/ghostty.config" | sed 's/^/      /'
      V_BAD=1
    else
      printf "  ${g}✓${o} ghostty.config 未引用付费主题\n"
    fi

    # ⛔ 相对链接必须在**这一档里**解析得到。
    #    这道门以前只装在付费分支（手册搬进 docs/ 会把路径整体压深一层），
    #    开源分支没有 —— 而开源版才是链接最容易断的那一档：README 是母本，
    #    里面正常会提到 config/font.conf、references/terminals.md 这些**付费件**，
    #    剔掉之后每一条都成了 404，点一条死一条，从 2.0.0 起没人发现（07-27 补）。
    #    判据同付费分支：把路径解析一遍看文件在不在，别 grep 字符串。
    if python3 - "$V_DEST" <<'PYLNKOSS'
import pathlib, re, sys
root = pathlib.Path(sys.argv[1])
bad = []
mds = sorted(root.glob("*.md")) + sorted((root / "references").glob("*.md"))
for md in mds:
    for m in re.finditer(r'\[[^\]]+\]\(([^)#][^)]*)\)', md.read_text(encoding="utf-8")):
        t = m.group(1).split("#")[0]
        if not t or t.startswith(("http", "mailto")):
            continue
        if not (md.parent / t).exists():
            bad.append(f"{md.relative_to(root)} → {t}")
for b in bad[:12]:
    print("      " + b)
sys.exit(1 if bad else 0)
PYLNKOSS
    then
      printf "  ${g}✓${o} 文档相对链接全部解析得到\n"
    else
      printf "  ${r}✗ 上面这些链接在开源版里指向不存在的文件（多半是引用了付费件）${o}\n"; V_BAD=1
    fi
  else
    # 2') 付费仓反过来验：全量产物必须真的都在，付费能力必须真的能干活
    vrun "生成器出全量"                        "config/themes" python3 _generate.py
    vrun "palette.sh 推导器能跑"               "." ./palette.sh --from "#e08a5f" --name 验证用 --dry-run
    n="$(find "$V_DEST/config/themes" -maxdepth 1 -name '*.json' 2>/dev/null | wc -l | tr -d ' ')"
    if [ "$n" -ge 7 ] && [ -d "$V_DEST/config/themes/ghostty" ] \
       && [ -d "$V_DEST/config/themes/warp" ] && [ -d "$V_DEST/config/themes/ecosystem" ]; then
      printf "  ${g}✓${o} 全量产物齐（%s 套 iTerm2 主题 + ghostty/warp/ecosystem）\n" "$n"
    else
      printf "  ${r}✗ 全量产物不齐（iTerm2 主题 %s 套，期望 ≥7）${o}\n" "$n"; V_BAD=1
    fi
    # ⛔ 付费仓带 MIT = 亲手授权买家合法转售。这条必须能红。
    #    分三档而不是两档：`grep -q MIT 一个不存在的文件` 返回非 0，
    #    写成 if/else 会把「一个 LICENSE 都没有」误判成「已换成付费版」——
    #    那比带着 MIT 更糟（无条款 = 买家怎么用都没约束）。
    if [ ! -f "$V_DEST/LICENSE.txt" ]; then
      printf "  ${r}✗ 付费仓没有 LICENSE.txt —— LICENSE-PRO.txt 是不是丢了？${o}\n"; V_BAD=1
    elif grep -q "MIT License" "$V_DEST/LICENSE.txt" 2>/dev/null; then
      printf "  ${r}✗ 付费仓的 LICENSE.txt 还是 MIT —— 那等于授权买家合法转售${o}\n"; V_BAD=1
    else
      printf "  ${g}✓${o} 授权条款已换成付费版（非 MIT）\n"
    fi

    # ⛔ 首页必须是写给**买家**的那份。公开版 README 开头是免费/付费对比表 + ¥19.9，
    #    买家点进来被推销自己已买的东西 —— 这条用「有没有那张对比表」来判，能红。
    # ⚠️ 判据必须两种语言都认：README 主文件已改成英文，只认中文那句
    #    等于这道守卫永远不会响 —— 比没有守卫更糟（它还在装作有人看门）。
    if grep -qE "开源版（MIT · 免费）|Open source \(MIT · free\)" "$V_DEST/README.md" 2>/dev/null; then
      printf "  ${r}✗ 付费仓的 README 还是公开版（含免费/付费对比表）${o}\n"; V_BAD=1
    elif [ ! -f "$V_DEST/docs/manual.md" ]; then
      printf "  ${r}✗ 付费仓缺 docs/manual.md —— 正文被换掉后没有落脚点${o}\n"; V_BAD=1
    else
      printf "  ${g}✓${o} 首页是付费版，完整手册已移入 docs/\n"
    fi

    # ⛔ 图片相对路径：手册从仓根搬进 docs/ 后 `docs/images/…` 会全裂。
    #    别只数字符串「还有没有 docs/images/」—— 那只能抓这一种写法。
    #    逐条把引用解析成实际路径、验证文件真的在，才抓得住任何一种写错。
    local miss=0 total=0 img
    # ⛔ 判据必须是「把路径解析一遍看文件在不在」，不能 grep 字符串 ——
    #    grep 只能抓它认得的那一种写法，换个写法就漏（见 memory move-markdown-fix-relative-paths）。
    if python3 - "$V_DEST" <<'PYLNK'
import pathlib, re, sys
root = pathlib.Path(sys.argv[1])
bad = []
for md in [root / "README.md"] + sorted((root / "docs").glob("manual*.md")):
    if not md.is_file():
        continue
    for m in re.finditer(r'\[[^\]]+\]\(([^)#][^)]*)\)', md.read_text(encoding="utf-8")):
        t = m.group(1).split("#")[0]
        if not t or t.startswith(("http", "mailto")):
            continue
        if not (md.parent / t).exists():
            bad.append(f"{md.relative_to(root)} → {t}")
for b in bad[:12]:
    print("      " + b)
sys.exit(1 if bad else 0)
PYLNK
    then
      printf "  ${g}✓${o} 首页与手册的相对链接全部解析得到\n"
    else
      printf "  ${r}✗ 上面这些链接在导出后指向不存在的位置${o}\n"; V_BAD=1
    fi

    for f in "$V_DEST/README.md" "$V_DEST/docs/manual.md" "$V_DEST/docs/manual.zh-CN.md"; do
      [ -f "$f" ] || continue
      local base; base="$(dirname "$f")"
      while IFS= read -r img; do
        [ -n "$img" ] || continue
        case "$img" in http*|data:*) continue ;; esac
        total=$((total + 1))
        [ -f "$base/$img" ] || { printf "  ${r}✗ 图裂：%s 引用的 %s 不存在${o}\n" "$(basename "$f")" "$img"; miss=$((miss + 1)); }
      done <<EOF
$(grep -o 'src="[^"]*"' "$f" 2>/dev/null | sed 's/^src="//; s/"$//')
EOF
    done
    if [ "$miss" -gt 0 ]; then
      V_BAD=1
    else
      printf "  ${g}✓${o} 首页与手册的 %s 处图片引用全部指向真实文件\n" "$total"
    fi

    # 联系方式没填就发出去 = 买家出了问题找不到人，售后承诺落空。
    # 这是内容完整性问题不是泄漏，所以只警告不拦（否则第一次建仓就寸步难行）。
    if grep -q '`（待填）`' "$V_DEST/README.md" 2>/dev/null; then
      printf "  ${y}⚠ README 的联系方式还是「（待填）」—— 正式卖之前必须填${o}\n"
    fi
  fi

  # 4) 买家最先跑的两个只读入口（--dry-run 只打印不执行，theme.sh 无参 = 列表）
  vrun "theme.sh 主题列表"                     "." ./theme.sh
  vrun "install.sh --dry-run"                  "." ./install.sh --dry-run

  return $V_BAD
}

ensure_pages() {   # ensure_pages <repo> <branch> <path>
  local repo="$1" br="$2" p="$3" cur out rc
  cur="$(gh api "repos/$repo/pages" --jq '.source.branch + " " + .source.path' 2>/dev/null || echo "")"
  if [ "$cur" = "$br $p" ]; then
    printf "  ${g}✓${o} Pages 已是 %s %s\n" "$br" "$p"; return 0
  fi
  # 没开过用 POST 建站，开过但 source 不对用 PUT 改回来 —— 后者是关键：
  # 在网页 Settings 里手滑改一下 source，落地页当场 404，而母版毫不知情。
  if [ -z "$cur" ]; then
    out="$(gh api -X POST "repos/$repo/pages" -f "source[branch]=$br" -f "source[path]=$p" 2>&1)"; rc=$?
    [ "$rc" -eq 0 ] && { printf "  ${g}✓${o} Pages 已开启（%s %s）\n" "$br" "$p"; return 0; }
  else
    out="$(gh api -X PUT "repos/$repo/pages" -f "source[branch]=$br" -f "source[path]=$p" 2>&1)"; rc=$?
    [ "$rc" -eq 0 ] && { printf "  ${g}✓${o} Pages source 已改回 %s %s（原来是 %s）\n" "$br" "$p" "$cur"; return 0; }
  fi
  printf "  ${r}✗ Pages 设置失败${o}\n"; printf '%s\n' "$out" | sed 's/^/      /'
  return 1
}

apply_meta() {   # apply_meta <标签> <repo> <description> <topics 逗号分隔> <homepage>
  local label="$1" repo="$2" desc="$3" topics="$4" home="${5:-}"
  printf "\n${b}%s → %s${o}\n" "$label" "$repo"
  local cur_desc cur_topics cur_home t add=() del=()
  if ! cur_desc="$(gh repo view "$repo" --json description --jq '.description // ""' 2>/dev/null)"; then
    printf "  ${r}✗ 读不到这个仓（gh 没登录？仓库不存在？）${o}\n"; return 1
  fi
  if [ "$cur_desc" = "$desc" ]; then
    printf "  ${g}✓${o} description 已是最新\n"
  else
    # ⛔ 别把 gh 的错误 `>/dev/null 2>&1` 掉。原来就是这么写的，于是
    #    「description 超过 350 字符 → HTTP 422」这个真因被藏了整整四天，
    #    对外只打一句「更新失败」，谁也不知道失败在哪儿，线上一直是旧文案。
    #    一个不说原因的失败，跟一个永远报平安的检查一样没用。
    local out rc
    out="$(gh repo edit "$repo" --description "$desc" 2>&1)"; rc=$?
    if [ "$rc" -eq 0 ]; then
      printf "  ${g}✓${o} description 已更新\n"
    else
      printf "  ${r}✗ description 更新失败${o}\n"
      printf '%s\n' "$out" | sed 's/^/      /'
      return 1
    fi
  fi
  # homepage：空串是**有意的**（付费仓不挂），所以要跟线上比对后显式清空，
  # 不能「非空才设」—— 那样线上一旦被手工填过就永远清不掉，真相源又漏了一块。
  cur_home="$(gh repo view "$repo" --json homepageUrl --jq '.homepageUrl // ""' 2>/dev/null || echo "")"
  if [ "$cur_home" = "$home" ]; then
    printf "  ${g}✓${o} homepage 已是最新%s\n" "${home:+（${home}）}"
  else
    gh repo edit "$repo" --homepage "$home" >/dev/null 2>&1 \
      && printf "  ${g}✓${o} homepage 已更新%s\n" "${home:+ → $home}" \
      || { printf "  ${r}✗ homepage 更新失败${o}\n"; return 1; }
  fi
  # topics 要算双向差集：--add-topic 只会加，线上多出来的旧标签得显式删，
  # 否则「母版是唯一真相源」这句就不成立了（线上会慢慢攒出母版里没有的标签）。
  cur_topics="$(gh repo view "$repo" --json repositoryTopics --jq '[.repositoryTopics[]?.name]|join(",")' 2>/dev/null || echo "")"
  for t in ${topics//,/ }; do
    case ",$cur_topics," in *",$t,"*) ;; *) add+=("$t") ;; esac
  done
  for t in ${cur_topics//,/ }; do
    case ",$topics," in *",$t,"*) ;; *) del+=("$t") ;; esac
  done
  if [ "${#add[@]}" -eq 0 ] && [ "${#del[@]}" -eq 0 ]; then
    printf "  ${g}✓${o} topics 已是最新（%s 个）\n" "$(printf '%s' "$topics" | awk -F, '{print NF}')"
  else
    local args=()
    [ "${#add[@]}" -gt 0 ] && args+=(--add-topic "$(IFS=,; printf '%s' "${add[*]}")")
    [ "${#del[@]}" -gt 0 ] && args+=(--remove-topic "$(IFS=,; printf '%s' "${del[*]}")")
    gh repo edit "$repo" "${args[@]}" >/dev/null 2>&1 \
      && printf "  ${g}✓${o} topics 已更新（+%s / -%s）\n" "${#add[@]}" "${#del[@]}" \
      || { printf "  ${r}✗ topics 更新失败${o}\n"; return 1; }
  fi
  return 0
}

case "${1:-}" in
# ------------------------------------------------------------
--meta)
  # description / topics 不是文件，改这两样也要以母版为准（见文件头的说明）
  command -v gh >/dev/null 2>&1 || { printf "${r}✗ 需要 gh CLI${o}\n"; exit 1; }
  MBAD=0
  case "${2:-all}" in
    oss) apply_meta "开源版" "$OSS_REPO" "$OSS_DESC" "$OSS_TOPICS" "$OSS_HOMEPAGE" || MBAD=1
         ensure_pages "$OSS_REPO" "$OSS_PAGES_BRANCH" "$OSS_PAGES_PATH" || MBAD=1 ;;
    pro) apply_meta "付费仓" "$PRO_REPO" "$PRO_DESC" "$PRO_TOPICS" "$PRO_HOMEPAGE" || MBAD=1 ;;
    all) apply_meta "开源版" "$OSS_REPO" "$OSS_DESC" "$OSS_TOPICS" "$OSS_HOMEPAGE" || MBAD=1
         ensure_pages "$OSS_REPO" "$OSS_PAGES_BRANCH" "$OSS_PAGES_PATH" || MBAD=1
         apply_meta "付费仓" "$PRO_REPO" "$PRO_DESC" "$PRO_TOPICS" "$PRO_HOMEPAGE" || MBAD=1 ;;
    *)   printf "${r}用法：./release.sh --meta [oss|pro]${o}\n"; exit 1 ;;
  esac
  [ "$MBAD" = "0" ] && printf "\n${g}✓ 仓库元数据已与母版一致${o}\n" || { printf "\n${r}✗ 有仓没同步上${o}\n"; exit 1; }
  ;;

# ------------------------------------------------------------
--oss|--pro)
  MODE="${1#--}"
  DEST=""; UPDATE=0
  shift
  for a in "$@"; do
    case "$a" in
      --update) UPDATE=1 ;;
      -*)       printf "${r}未知参数：%s${o}\n" "$a"; exit 1 ;;
      *)        DEST="$a" ;;
    esac
  done
  [ "$MODE" = "oss" ] && MODE_CN="开源版" || MODE_CN="付费仓"
  [ -n "$DEST" ] || { printf "${r}用法：./release.sh --%s <目录> [--update]${o}\n" "$MODE"; exit 1; }

  if [ "$MODE" = "pro" ] && [ ! -f config/themes/palettes/brand.py ]; then
    printf "${r}✗ 没有 config/themes/palettes/brand.py，导不出付费仓${o}\n"; exit 1
  fi

  if [ "$UPDATE" = "1" ]; then
    # ⚠️ --update 会 rsync --delete，对着一个非 git 目录跑等于清空它。必须先确认是仓。
    [ -d "$DEST/.git" ] || {
      printf "${r}✗ %s 不是 git 仓（没有 .git）—— --update 拒绝对它下手${o}\n" "$DEST"
      printf "${d}  第一次建仓：去掉 --update，导进一个空目录。${o}\n"; exit 1; }
    # 目标仓有未提交改动的话，rsync 覆盖完就再也分不清哪些是这次导出带来的
    if [ -n "$(git -C "$DEST" status --porcelain 2>/dev/null)" ]; then
      printf "${r}✗ %s 有未提交的改动 —— 先提交或丢弃再来${o}\n" "$DEST"
      git -C "$DEST" status --short | head -5 | sed 's/^/      /'; exit 1
    fi
    STAGE="$(mktemp -d)"; trap 'rm -rf "$STAGE"' EXIT
    printf "${b}更新%s → %s${o}\n" "$MODE_CN" "$DEST"
  else
    if [ -e "$DEST" ] && [ -n "$(find "$DEST" -mindepth 1 -maxdepth 1 2>/dev/null | head -1)" ]; then
      printf "${r}✗ %s 已存在且非空 —— 不覆盖${o}\n" "$DEST"
      printf "${d}  想更新已有仓：./release.sh --%s %s --update${o}\n" "$MODE" "$DEST"; exit 1
    fi
    STAGE="$DEST"
    printf "${b}导出%s → %s${o}\n" "$MODE_CN" "$DEST"
  fi

  # ⚠️ 本脚本只有 set -u、没有 set -e —— build_tree 的返回值**必须显式接**，
  #    不接的话它里面的门 return 1 会被静默吞掉，等于那道门根本不存在
  #    （同 --oss 降级验证曾经被 `| sed` 吃掉退出码那次，见文件末尾注释）。
  if ! build_tree "$MODE" "$STAGE"; then
    printf "\n${r}✗ 导出中止：build_tree 有门没过（上面有红字）${o}\n"; exit 1
  fi

  printf "\n${b}验证：%s在它自己那一档下能不能跑${o}\n" "$MODE_CN"
  if verify_tree "$MODE" "$STAGE"; then
    printf "  ${g}✓ %s自成完整产品${o}\n" "$MODE_CN"
  else
    printf "\n  ${r}✗ %s有跑不通的地方，别发${o}\n" "$MODE_CN"; exit 1
  fi

  # 付费仓也要扫：它是 private，但买家读得到，同样不能夹带 IP / 家目录 / 密钥
  printf "\n${b}安全扫描（夹带检查）${o}\n"
  if scan_dir "$STAGE"; then
    printf "  ${g}✓ 没有 IP / 家目录 / 密钥 泄漏${o}\n"
  else
    printf "\n  ${r}✗ 发现不该带出去的内容，已中止 —— 清理后重跑${o}\n"; exit 1
  fi

  if [ "$UPDATE" = "1" ]; then
    # ⚠️ 必须 --exclude=.git，否则 --delete 会连目标仓的 git 历史一起删掉。
    #    也别用 cp -R：cp 不删目标里已经不该存在的文件，
    #    上一版的付费件 / 改名前的旧文件会变成幽灵永久留在仓里。
    # ⛔ 必须带 -c（按校验和比对），别用默认的 quick-check。
    #    rsync 默认「size 相同 且 mtime 相同 → 跳过」，而这两个条件在发版时**很容易同时成立**：
    #      · 版本号升位（2.2.0 → 2.3.0）、改一个字符的 typo —— 都是**等长**改动，size 不变
    #      · STAGE 是导出当下用 cp 现建的，DEST 若刚被 git reset/checkout 碰过，
    #        两边 mtime 会落在同一秒（mtime 比对精度就是秒）
    #    2026-07-27 实测：reset 完紧接着导出，SKILL.md 的 2.2.0→2.3.0 被静默跳过，
    #    rsync 退出码 0、导出日志全绿、git status 里那个文件干脆不出现 —— 看上去像「没改过」。
    #    119 个文件算校验和的代价可以忽略，别为省这点时间换一个静默漏发。
    rsync -ac --delete --exclude='.git' "$STAGE/" "$DEST/" || {
      printf "${r}✗ rsync 同步失败${o}\n"; exit 1; }
    printf "\n${g}═══ 已同步进 %s ═══${o}\n" "$DEST"
    printf "文件数：%s\n\n" "$(find "$DEST" -type f -not -path '*/.git/*' | wc -l | tr -d ' ')"
    printf "${b}改动如下（**没有自动提交**，你审完再提交）${o}\n"
    git -C "$DEST" status --short | head -30 | sed 's/^/  /'
    N="$(git -C "$DEST" status --porcelain | wc -l | tr -d ' ')"
    [ "$N" -gt 30 ] && printf "  ${d}…… 共 %s 处${o}\n" "$N"
    [ "$N" = "0" ] && printf "  ${d}（无改动，导出结果与仓内当前内容一致）${o}\n"
    printf "\n${d}  cd %s && git diff && git add -A && git commit && git push${o}\n" "$DEST"
  else
    printf "\n${g}═══ 完成 ═══${o}\n"
    printf "文件数：%s\n" "$(find "$DEST" -type f | wc -l | tr -d ' ')"
    printf "\n${d}下一步（⚠️ 一定要建**新仓**，别把母版仓改可见性 ——\n"
    printf "母版的 git 历史里有真实服务器信息，改可见性会连历史一起公开）：\n"
    printf "  cd %s && git init && git add -A && git commit -m 'initial'\n" "$DEST"
    if [ "$MODE" = "oss" ]; then
      printf "  gh repo create hekouwang-terminal-kit --public --source=. --push\n"
    else
      printf "  gh repo create hekouwang-terminal-kit-pro --private --source=. --push\n"
      printf "  ${d}买家按 GitHub 账号逐个加 collaborator（Settings → Collaborators）${o}\n"
    fi
    printf "${o}"
  fi
  ;;

# ------------------------------------------------------------
--pack)
  OUT="${2:-$HOME/Desktop/hekouwang-terminal-kit-付费包-$(date +%Y%m%d).zip}"
  [ -f config/themes/palettes/brand.py ] || {
    printf "${r}✗ 没有 config/themes/palettes/brand.py，无从打包${o}\n"; exit 1; }
  printf "${b}打包付费包 → %s${o}\n" "$OUT"
  # ⛔ 清单**从 PAID_PATHS 生成，不许再手写一份**。这里曾经是第三份硬编码副本
  #    （.gitignore 一份、build_tree 一份、这儿一份），2026-07-23 当天漂了两次：
  #    加 _import.py 没同步、把三个入口脚本改成付费也没同步 —— 结果 zip 缺 8 项，
  #    **包括 _apply_pro.sh**：走 zip 的买家拿到的 theme.sh 只能切 iTerm2，
  #    「多终端同步」这个招牌功能整个不在，而且零报错零提示。
  python3 - "$OUT" "$BRAND_THEMES" "${PAID_PATHS[@]}" <<'PY'
import os, sys, zipfile
out, themes, paid = sys.argv[1], sys.argv[2].split(), sys.argv[3:]
files = []
for p in paid:
    if os.path.isdir(p):
        # 目录整棵带上：ghostty / warp / ecosystem 里是**全部主题的**产物（含 3 套社区的），
        # 因为「多终端 + 全生态同色」本身就是付费能力，不只对品牌主题生效。
        for root, _dirs, fs in os.walk(p):
            files += [os.path.join(root, f) for f in sorted(fs) if not f.startswith('.')]
    else:
        files.append(p)
files += [f'config/themes/{t}.json' for t in themes]
# ⛔ VERSION 也要进包，但**绝不能加进 PAID_PATHS** —— 那个数组同时驱动「从公开仓剔除」，
#    而 VERSION 是两档都必须有的版本号真相源。这里显式补进出货清单。
#    实测过的坑：买家手里是 2.3.0 的免费仓（那一版还没有 VERSION 文件），解压 2.4.0 的包，
#    整棵树没有 VERSION → update.sh 静默打「版本未知」；就算有，也会 VERSION=2.3.0
#    而包内 SKILL.md 写 2.4.0，两个版本号当场打架。
files.append('VERSION')

# ⛔ 剔掉本机 ./import.sh 导进来的主题 —— 那是我个人试色，不随产品分发。
#    build_tree 已经为两个 git 子仓做过这件事，但 --pack 是**第三条**出货路径，
#    2026-07-23 实测漏掉了：zip 里躺着 16 个 rose-pine / claude-code-light 的文件。
#    每加一条出货路径就得想一遍「本机脏数据会不会跟着走」。
imported = "config/themes/palettes/imported.py"
if os.path.isfile(imported):
    import ast, re
    src = open(imported, encoding="utf-8").read()
    m = re.search(r"PALETTES\s*=\s*(\{.*\})\s*$", src, re.S)
    mine = set(ast.literal_eval(m.group(1))) if m else set()
    def is_mine(f):
        base = os.path.basename(f)
        return any(base in (f"{t}.json", f"hekouwang-{t}", f"{t.replace('-', '_')}.yaml",
                            f"hekouwang-{t}-color-theme.json")
                   or f"/ecosystem/{t}/" in f
                   for t in mine)
    files = [f for f in files if not is_mine(f)]
files = sorted(set(f for f in files if os.path.isfile(f)))
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
    for f in files:
        # ⚠️ 必须打 UTF-8 标记(0x800)，否则「速查卡.pdf」这类中文名解出来是乱码
        zi = zipfile.ZipInfo.from_file(f, f)
        zi.flag_bits |= 0x800
        zi.compress_type = zipfile.ZIP_DEFLATED
        with open(f, 'rb') as fh:
            z.writestr(zi, fh.read())
    z.writestr('把我解压到开源版目录里.txt',
               '解压到 hekouwang-terminal-kit 目录下（保持目录结构覆盖即可），\n'
               '然后跑：\n'
               '  cd config/themes && python3 _generate.py\n'
               '  cd ../.. && ./theme.sh v2-mihei\n'
               '就能用上品牌四套主题（含两套亮色）和跟随系统换肤。\n'
               '\n'
               '注：第一次切到某套品牌主题时，theme.sh 会顺手为 bat 建一次缓存\n'
               '（多花几秒）。这一步不能省 —— bat 认不出主题时不会报错，\n'
               '而是静默用它自己的默认配色，表现为「只有 cat 的颜色不对」。\n'
               '\n'
               '跟随系统深浅色：./theme.sh --auto\n'
               '速查卡：docs/速查卡.pdf（A4，可直接打印）\n')
print(f'  {len(files)} 个文件 → {out}')
PY
  # ⛔ 打完必须验：PAID_PATHS 里每一项都得在 zip 里。
  #    这道门是为「清单漂移」立的 —— 缺件时 zip 照样打得出来、照样报成功，
  #    买家解压后也不报错，只是功能悄悄少一半。没门就永远发现不了。
  if ! python3 - "$OUT" "${PAID_PATHS[@]}" <<'PYV'
import os, sys, zipfile
out, paid = sys.argv[1], sys.argv[2:] + ["VERSION"]   # VERSION 随包出货，见上面 files.append
names = set(zipfile.ZipFile(out).namelist())
miss = []
for q in paid:
    if os.path.isdir(q):
        if not any(n.startswith(q.rstrip("/") + "/") for n in names):
            miss.append(q + "/")
    elif os.path.isfile(q) and q not in names:
        miss.append(q)
if miss:
    print("\n".join("      " + m for m in miss))
    sys.exit(1)
PYV
  then
    printf "  ${r}✗ 付费包缺件（上面这些在 PAID_PATHS 里却没进 zip）${o}\n"
    rm -f "$OUT"
    exit 1
  fi
  printf "  ${g}✓${o} 验包：PAID_PATHS 每一项都在\n"
  printf "${g}✓ 付费包已打好${o}\n"
  printf "${d}买家拿到后：解压进开源版目录 → 重跑 _generate.py → ./theme.sh${o}\n"
  ;;

# ------------------------------------------------------------
# 打 tag —— 发版流程的最后一步
#
# ⚠️ 为什么要收进这个脚本：tag 以前是**手打的**，结果 2.3.0、2.4.0 三个仓一个都没打，
#    线上最后一个 tag 停在 07-23 的 v2.2.0，而 CHANGELOG 已经走到 2.4.0。
#    跟 description / topics 当初手点是同一个病：**只要有一样东西活在自动流程之外，
#    它就一定会漂**。版本号从 VERSION 取（唯一真相源），三仓一条命令打齐。
#
# ⛔ 绝不移动已存在的 tag。tag 指向别处时直接拒绝、让人自己判断 ——
#    `git tag -f` 会让已经 clone 过的人拿到跟你不一样的 v2.4.0，而且毫无提示。
# ------------------------------------------------------------
--tag)
  shift
  VER="$(tr -d '[:space:]' < "$SCRIPT_DIR/VERSION" 2>/dev/null)"
  if [ -z "$VER" ]; then
    printf "${r}✗ 读不到 VERSION${o}\n"; exit 1
  fi
  TAG="v$VER"
  printf "${b}打 tag %s（母版 + %s 个子仓）${o}\n" "$TAG" "$#"
  TAG_BAD=0
  for tdir in "$SCRIPT_DIR" "$@"; do
    tname="$(basename "$tdir")"
    if [ ! -d "$tdir/.git" ]; then
      printf "  ${r}✗ %s 不是 git 仓${o}\n" "$tname"; TAG_BAD=1; continue
    fi
    # ⛔ 脏树不许打：tag 指向的是**已提交的内容**，工作区里还躺着改动的话，
    #    这个 tag 代表的东西跟你以为的不是一回事。
    if [ -n "$(git -C "$tdir" status --porcelain 2>/dev/null)" ]; then
      printf "  ${r}✗ %s 工作区不干净，先提交再打 tag${o}\n" "$tname"; TAG_BAD=1; continue
    fi
    thead="$(git -C "$tdir" rev-parse HEAD)"
    if git -C "$tdir" rev-parse -q --verify "refs/tags/$TAG" >/dev/null 2>&1; then
      # ⚠️ 比的是 tag **解引用之后**指向的提交（附注 tag 自己是个对象，直接比会永远不等）
      tat="$(git -C "$tdir" rev-list -n1 "$TAG")"
      if [ "$tat" = "$thead" ]; then
        printf "  ${g}✓${o} %s 已有 %s 且指向 HEAD\n" "$tname" "$TAG"
      else
        printf "  ${r}✗ %s 的 %s 指向 %s，而 HEAD 是 %s${o}\n" \
               "$tname" "$TAG" "${tat:0:7}" "${thead:0:7}"
        printf "  ${d}  已发布的 tag 不移动。要么这版内容该重打个新版本号，要么这个 tag 打错了地方。${o}\n"
        TAG_BAD=1; continue
      fi
    else
      git -C "$tdir" tag -a "$TAG" -m "$TAG" || { printf "  ${r}✗ %s 打 tag 失败${o}\n" "$tname"; TAG_BAD=1; continue; }
      printf "  ${g}✓${o} %s 打上 %s（%s）\n" "$tname" "$TAG" "${thead:0:7}"
    fi
    # 推：已经在远端就静默通过（幂等）
    if git -C "$tdir" push -q origin "refs/tags/$TAG" 2>/dev/null; then
      printf "    ${d}→ 已推到 origin${o}\n"
    elif git -C "$tdir" ls-remote --tags origin "$TAG" 2>/dev/null | grep -q .; then
      printf "    ${d}→ 远端已有${o}\n"
    else
      printf "    ${r}✗ 推不上去（远端没有这个 tag）${o}\n"; TAG_BAD=1
    fi
  done
  if [ "$TAG_BAD" = "1" ]; then
    printf "\n${r}✗ 有仓没打上，别当成发完了${o}\n"; exit 1
  fi
  printf "\n${g}✓ %s 三仓齐了${o}\n" "$TAG"
  ;;

# ------------------------------------------------------------
# 发 GitHub Release —— 只发**公开仓**
#
# ⛔ 发布说明**不另写一份**，逐字取自 CHANGELOG-OSS.md 的同名小节。
#    分档产品每多一处对外文案，就多一处会漂到「在免费页面上吹付费能力」的地方
#    （公开仓 description 写「全链同步」就是这么来的）。CHANGELOG-OSS 已经守着分档口径、
#    而且本来就发在公开仓里，让它当唯一真相源，Release 页只是它的一个镜像。
# ⛔ 付费仓不发：它是 private，Release 页只有买家看得见，而买家 git pull 就有完整 CHANGELOG。
#
# 副标题也从 CHANGELOG-OSS 取：`## [2.4.0] · 副标题` —— 写在那儿而不是当命令行参数传，
# 是为了让「这一版对外怎么介绍」也留在版本库里，而不是打完命令就没了。
# ------------------------------------------------------------
--release)
  shift
  RVER="${1:-$(tr -d '[:space:]' < "$SCRIPT_DIR/VERSION" 2>/dev/null)}"
  if [ -z "$RVER" ]; then
    printf "${r}✗ 读不到版本号${o}\n"; exit 1
  fi
  RTAG="v$RVER"
  printf "${b}发 Release %s → %s${o}\n" "$RTAG" "$OSS_REPO"

  # ① 远端必须已经有这个 tag。Release 挂在 tag 上，tag 不在就等于凭空造一个引用。
  if ! gh api "repos/$OSS_REPO/git/ref/tags/$RTAG" >/dev/null 2>&1; then
    printf "  ${r}✗ 远端没有 %s —— 先跑 ./release.sh --tag${o}\n" "$RTAG"; exit 1
  fi
  printf "  ${g}✓${o} 远端 tag 在\n"

  # ② 幂等：已经发过就不动它（别覆盖已经有人读过的发布说明）
  if gh release view "$RTAG" --repo "$OSS_REPO" >/dev/null 2>&1; then
    printf "  ${g}✓${o} %s 已经发过了，不覆盖\n" "$RTAG"
    exit 0
  fi

  # ③ 从 CHANGELOG-OSS.md 抽正文与副标题；抽不到就拒绝 —— 宁可不发，也别发一个空说明
  RNOTES="$(mktemp)"; RTITLE=""
  if ! RTITLE="$(python3 - "$SCRIPT_DIR/CHANGELOG-OSS.md" "$RVER" "$RNOTES" <<'PYREL'
import re, sys, pathlib
src = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
ver = re.escape(sys.argv[2])
m = re.search(rf"^## \[{ver}\](?:\s*·\s*(.+?))?\s*$\n(.*?)(?=^## \[|\Z)", src, re.S | re.M)
if not m or not m.group(2).strip():
    sys.exit(1)
pathlib.Path(sys.argv[3]).write_text(m.group(2).strip() + "\n", encoding="utf-8")
print((m.group(1) or "").strip())
PYREL
  )"; then
    printf "  ${r}✗ CHANGELOG-OSS.md 里没有 [%s] 这一节（或它是空的）${o}\n" "$RVER"
    rm -f "$RNOTES"; exit 1
  fi
  [ -n "$RTITLE" ] && RTITLE="$RTAG · $RTITLE" || RTITLE="$RTAG"
  printf "  ${d}标题：%s（%s 行说明）${o}\n" "$RTITLE" "$(wc -l < "$RNOTES" | tr -d ' ')"

  if gh release create "$RTAG" --repo "$OSS_REPO" --title "$RTITLE" --notes-file "$RNOTES"; then
    printf "  ${g}✓${o} 已发布\n"
  else
    printf "  ${r}✗ 发布失败（上面是 gh 的原始报错）${o}\n"; rm -f "$RNOTES"; exit 1
  fi
  rm -f "$RNOTES"
  ;;

# ------------------------------------------------------------
--check)
  printf "${b}shell 脚本自检${o}\n"
  LINT_BAD=0
  for f in "$SCRIPT_DIR"/*.sh "$SCRIPT_DIR"/*/*.sh; do
    [ -f "$f" ] || continue
    bash -n "$f" 2>/dev/null || { printf "  ${r}✗ 语法错误：%s${o}\n" "$(basename "$f")"; LINT_BAD=1; }
  done
  # ⛔ `$VAR` 后面直接跟全角字符（如 `$FOO）`）会被并进变量名 ——
  #    在中文文案里极容易写出来，报错是 `unbound variable` 且**整个脚本当场退出**，
  #    后面的检查全不跑。开发这版时同一个坑连踩三次（theme.sh / doctor.sh ×2 / sync.sh），
  #    所以固化成发布前的硬检查。正确写法：${VAR}。
  if python3 - "$SCRIPT_DIR" <<'PY'
import pathlib, re, sys
bad = []
for f in sorted(pathlib.Path(sys.argv[1]).rglob('*.sh')):
    for i, l in enumerate(f.read_text(encoding='utf-8').splitlines(), 1):
        if l.lstrip().startswith('#'):
            continue
        for m in re.finditer(r'\$[A-Za-z_][A-Za-z0-9_]*', l):
            nxt = l[m.end():m.end() + 1]
            if nxt and ord(nxt) > 127:
                bad.append(f'{f.relative_to(sys.argv[1])}:{i}: {m.group(0)}{nxt} → 应写成 ${{{m.group(0)[1:]}}}{nxt}')
for b in bad:
    print('      ' + b)
sys.exit(1 if bad else 0)
PY
  then
    printf "  ${g}✓ 无「\$变量 紧跟全角字符」（会被当成变量名的一部分）${o}\n"
  else
    printf "  ${r}✗ 上面这些会导致 unbound variable 并让脚本当场退出${o}\n"; LINT_BAD=1
  fi
  [ "$LINT_BAD" = "0" ] && printf "  ${g}✓ 全部脚本语法通过${o}\n"

  # ---- 词条表：en / zh 双向差集 -------------------------------
  # ⛔ 清单同源：只加英文不加中文，中文用户看到的是一句英文（会静默回落，不报错）；
  #    只加中文不加英文，默认语言反而看到 key。两边都要盯，而且要**双向**差集 ——
  #    只查一边等于只有半扇门（跟 --meta 的 topics 是同一个教训）。
  printf "\n${b}词条表对齐（lib/i18n）${o}\n"
  if python3 - "$SCRIPT_DIR" <<'PYI18N'
import pathlib, re, sys
root = pathlib.Path(sys.argv[1]) / "lib" / "i18n"
if not root.is_dir():
    print("      lib/i18n 不存在"); sys.exit(1)


def keys(f):
    if not f.is_file():
        return set()
    txt = f.read_text(encoding="utf-8")
    return (set(re.findall(r'^([A-Z][A-Z0-9_]*)=', txt, re.M))
            | set(re.findall(r'^(blk_[a-z0-9_]+)\(\)', txt, re.M)))


bad = 0
mods = sorted({f.name for d in root.iterdir() if d.is_dir() for f in d.glob("*.sh")})
for mod in mods:
    en, zh = keys(root / "en" / mod), keys(root / "zh" / mod)
    for miss, where in ((en - zh, "zh"), (zh - en, "en")):
        if miss:
            bad = 1
            print(f"      {mod}: {where} 缺 {', '.join(sorted(miss))}")

# Python 侧同理
sys.path.insert(0, str(pathlib.Path(sys.argv[1]) / "lib"))
try:
    import i18n as m
    pen, pzh = set(m.MESSAGES["en"]), set(m.MESSAGES["zh"])
    for miss, where in ((pen - pzh, "zh"), (pzh - pen, "en")):
        if miss:
            bad = 1
            print(f"      i18n.py: {where} 缺 {', '.join(sorted(miss))}")
except Exception as e:
    bad = 1
    print(f"      i18n.py 读不出来：{e}")
sys.exit(bad)
PYI18N
  then
    printf "  ${g}✓ en / zh 词条一一对应（含 Python 侧）${o}\n"
  else
    printf "  ${r}✗ 上面这些词条只有一种语言有 —— 补齐再发${o}\n"; LINT_BAD=1
  fi

  # ---- 默认语言路径上不许残留中文 -----------------------------
  # 默认是英文，所以英文词条表里出现中日韩字符，多半是漏翻的一条。
  printf "\n${b}英文词条表里的漏翻${o}\n"
  if CJK="$(grep -rn '[一-龥]' "$SCRIPT_DIR/lib/i18n/en/" 2>/dev/null | grep -v '^\s*#' | grep -vE ':[[:space:]]*#' | grep -vE '禾口王|中文|简体')"; then
    printf '%s\n' "$CJK" | sed 's|^|      |' | head -10
    printf "  ${r}✗ 英文词条表里有中文${o}\n"; LINT_BAD=1
  else
    printf "  ${g}✓ 英文词条表无漏翻${o}\n"
  fi

  # ---- 仓库 description 长度（GitHub 硬上限 350）--------------
  # 超一个字符，gh repo edit 整次调用报 HTTP 422、什么都不改。放在这里是为了
  # **改文案的当下就红**，而不是等你 --meta 推的时候才发现（那时候你多半以为推成功了）。
  printf "\n${b}仓库 description 长度（上限 350）${o}\n"
  DESC_BAD=0
  for pair in "OSS_DESC:$OSS_DESC" "PRO_DESC:$PRO_DESC"; do
    dname="${pair%%:*}"; dval="${pair#*:}"
    dlen="$(printf '%s' "$dval" | wc -m | tr -d ' ')"
    if [ "$dlen" -gt 350 ]; then
      printf "  ${r}✗ %s = %s 字符，超 %s${o}\n" "$dname" "$dlen" "$((dlen-350))"; DESC_BAD=1
    else
      printf "  ${g}✓${o} %s = %s 字符\n" "$dname" "$dlen"
    fi
  done
  [ "$DESC_BAD" = "1" ] && LINT_BAD=1

  # ---- 版本号：VERSION 是真相源，SKILL frontmatter 必须跟它相等 ----
  # 2.4.0 起 SKILL.md 归付费档，所以版本号真相源挪到了仓根的 VERSION（两档都发）。
  # 但 SKILL.md 的 frontmatter 仍**必须**有 version（Claude Code / SkillHub 都读它），
  # 于是又出现了一份副本 —— 这个仓已经因为「硬编码副本漂掉」栽过四次，直接补门。
  # ⛔ 判据是「每一份都等于 VERSION」，不是「有没有 version 这一行」。
  printf "\n${b}版本号一致性（VERSION 是真相源）${o}\n"
  VER_SRC="$(tr -d '[:space:]' < "$SCRIPT_DIR/VERSION" 2>/dev/null)"
  if [ -z "$VER_SRC" ]; then
    printf "  ${r}✗ 仓根没有 VERSION 或它是空的${o}\n"; LINT_BAD=1
  else
    printf "  ${d}真相源：%s${o}\n" "$VER_SRC"
    VER_BAD=0
    for f in SKILL.md SKILL.zh-CN.md; do
      [ -f "$SCRIPT_DIR/$f" ] || continue     # 中文镜像没 frontmatter 时跳过
      grep -q '^version:' "$SCRIPT_DIR/$f" || continue
      fv="$(grep -m1 '^version:' "$SCRIPT_DIR/$f" | awk '{print $2}' | tr -d '[:space:]')"
      if [ "$fv" != "$VER_SRC" ]; then
        printf "  ${r}✗ %s 的 frontmatter 是 %s，VERSION 是 %s${o}\n" "$f" "$fv" "$VER_SRC"; VER_BAD=1
      fi
    done
    if [ "$VER_BAD" -eq 0 ]; then
      printf "  ${g}✓ SKILL frontmatter 与 VERSION 一致${o}\n"
    else
      printf "  ${r}→ 升版本改 VERSION，SKILL frontmatter 要跟着改${o}\n"; LINT_BAD=1
    fi
  fi

  # ---- 落地页地址：一处定义、七处引用，别漂 -------------------
  # lib/links.sh 是唯一真相源。README（中英）、FUNDING.yml、落地页自己都得跟它一致，
  # 否则会出现「换肤回执把人送到 A、README 送到 B」这种没人会发现的分叉。
  # ⛔ 判据是「文件里出现的每一个 huiyonghkw.github.io 地址都等于真相源」，
  #    不是「文件里含有真相源」—— 后者在多出一个旧地址时照样报绿（半扇门）。
  printf "\n${b}落地页地址一致性（lib/links.sh 是真相源）${o}\n"
  URL_SRC="$(sed -n 's/^HKW_URL_BUY="\(.*\)"$/\1/p' "$SCRIPT_DIR/lib/links.sh" 2>/dev/null)"
  if [ -z "$URL_SRC" ]; then
    printf "  ${r}✗ lib/links.sh 里读不出 HKW_URL_BUY${o}\n"; LINT_BAD=1
  else
    printf "  ${d}真相源：%s${o}\n" "$URL_SRC"
    URL_BAD=0
    for f in ".github/FUNDING.yml" "docs/index.html" "README.md" "README.zh-CN.md"; do
      [ -f "$SCRIPT_DIR/$f" ] || { printf "  ${r}✗ %s 不见了${o}\n" "$f"; URL_BAD=1; continue; }
      # 抓出这个文件里所有指向 Pages 站的地址
      HITS="$(grep -oE 'https://huiyonghkw\.github\.io[^ )"'"'"'`<]*' "$SCRIPT_DIR/$f" 2>/dev/null | sort -u)"
      if [ -z "$HITS" ]; then
        printf "  ${r}✗ %s 里没有落地页地址${o}\n" "$f"; URL_BAD=1; continue
      fi
      while IFS= read -r u; do
        [ -n "$u" ] || continue
        if [ "$u" != "$URL_SRC" ]; then
          printf "  ${r}✗ %s 指向 %s${o}\n" "$f" "$u"; URL_BAD=1
        fi
      done <<EOF_URLS
$HITS
EOF_URLS
    done
    if [ "$URL_BAD" -eq 0 ]; then
      printf "  ${g}✓ 四处引用与真相源一致${o}\n"
    else
      printf "  ${r}→ 改 lib/links.sh 之后，上面这些文件要一起改${o}\n"; LINT_BAD=1
    fi
  fi

  printf "\n${b}扫当前工作区（不含 git 历史）${o}\n"
  if scan_dir "$SCRIPT_DIR"; then
    printf "  ${g}✓ 工作区干净${o}\n"
  fi
  printf "\n${b}扫 git 历史${o}\n"
  BADC=0
  # ⚠️ `git log -S` 默认是**字面量**匹配，传正则进去会静默匹配不到 ——
  #    一个永远报平安的安全检查比没有检查更危险。必须带 --pickaxe-regex。
  for pat in '([0-9]{1,3}\.){3}[0-9]{1,3}' '/Users/[a-z]'; do
    n="$(git log --oneline --all --pickaxe-regex -S"$pat" 2>/dev/null | wc -l | tr -d ' ')"
    if [ "$n" -gt 0 ]; then
      printf "  ${y}⚠ %s 个提交含 %s${o}\n" "$n" "$pat"
      git log --oneline --all --pickaxe-regex -S"$pat" 2>/dev/null | head -5 | sed 's/^/      /'
      BADC=$((BADC+n))
    fi
  done
  if [ "$BADC" -gt 0 ]; then
    printf "\n  ${r}→ 所以不能把本仓改成 public。${o}\n"
    printf "  ${d}用 ./release.sh --oss 导出干净副本，在**新仓**里 git init。${o}\n"
  else
    printf "  ${g}✓ 历史也干净${o}\n"
  fi
  ;;

*)
  sed -n '5,13p' "$0" | sed 's/^#\{1,\} \{0,1\}//'
  ;;
esac
