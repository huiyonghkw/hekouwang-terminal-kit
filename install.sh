#!/bin/bash
# ============================================================
# hekouwang-terminal-kit — 一键安装
#
# ⚠️ 对外文案（help / dry-run 清单 / 每一条进度）全在 lib/i18n/{en,zh}/install.sh，
#    这里只留逻辑。`./install.sh -h` 打的就是词条表里的 blk_install_help，
#    不再是「打印本文件头部注释」那套 —— 双语之后那条路必然漂。
#
# 幂等：重复执行安全，已装的跳过。覆盖 ~/.zshrc 前先备份成 ~/.zshrc.bak.<时间戳>。
# 已经在用自己的 .zshrc 的人应该先跑 ./migrate.sh，不是直接装。
# ============================================================
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME="$HOME/.config/hekouwang-terminal"
ECO_DIR="$SCRIPT_DIR/config/themes/ecosystem"
DEFAULT_THEME="${THEME:-}"

# shellcheck disable=SC1091
. "$SCRIPT_DIR/lib/i18n.sh"
hkw_i18n_init install "$@"
eval set -- "$HKW_ARGS"

DRY=0
for a in "$@"; do
  case "$a" in
    --dry-run|-n) DRY=1 ;;
    -h|--help) blk_install_help; exit 0 ;;
  esac
done

say()  { printf "\n\033[1;35m▶ %s\033[0m\n" "$(t "$@")"; }
info() { printf "  %s\n" "$(t "$@")"; }
dim()  { printf "\033[2m  %s\033[0m\n" "$(t "$@")"; }

# 没指定主题时，按「品牌包在不在」自动挑默认
if [ -z "$DEFAULT_THEME" ]; then
  for t_ in v2-mihei tokyo-night catppuccin-mocha gruvbox-dark; do
    [ -f "$SCRIPT_DIR/config/themes/$t_.json" ] && { DEFAULT_THEME="$t_"; break; }
  done
fi

# ============================================================
# --dry-run：把要做的事原样列一遍再退出
# ============================================================
if [ "$DRY" = "1" ]; then
  printf "\033[1;34m%s\033[0m\n" "$(t M_INSTALL_DRY_HEAD)"
  blk_install_dryrun
  printf "\n\033[1;33m%s\033[0m\n" "$(t M_INSTALL_DRY_TAIL)"
  exit 0
fi

# ---- 0. 语言：显式给了就用；没给、是交互终端、以前也没记过 → 问一次并记住 ----
# 非交互（CI / 管道）绝不卡在这里等输入：直接走默认英文。
if [ -z "${HKW_LANG_EXPLICIT:-}" ] && [ ! -f "$HKW_LANG_FILE" ] && [ -t 0 ]; then
  printf "\n%s" "$(t M_LANG_PROMPT)"
  read -r _ans </dev/tty || _ans=""
  case "$_ans" in
    2|zh*|ZH*|c|C|中文) HKW_LANG=zh ;;
    *)                  HKW_LANG=en ;;
  esac
  export HKW_LANG
  hkw_i18n_load common; hkw_i18n_load install    # 换了语言，词条表重载
  echo
fi
hkw_lang_persist

# ---- 0b. 国内镜像（可选）----
# 国内网络连不上 GitHub / ghcr.io 时（报错 portable-ruby 下载失败、
# SSL_ERROR_SYSCALL 连 pkg-containers.githubusercontent.com:443），
# 用 CN=1 ./install.sh 启用清华 TUNA 镜像，全程走国内源。
MIRROR="https://mirrors.tuna.tsinghua.edu.cn"
if [ "${CN:-0}" = "1" ]; then
  say M_INSTALL_CN_MIRROR
  export HOMEBREW_API_DOMAIN="$MIRROR/homebrew-bottles/api"
  export HOMEBREW_BOTTLE_DOMAIN="$MIRROR/homebrew-bottles"
  export HOMEBREW_BREW_GIT_REMOTE="$MIRROR/git/homebrew/brew.git"
  export HOMEBREW_CORE_GIT_REMOTE="$MIRROR/git/homebrew/homebrew-core.git"
  export HOMEBREW_NO_AUTO_UPDATE=1
fi

# CN 模式下给 github raw 链接套一层代理（绕开 raw.githubusercontent.com 连不上）
gh() { if [ "${CN:-0}" = "1" ]; then echo "https://ghfast.top/$1"; else echo "$1"; fi; }

# ---- 1. Homebrew ----
if ! command -v brew >/dev/null; then
  say M_INSTALL_BREW
  # 官方安装脚本本身认上面设的 HOMEBREW_*_GIT_REMOTE，CN 模式只需用代理拉到脚本即可
  /bin/bash -c "$(curl -fsSL "$(gh https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)")"
fi
# 把 brew 放进当前 shell PATH —— Apple Silicon=/opt/homebrew，Intel=/usr/local，二者都试
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [ -x "$_brew" ] && eval "$("$_brew" shellenv)" && break
done
BREW_PREFIX="$(brew --prefix)"   # 后续所有 share/ 路径都用它，不写死 /opt/homebrew

# ---- 2. iTerm2 + 字体 ----
# 字体全部走 brew cask —— 都是自由许可（OFL），可以放心分发和批量装。
# ⚠️ 1.x 版这里从第三方仓库拉 Operator Mono（H&Co 商业字体）。那是盗版分发，
#    自用尚属灰色，随产品分发就是明确的侵权。2.0 起换成 Maple Mono NF CN：
#    SIL OFL-1.1，免费可商用，而且自带 Nerd 图标 + 中文等宽，一套顶原来两套。
#    自己买过 Operator Mono 授权的：改 config/themes/_generate.py 的 NORMAL_FONT。
say M_INSTALL_ITERM_FONTS
# ⚠️ 「App 已经在 /Applications 里但不是 brew 装的」是很常见的情况（手动下载装的）。
#    brew 这时会拒绝安装并报错，但那不是失败 —— 东西本来就在。
#    直接报「装失败」会把人吓一跳，所以这里分三种情况说清楚。
cask_app_path() {
  case "$1" in
    iterm2) echo "/Applications/iTerm.app" ;;
    ghostty) echo "/Applications/Ghostty.app" ;;
    *) echo "" ;;                       # 字体类 cask 没有对应 App
  esac
}
for cask in iterm2 font-maple-mono-nf-cn font-symbols-only-nerd-font font-jetbrains-mono; do
  if brew list --cask "$cask" >/dev/null 2>&1; then
    info M_PKG_SKIP "$cask"
    continue
  fi
  APP="$(cask_app_path "$cask")"
  if [ -n "$APP" ] && [ -d "$APP" ]; then
    info M_INSTALL_CASK_SKIP_MANUAL "$cask"
    continue
  fi
  if brew install --cask "$cask"; then
    info M_PKG_OK "$cask"
  else
    info M_INSTALL_CASK_FAIL "$cask"
  fi
done

# ---- 3. CLI 全家桶 ----
# set -e 下若一行装 N 个包、中间一个失败会整脚本退出，前功尽弃。
# 改成逐个装、单包失败只记录不中断，最后汇总没装上的。
say M_INSTALL_CLI
FAILED_PKGS=""
for pkg in starship eza bat fzf fd zoxide ripgrep atuin fnm tmux git-delta \
           zsh-autosuggestions zsh-syntax-highlighting; do
  if brew list --formula "$pkg" >/dev/null 2>&1; then
    info M_PKG_SKIP "$pkg"
  elif brew install "$pkg"; then
    info M_PKG_OK "$pkg"
  else
    info M_INSTALL_PKG_FAIL "$pkg"
    FAILED_PKGS="$FAILED_PKGS $pkg"
  fi
done
[ -n "$FAILED_PKGS" ] && info M_INSTALL_PKG_FAILED_SUM "$FAILED_PKGS"

# ---- 4. oh-my-zsh ----
# KEEP_ZSHRC=yes：禁止 omz 安装器自己生成 .zshrc（由本脚本第 5 步统一部署）
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  say M_INSTALL_OMZ
  # 显式传 ZSH，防止当前 shell 已导出的 $ZSH（指向别的目录）干扰安装器
  # CN 模式下从 gitee 镜像拉 oh-my-zsh 主体
  [ "${CN:-0}" = "1" ] && export REMOTE="https://gitee.com/mirrors/oh-my-zsh.git"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes ZSH="$HOME/.oh-my-zsh" \
    sh -c "$(curl -fsSL "$(gh https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)")" "" --unattended
fi

# ---- 5. 配置文件 ----
say M_INSTALL_CONFIG
mkdir -p ~/.config "$RUNTIME"
cp "$SCRIPT_DIR/config/starship.toml" ~/.config/starship.toml

# Ghostty（装了才配，没装静默跳过 —— 它是可选终端，不是必需件）。
# 必须排在 theme.sh 之前：theme.sh 要靠这些文件在位才切得动 Ghostty 那一半。
if [ -d /Applications/Ghostty.app ]; then
  mkdir -p ~/.config/ghostty/themes
  # 配色主题是付费件；开源版没有这个目录，跳过即可（config 本身照常部署 ——
  # 字体/毛玻璃/光标/回滚/ssh-terminfo 都不是付费能力）。
  # ⚠️ 跟下面 Warp 分支的守卫保持一致：以前这里没守卫，两边不一致，
  #    结果开源版把一份指向不存在主题的 config 写给了用户（2026-07-23 修）。
  if [ -d "$SCRIPT_DIR/config/themes/ghostty" ]; then
    cp "$SCRIPT_DIR/config/themes/ghostty/"hekouwang-* ~/.config/ghostty/themes/ 2>/dev/null || true
  fi
  # 手改过的 config 先备份再覆盖（认自家生成的标记行；没标记就是用户自己的，备份保平安）
  # ⚠️ 标记必须用 ASCII 的 `hekouwang-terminal-kit`，不能用中文标题 ——
  #    双语之后中文那行会随语言变，一变这里就永远认不出自家文件、每次装都多备份一份。
  if [ -f ~/.config/ghostty/config ] && ! grep -q "hekouwang-terminal-kit" ~/.config/ghostty/config; then
    cp ~/.config/ghostty/config ~/.config/ghostty/config.bak."$(date +%Y%m%d%H%M%S)"
    info M_INSTALL_GHOSTTY_BAK
  fi
  cp "$SCRIPT_DIR/config/ghostty.config" ~/.config/ghostty/config
  info M_INSTALL_GHOSTTY_OK
fi


# Warp（装了才配）
if [ -d /Applications/Warp.app ] && [ -d "$SCRIPT_DIR/config/themes/warp" ]; then
  mkdir -p ~/.warp/themes
  cp "$SCRIPT_DIR/config/themes/warp/"*.yaml ~/.warp/themes/ 2>/dev/null || true
  info M_INSTALL_WARP_OK
fi

# ---- 6. bat 主题：一次装全套，之后换肤只改环境变量不重建缓存 ----
# bat cache --build 有几秒开销，放在换肤流程里每次都跑太慢。
# 所以这里一次性把所有主题装进去建一次缓存，theme.sh 只改 BAT_THEME。
if command -v bat >/dev/null 2>&1; then
  say M_INSTALL_BAT
  BAT_THEMES="$(bat --config-dir)/themes"
  if [ -n "$BAT_THEMES" ] && mkdir -p "$BAT_THEMES" 2>/dev/null; then
    n=0
    for eco in "$ECO_DIR"/*/; do
      [ -f "$eco/bat.tmTheme" ] || continue
      cp "$eco/bat.tmTheme" "$BAT_THEMES/hekouwang-$(basename "$eco").tmTheme"
      n=$((n+1))
    done
    if bat cache --build >/dev/null 2>&1; then
      info M_INSTALL_BAT_OK "$n"
    else
      info M_INSTALL_BAT_CACHE_FAIL
    fi
  fi
else
  info M_INSTALL_BAT_MISSING
fi

# ---- 7. Dynamic Profile + 生态配色（一条命令全套上）----
# theme.sh 会：拷 iTerm2 Profile、部署 current/ 生态配色、切 Ghostty。
say M_INSTALL_THEME "$DEFAULT_THEME"
bash "$SCRIPT_DIR/theme.sh" "$DEFAULT_THEME"

# ---- 8. 挂进 git / tmux（都先备份，且只加一行）----
# ⚠️ 这两处改的是**用户自己的**配置文件，所以：先备份、只加一行、可被 uninstall.sh 精确摘掉。
if command -v git >/dev/null 2>&1; then
  if git config --get-all include.path 2>/dev/null | grep -q hekouwang-terminal; then
    info M_INSTALL_GIT_SKIP
  else
    [ -f ~/.gitconfig ] && cp ~/.gitconfig ~/.gitconfig.bak."$(date +%Y%m%d%H%M%S)"
    git config --global --add include.path "$RUNTIME/current/delta.gitconfig"
    info M_INSTALL_GIT_OK
  fi
fi
if [ -f ~/.tmux.conf ] && grep -q hekouwang-terminal ~/.tmux.conf; then
  info M_INSTALL_TMUX_SKIP
else
  [ -f ~/.tmux.conf ] && cp ~/.tmux.conf ~/.tmux.conf.bak."$(date +%Y%m%d%H%M%S)"
  # ⚠️ 注释行跟语言走，但 source-file 那行永远含 hekouwang-terminal ——
  #    uninstall.sh 靠的是路径那一行，所以换语言不影响卸载。
  printf '\n%s\nsource-file %s/current/tmux.conf\n' \
    "$(t M_INSTALL_TMUX_MARK)" "$RUNTIME" >> ~/.tmux.conf
  info M_INSTALL_TMUX_OK
fi

# ---- 9. VS Code / Cursor 主题（装了对应编辑器才装）----
VSC_SRC="$SCRIPT_DIR/config/themes/ecosystem/vscode"
if [ -d "$VSC_SRC" ]; then
  VER="$(python3 -c "import json;print(json.load(open('$VSC_SRC/package.json'))['version'])" 2>/dev/null || echo 2.0.0)"
  for ext_root in "$HOME/.vscode/extensions" "$HOME/.cursor/extensions"; do
    [ -d "$ext_root" ] || continue
    dest="$ext_root/hekouwang.hekouwang-terminal-themes-$VER"
    rm -rf "$ext_root"/hekouwang.hekouwang-terminal-themes-* 2>/dev/null || true
    mkdir -p "$dest" && cp -R "$VSC_SRC/." "$dest/"
    info M_INSTALL_VSC_OK "$(basename "$ext_root")"
  done
fi

# ---- 10. .zshrc ----
# 已有 .zshrc（含 oh-my-zsh 自动生成的模板）一律先备份再覆盖，可随时回滚。
# 想保留自己原有配置的，应该先跑 ./migrate.sh 而不是直接装。
if [ -f ~/.zshrc ]; then
  BAK=~/.zshrc.bak."$(date +%Y%m%d%H%M%S)"
  cp ~/.zshrc "$BAK"
  info M_INSTALL_ZSHRC_BAK "$BAK"
  if [ ! -f ~/.zshrc.local ] && grep -qE '^\s*(alias|export)\s' "$BAK" 2>/dev/null; then
    info M_INSTALL_ZSHRC_HINT_MIGRATE
  fi
fi
# 模板分语言：注释会原样躺进用户的 ~/.zshrc，得是他看得懂的那种语言。
# 对应语言的模板不在时自动落回英文那份（跟词条表同一套回退逻辑）。
ZSHRC_TPL="$SCRIPT_DIR/config/zshrc.template"
[ "$HKW_LANG" != "en" ] && [ -f "$ZSHRC_TPL.$HKW_LANG" ] && ZSHRC_TPL="$ZSHRC_TPL.$HKW_LANG"
ZSHRC_LOCAL_TPL="$SCRIPT_DIR/config/zshrc.local.example"
[ "$HKW_LANG" != "en" ] && [ -f "$ZSHRC_LOCAL_TPL.$HKW_LANG" ] && ZSHRC_LOCAL_TPL="$ZSHRC_LOCAL_TPL.$HKW_LANG"
cp "$ZSHRC_TPL" ~/.zshrc
[ -f ~/.zshrc.local ] || cp "$ZSHRC_LOCAL_TPL" ~/.zshrc.local

# ---- 11. iTerm2 Shell Integration ----
say M_INSTALL_SI
# 用临时文件而非 curl|bash：无 pipefail 时 curl 失败会让 bash 收到空输入并「成功」退出，静默漏装。
SI_TMP="$(mktemp)"
if curl -fsSL -m 60 https://iterm2.com/shell_integration/install_shell_integration_and_utilities.sh -o "$SI_TMP" \
   && [ -s "$SI_TMP" ] && bash "$SI_TMP"; then
  info M_INSTALL_SI_OK
else
  info M_INSTALL_SI_FAIL
fi
rm -f "$SI_TMP"

# ---- 12. 系统级 defaults ----
# ⛔ 从第 11 步 `cp "$ZSHRC_TPL" ~/.zshrc` 开始，用户的配置已经被换掉了。
#    此后每一步都不许触发 set -e —— 否则人停在「配置换了、环境没配好」的半截状态，
#    比装失败更糟（他的旧 .zshrc 已经没了）。一律 `|| 兜底`，见 memory
#    install-script-half-broken-state。
say M_INSTALL_DEFAULTS
defaults write -g ApplePressAndHoldEnabled -bool false || true

# ---- 13. atuin 导入历史 ----
command -v atuin >/dev/null && atuin import auto || true

# ---- 14. GUI 三步自动化（原来要手点，现在脚本写）----
say M_INSTALL_GUI
# ⚠️ 别裸调：setup-gui.sh 自己带 set -e，里面十来条 defaults write 全无守卫，
#    任一条失败它就非零退出 → 这里的 set -e 会把 install.sh 一起杀掉，
#    而此时 ~/.zshrc 已经被覆盖。实测父脚本当场退出码 3。
if ! bash "$SCRIPT_DIR/setup-gui.sh"; then
  info M_INSTALL_GUI_FAIL
fi

# ---- 15. 自检 ----
say M_INSTALL_DOCTOR
# HKW_NO_PROMO：让 doctor 别打「付费档在哪儿」那一行 —— 下面 install 的收尾会打，
# 两句隔十行出现两遍就成了噪音。见 doctor.sh 汇总段的注释。
HKW_NO_PROMO=1 bash "$SCRIPT_DIR/doctor.sh" || true

say M_INSTALL_DONE
dim M_INSTALL_TAIL_LOCAL
dim M_INSTALL_TAIL_OPEN
dim M_INSTALL_TAIL_THEME
dim M_INSTALL_TAIL_AUTO
dim M_INSTALL_TAIL_UNDO
echo ""
dim M_INSTALL_TAIL_CN
# 付费档在哪儿 —— 只在付费件缺席时打一行。装完这一刻他刚看见成果，
# 是除了换肤回执之外第二个不用翻 README 的转化位。买家（付费件在）不打，
# 免得冲已经付过钱的人推销（同 release.sh 里「付费仓别拿公开版首页」那条）。
if [ ! -f "$SCRIPT_DIR/config/themes/_apply_pro.sh" ] && [ -n "${HKW_URL_BUY:-}" ]; then
  dim M_INSTALL_TAIL_BUY "$HKW_URL_BUY"
fi
