# ============================================================
# 色板注册表 —— 分档的唯一分界线
#
#   community.py  开源版自带，MIT，随仓库分发
#   brand.py      付费包独占（品牌推导四套，含两套亮色）
#                 开源仓的 .gitignore 会排掉它；没有它时生成器照常工作，
#                 只是少四套主题、默认主题回退到 tokyo-night。
#
# 加自己的主题：新建 palettes/mine.py，里面写 PALETTES = {...}，
# 本文件会自动发现（扫同目录下所有 .py，除了 __init__）。
# ============================================================
import importlib
import os
import pkgutil

# 缺 brand.py 时的默认主题回退顺序（第一个存在的即为默认）
DEFAULT_ORDER = ["v2-mihei", "tokyo-night", "catppuccin-mocha"]

# 付费包提供的主题名 —— 仅用于生成器打印分档提示，不参与逻辑判断
BRAND_THEMES = ["v2-mihei", "v1-keji", "v2-mibai", "v3-caijing-bai"]


def load():
    """扫本包下所有模块，合并它们的 PALETTES。返回 (palettes, 来源映射)。"""
    palettes, origin = {}, {}
    here = os.path.dirname(__file__)
    # community 先加载，其余按名字排序 —— 同名主题后加载的覆盖先加载的
    names = sorted(
        (m.name for m in pkgutil.iter_modules([here])),
        key=lambda n: (n != "community", n),
    )
    for mod_name in names:
        mod = importlib.import_module(f"{__name__}.{mod_name}")
        for key, val in getattr(mod, "PALETTES", {}).items():
            palettes[key] = val
            origin[key] = mod_name
    return palettes, origin


def default_theme(palettes):
    for name in DEFAULT_ORDER:
        if name in palettes:
            return name
    return next(iter(palettes), "")
