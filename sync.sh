#!/bin/bash
# ============================================================
# hekouwang-terminal-kit — 多机同步 / 配置漂移检查 / 钉住状态换机
#
# 用法:
#   ./sync.sh                      体检：部署出去的配置和仓库里的还一致吗（只读）
#   ./sync.sh --pull               按仓库重新部署一遍，把漂掉的对回来
#   ./sync.sh --export <路径>       打一个可以带去第二台机器的包（整仓）
#   ./sync.sh --state-export [文件] 导出本机钉住状态（主题/跟随/Node/光学/场景/badge）
#   ./sync.sh --state-import <文件> 在新机按 manifest 还原钉住状态
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

# ---- --state-export / --state-import（换机钉住状态，不是整仓 zip）----
state_export() {
  local out="${1:-$HOME/Desktop/hekouwang-terminal-state-$(date +%Y%m%d).json}"
  mkdir -p "$(dirname "$out")" 2>/dev/null || true
  printf "${b}%s${o}\n" "$(t M_SY_STATE_EXPORT_HEAD)"
  HKW_RUNTIME="$RUNTIME" HKW_OUT="$out" python3 <<'PY' >/dev/null
import json, os, time
from pathlib import Path
rt = Path(os.environ["HKW_RUNTIME"])
out = Path(os.environ["HKW_OUT"])

def read_text(p):
    try:
        return p.read_text(encoding="utf-8").strip()
    except OSError:
        return None

def parse_kv(p):
    d = {}
    try:
        for line in p.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, _, v = line.partition("=")
            d[k.strip()] = v.strip().strip('"').strip("'")
    except OSError:
        pass
    return d

auto = {"enabled": False}
ac = rt / "auto.conf"
if ac.is_file():
    kv = parse_kv(ac)
    auto = {
        "enabled": True,
        "dark": kv.get("AUTO_DARK") or kv.get("dark"),
        "light": kv.get("AUTO_LIGHT") or kv.get("light"),
    }

typo = parse_kv(rt / "typography") if (rt / "typography").is_file() else None
scene = parse_kv(rt / "scene") if (rt / "scene").is_file() else None
if scene is None and (rt / "scene.env").is_file():
    env = {}
    for line in (rt / "scene.env").read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line.startswith("export "):
            line = line[len("export "):]
        if "=" in line and not line.startswith("#"):
            k, _, v = line.partition("=")
            env[k.strip()] = v.strip().strip('"')
    if env.get("HKW_SCENE"):
        scene = {"SCENE_ID": env["HKW_SCENE"]}

manifest = {
    "version": 1,
    "kind": "hekouwang-terminal-state",
    "exported_at": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
    "theme": read_text(rt / "theme"),
    "auto": auto,
    "node": read_text(rt / "node-manager"),
    "lang": read_text(rt / "lang"),
    "optical": typo if typo else None,
    "scene": scene if scene else None,
    "badge": read_text(rt / "badge"),
}
out.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
  printf "${g}%s${o}\n" "$(t M_SY_STATE_EXPORT_OK "$out")"
  printf "${d}%s${o}\n" "$(t M_SY_STATE_EXPORT_NEXT)"
}

state_import() {
  local src="${1:-}"
  if [ -z "$src" ] || [ ! -f "$src" ]; then
    printf "${y}%s${o}\n" "$(t M_SY_STATE_IMPORT_NEED)"
    exit 1
  fi
  printf "${b}%s${o}\n" "$(t M_SY_STATE_IMPORT_HEAD "$src")"
  eval "$(HKW_SRC="$src" python3 <<'PY'
import json, os, shlex
m = json.load(open(os.environ["HKW_SRC"], encoding="utf-8"))
if m.get("kind") != "hekouwang-terminal-state":
    raise SystemExit("bad kind")
def exp(k, v):
    if v is None or v == "":
        return
    print(f"export HKW_ST_{k}={shlex.quote(str(v))}")
exp("THEME", m.get("theme"))
exp("NODE", m.get("node"))
exp("LANG", m.get("lang"))
exp("BADGE", m.get("badge"))
auto = m.get("auto") or {}
exp("AUTO_ON", "1" if auto.get("enabled") else "0")
exp("AUTO_DARK", auto.get("dark"))
exp("AUTO_LIGHT", auto.get("light"))
opt = m.get("optical") or {}
exp("FONT_ID", opt.get("FONT_ID"))
exp("DENSITY", opt.get("DENSITY"))
sc = m.get("scene") or {}
exp("SCENE_ID", sc.get("SCENE_ID"))
PY
)"
  if [ -n "${HKW_ST_LANG:-}" ]; then
    mkdir -p "$RUNTIME"
    printf '%s\n' "$HKW_ST_LANG" > "$RUNTIME/lang"
    same "$(t M_SY_STATE_APPLIED_LANG "$HKW_ST_LANG")"
  fi
  if [ -n "${HKW_ST_NODE:-}" ] && [ -x "$SCRIPT_DIR/node-mgr.sh" ]; then
    bash "$SCRIPT_DIR/node-mgr.sh" "$HKW_ST_NODE" && same "$(t M_SY_STATE_APPLIED_NODE "$HKW_ST_NODE")" \
      || printf "  ${y}%s${o}\n" "$(t M_SY_STATE_FAIL_NODE)"
  fi
  if [ -n "${HKW_ST_THEME:-}" ]; then
    bash "$SCRIPT_DIR/theme.sh" "$HKW_ST_THEME" && same "$(t M_SY_STATE_APPLIED_THEME "$HKW_ST_THEME")" \
      || printf "  ${y}%s${o}\n" "$(t M_SY_STATE_FAIL_THEME)"
  fi
  if [ "${HKW_ST_AUTO_ON:-0}" = "1" ]; then
    # shellcheck disable=SC2086
    bash "$SCRIPT_DIR/theme.sh" --auto ${HKW_ST_AUTO_DARK:+$HKW_ST_AUTO_DARK} ${HKW_ST_AUTO_LIGHT:+$HKW_ST_AUTO_LIGHT} \
      && same "$(t M_SY_STATE_APPLIED_AUTO)" \
      || printf "  ${y}%s${o}\n" "$(t M_SY_STATE_FAIL_AUTO)"
  else
    bash "$SCRIPT_DIR/theme.sh" --auto off >/dev/null 2>&1 || true
    same "$(t M_SY_STATE_APPLIED_AUTO_OFF)"
  fi
  if [ -n "${HKW_ST_FONT_ID:-}" ]; then
    if [ -x "$SCRIPT_DIR/font.sh" ]; then
      bash "$SCRIPT_DIR/font.sh" apply "$HKW_ST_FONT_ID" \
        ${HKW_ST_DENSITY:+--density "$HKW_ST_DENSITY"} \
        ${HKW_ST_THEME:+--theme "$HKW_ST_THEME"} \
        && same "$(t M_SY_STATE_APPLIED_OPTICAL "$HKW_ST_FONT_ID")" \
        || printf "  ${y}%s${o}\n" "$(t M_SY_STATE_FAIL_OPTICAL)"
    else
      miss "$(t M_SY_STATE_SKIP_PAID optical)"
    fi
  fi
  if [ -n "${HKW_ST_SCENE_ID:-}" ]; then
    if [ -x "$SCRIPT_DIR/scene.sh" ]; then
      bash "$SCRIPT_DIR/scene.sh" apply "$HKW_ST_SCENE_ID" \
        ${HKW_ST_THEME:+--theme "$HKW_ST_THEME"} \
        && same "$(t M_SY_STATE_APPLIED_SCENE "$HKW_ST_SCENE_ID")" \
        || printf "  ${y}%s${o}\n" "$(t M_SY_STATE_FAIL_SCENE)"
    else
      miss "$(t M_SY_STATE_SKIP_PAID scene)"
    fi
  fi
  if [ -n "${HKW_ST_BADGE:-}" ]; then
    if [ -x "$SCRIPT_DIR/scene.sh" ]; then
      bash "$SCRIPT_DIR/scene.sh" badge "$HKW_ST_BADGE" \
        && same "$(t M_SY_STATE_APPLIED_BADGE "$HKW_ST_BADGE")" \
        || { mkdir -p "$RUNTIME"; printf '%s\n' "$HKW_ST_BADGE" > "$RUNTIME/badge"; same "$(t M_SY_STATE_APPLIED_BADGE_FILE)"; }
    else
      mkdir -p "$RUNTIME"
      printf '%s\n' "$HKW_ST_BADGE" > "$RUNTIME/badge"
      miss "$(t M_SY_STATE_SKIP_PAID badge)"
    fi
  fi
  printf "${g}%s${o}\n" "$(t M_SY_STATE_IMPORT_DONE)"
  printf "${d}%s${o}\n" "$(t M_SY_STATE_IMPORT_NEXT)"
}

case "${1:-}" in
  --state-export|--export-state)
    state_export "${2:-}"
    exit 0
    ;;
  --state-import|--import-state)
    state_import "${2:-}"
    exit 0
    ;;
esac

# ---- --export ----------------------------------------------
if [ "${1:-}" = "--export" ]; then
  OUT="${2:-$HOME/Desktop/hekouwang-terminal-kit-$(date +%Y%m%d).zip}"
  cd "$SCRIPT_DIR"
  printf "${b}%s${o}\n" "$(t M_SY_EXPORT_HEAD)"
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
        zi.flag_bits |= 0x800
        zi.compress_type = zipfile.ZIP_DEFLATED
        with open(n, 'rb') as fh:
            z.writestr(zi, fh.read())
print(os.environ.get('HKW_MSG_COUNT', '  %s files -> %s') % (len(names), out))
PY
  rm -f /tmp/.hkw-files.z
  printf "${g}%s${o}\n" "$(t M_SY_EXPORT_OK)"
  printf "${d}%s${o}\n" "$(t M_SY_EXPORT_NEXT)"
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
  PROF_SRC="$SCRIPT_DIR/config/themes/$CUR_THEME.json"
  if [ ! -f "$DP" ]; then
    miss "$(t M_SY_PROFILE_MISSING)"
  elif [ ! -f "$PROF_SRC" ]; then
    miss "$(t M_SY_PROFILE_NO_SRC)"
  elif python3 - "$PROF_SRC" "$DP" <<'PY'
import json, sys
def norm(p):
    d = json.load(open(p, encoding='utf-8'))
    d['Profiles'][0].pop('Normal Font', None)
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
ZSHRC_TPL="$SCRIPT_DIR/config/zshrc.template"
[ "$HKW_LANG" != "en" ] && [ -f "$ZSHRC_TPL.$HKW_LANG" ] && ZSHRC_TPL="$ZSHRC_TPL.$HKW_LANG"
check M_SY_TPL_ZSHRC    "$ZSHRC_TPL" "$HOME/.zshrc"

printf "\n${b}%s${o}\n" "$(t M_SY_LOCAL_HEAD)"
[ -f "$HOME/.zshrc.local" ] \
  && printf "  ${g}✓${o} %s\n" "$(t M_SY_LOCAL_OK "$(grep -vc '^\s*#\|^\s*$' "$HOME/.zshrc.local" 2>/dev/null || echo 0)")" \
  || miss "$(t M_SY_LOCAL_MISSING)"

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
