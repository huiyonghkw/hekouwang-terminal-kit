#!/bin/bash
# ============================================================
# hekouwang-terminal-kit — 多机同步 / 配置漂移检查
#
# 用法:
#   ./sync.sh                  体检：部署出去的配置和仓库里的还一致吗（只读）
#   ./sync.sh --pull           按仓库重新部署一遍，把漂掉的对回来
#   ./sync.sh --export <路径>   打一个可以带去第二台机器的包
#
# 解决的问题：你在 A 机器上手改过 Ghostty config、B 机器还是老配置、
# 半年后完全想不起哪台是对的。这个脚本让「哪儿漂了」变成一句话能看清的事。
# ============================================================
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/lib/i18n.sh"
hkw_i18n_init sync "$@"
eval set -- "$HKW_ARGS"
case "${1:-}" in -h|--help) blk_sync_help; exit 0 ;; esac
RUNTIME="$HOME/.config/hekouwang-terminal"
DP="$HOME/Library/Application Support/iTerm2/DynamicProfiles/hekouwang-active-theme.json"

g='\033[1;32m'; y='\033[1;33m'; b='\033[1;34m'; d='\033[2m'; o='\033[0m'
DRIFT=0
same() { printf "  ${g}✓${o} %s\n" "$1"; }
diff_() { printf "  ${y}≠${o} %s\n" "$1"; [ -n "${2:-}" ] && printf "      ${d}↳ %s${o}\n" "$2"; DRIFT=$((DRIFT+1)); }
miss() { printf "  ${d}·${o} ${d}%s${o}\n" "$1"; }

check() {   # check <标签词条key> 仓库文件 已部署文件
  local label; label="$(t "$1")"; local src="$2" dst="$3"
  if [ ! -f "$dst" ]; then miss "$(t M_SY_NOT_DEPLOYED_ITEM "$label")"; return; fi
  if [ ! -f "$src" ]; then miss "$(t M_SY_NO_SRC_ITEM "$label")"; return; fi
  if cmp -s "$src" "$dst"; then same "$label"
  else diff_ "$(t M_SY_EDITED_ITEM "$label")" "$(t M_SY_COMPARE "$src" "$dst")"; fi
}

# ---- --export ----------------------------------------------
if [ "${1:-}" = "--export" ]; then
  OUT="${2:-$HOME/Desktop/hekouwang-terminal-kit-$(date +%Y%m%d).zip}"
  cd "$SCRIPT_DIR"
  printf "${b}%s${o}\n" "$(t M_SY_EXPORT_HEAD)"
  # 用 git ls-files 取「仓库该有的文件」（跟踪的 + 未忽略的新文件），
  # 自动排掉 .gitignore 里的东西。别用 git archive HEAD（漏未提交改动），
  # 也别 zip -r .（会吞 .git 和一堆本地垃圾）。
  # ⚠️ 用 Python 的 zipfile 打包而不是 macOS 自带 zip：自带 zip 不打 UTF-8 标记，
  #    中文文件名解出来是乱码。
  if [ -d .git ]; then
    git ls-files --cached --others --exclude-standard -z > /tmp/.hkw-files.z
  else
    find . -type f -not -path './.git/*' -print0 > /tmp/.hkw-files.z
  fi
  HKW_MSG_COUNT="$(t M_SY_EXPORT_COUNT '%s' '%s')" python3 - "$OUT" <<'PY'
import os, sys, zipfile
out = sys.argv[1]
with open('/tmp/.hkw-files.z', 'rb') as f:
    names = [n.decode('utf-8') for n in f.read().split(b'\0') if n]
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
    for n in names:
        if not os.path.isfile(n):
            continue
        zi = zipfile.ZipInfo.from_file(n, n)
        zi.flag_bits |= 0x800          # UTF-8 标记，否则中文名在别的机器上乱码
        zi.compress_type = zipfile.ZIP_DEFLATED
        with open(n, 'rb') as fh:
            z.writestr(zi, fh.read())
print(os.environ.get('HKW_MSG_COUNT', '  %s files -> %s') % (len(names), out))
PY
  rm -f /tmp/.hkw-files.z
  printf "${g}%s${o}\n" "$(t M_SY_EXPORT_OK)"
  printf "${d}%s${o}\n" "$(t M_SY_EXPORT_NEXT)"
  # 品牌包在不在，直说 —— 免得对方装完发现少四套主题不知道为什么
  if [ -f "$SCRIPT_DIR/config/themes/palettes/brand.py" ]; then
    printf "${d}%s${o}\n" "$(t M_SY_EXPORT_BRAND)"
  else
    printf "${d}%s${o}\n" "$(t M_SY_EXPORT_NO_BRAND)"
  fi
  exit 0
fi

# ---- 体检 --------------------------------------------------
printf "${b}%s${o}\n" "$(t M_SY_HEAD)"
CUR_THEME="$(cat "$RUNTIME/theme" 2>/dev/null || echo '')"
printf "${d}%s${o}\n" "$(t M_SY_CURRENT "${CUR_THEME:-$(t M_SY_NOT_DEPLOYED)}")"

printf "\n${b}%s${o}\n" "$(t M_SY_GEN_HEAD)"
if [ -n "$CUR_THEME" ]; then
  # ⚠️ iTerm2 Profile 不能逐字节比：字体是 theme.sh 部署时按本机 font.conf 探测后
  #    现填进去的（你装了 Operator Mono 就用它，别人没装就用 Maple），
  #    仓库里那份永远是默认值。所以比之前先把 Normal Font 归一化，
  #    否则每台机器都会被报一次「漂移」——那是假警报，会让真警报失去意义。
  PROF_SRC="$SCRIPT_DIR/config/themes/$CUR_THEME.json"
  if [ ! -f "$DP" ]; then
    miss "$(t M_SY_PROFILE_MISSING)"
  elif [ ! -f "$PROF_SRC" ]; then
    miss "$(t M_SY_PROFILE_NO_SRC)"
  elif python3 - "$PROF_SRC" "$DP" <<'PY'
import json, sys
def norm(p):
    d = json.load(open(p, encoding='utf-8'))
    d['Profiles'][0].pop('Normal Font', None)   # 按机器定，不参与比对
    return json.dumps(d, sort_keys=True, ensure_ascii=False)
sys.exit(0 if norm(sys.argv[1]) == norm(sys.argv[2]) else 1)
PY
  then
    DEPLOYED_FONT="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['Profiles'][0].get('Normal Font',''))" "$DP" 2>/dev/null)"
    same "$(t M_SY_PROFILE_SAME "$DEPLOYED_FONT")"
  else
    diff_ "$(t M_SY_PROFILE_DIFF)" "$(t M_SY_COMPARE "$PROF_SRC" "$DP")"
  fi
  ECO="$SCRIPT_DIR/config/themes/ecosystem/$CUR_THEME"
  check M_SY_ECO_COLORS  "$ECO/colors.sh"       "$RUNTIME/current/colors.sh"
  check M_SY_ECO_DELTA   "$ECO/delta.gitconfig"  "$RUNTIME/current/delta.gitconfig"
  check M_SY_ECO_TMUX    "$ECO/tmux.conf"        "$RUNTIME/current/tmux.conf"
  check M_SY_ECO_GHOSTTY "$SCRIPT_DIR/config/themes/ghostty/hekouwang-$CUR_THEME" \
                         "$HOME/.config/ghostty/themes/hekouwang-$CUR_THEME"
else
  miss "$(t M_SY_NO_THEME)"
fi

printf "\n${b}%s${o}\n" "$(t M_SY_TPL_HEAD)"
check M_SY_TPL_STARSHIP "$SCRIPT_DIR/config/starship.toml" "$HOME/.config/starship.toml"
check M_SY_TPL_GHOSTTY  "$SCRIPT_DIR/config/ghostty.config" "$HOME/.config/ghostty/config"
# ⚠️ 模板分语言（zshrc.template / .zh），比对时必须挑**部署时用的那份**，
#    否则中文用户每次跑 sync 都会看到一条假漂移，真警报就被淹了。
ZSHRC_TPL="$SCRIPT_DIR/config/zshrc.template"
[ "$HKW_LANG" != "en" ] && [ -f "$ZSHRC_TPL.$HKW_LANG" ] && ZSHRC_TPL="$ZSHRC_TPL.$HKW_LANG"
check M_SY_TPL_ZSHRC    "$ZSHRC_TPL" "$HOME/.zshrc"

printf "\n${b}%s${o}\n" "$(t M_SY_LOCAL_HEAD)"
[ -f "$HOME/.zshrc.local" ] \
  && printf "  ${g}✓${o} %s\n" "$(t M_SY_LOCAL_OK "$(grep -vc '^\s*#\|^\s*$' "$HOME/.zshrc.local" 2>/dev/null || echo 0)")" \
  || miss "$(t M_SY_LOCAL_MISSING)"

# ---- 结论 --------------------------------------------------
printf "\n${b}%s${o}\n" "$(t M_SY_RESULT)"
if [ "$DRIFT" = "0" ]; then
  printf "${g}%s${o}\n" "$(t M_SY_NO_DRIFT)"
else
  printf "${y}%s${o}\n" "$(t M_SY_DRIFT "$DRIFT")"
  printf "%s\n" "$(t M_SY_DRIFT_KEEP)"
  printf "%s\n" "$(t M_SY_DRIFT_PULL)"
fi

if [ "${1:-}" = "--pull" ]; then
  printf "\n${b}%s${o}\n" "$(t M_SY_PULL_HEAD)"
  [ -n "$CUR_THEME" ] || CUR_THEME="$(cd "$SCRIPT_DIR/config/themes" && ls -1 *.json 2>/dev/null | head -1 | sed 's/\.json$//')"
  bash "$SCRIPT_DIR/theme.sh" "$CUR_THEME" | sed 's/^/  /'
  cp "$SCRIPT_DIR/config/starship.toml" "$HOME/.config/starship.toml"
  printf "  ${g}%s${o}\n" "$(t M_SY_PULL_SS)"
  printf "${d}%s${o}\n" "$(t M_SY_PULL_NOTE)"
  printf "${d}%s${o}\n" "$(t M_SY_PULL_NOTE2 "$SCRIPT_DIR")"
fi
