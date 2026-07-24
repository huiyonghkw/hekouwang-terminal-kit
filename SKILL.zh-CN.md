# hekouwang-terminal-kit — 终端高阶配置（iTerm2 主 · 多终端同色）· 中文版

> [English](SKILL.md) · **简体中文**
> 这是 `SKILL.md` 的中文镜像。**两份必须同步改** —— 只改一份，另一种语言的读者就少了那条。


一套「配置即代码」的 macOS 终端环境：

- **窗口**：Minimal 主题，无标题栏无边框无滚动条，整窗一块画布 + 毛玻璃
- **配色**：七套主题走同一份 `PALETTES` 生成，默认 **v2-mihei**（V2 米黑，`#19191a` 暖黑 + 品牌暖橙光标）
- **跨终端**：同一份色板一并出 iTerm2 / Ghostty / Warp / macOS 自带终端
- **跨工具**：bat / fzf / eza / delta / tmux / VS Code 全部同色
- **字体**：按 `config/font.conf` 优先级探测本机已装的（含自购的商业字体），**不分发任何字体文件**
- **自动化**：Triggers 随 Profile 交付（错误标红/警告标黄/成功标绿/密码管理器），标注色跟主题走
- **AI 适配**：`Shift+Enter` 换行不提交（Claude Code 多行输入）

---

## 一、分档（回答「能不能开源 / 这功能属哪档」时先看这里）

**划线口径 = 能力，不是文件**：开源版 = 一台配好的 iTerm2；付费版 = 同一份色板走出 iTerm2。

**免费（开源仓里就有）**：完整 iTerm2 主题（3 套社区配色 + 毛玻璃 + Triggers + Shift+Enter）+ CLI 全家桶 + 体检 / 迁移 / 卸载 + 安装/换肤/自检等脚本本体。

⛔ **付费能力的实现也在付费包里**（2026-07-23 收紧）：以前是「脚本全部开源，只门控配置内容」，
结果免费仓里躺着多终端同步的完整实现和各 App 的格式踩坑手册 —— 别人补三个生成器就复刻了付费档。
现在 `import.sh` / `workspace.sh` / `palette.sh` 在免费仓里都只有 ~22 行（广告位 + `exec` 付费引擎），
`theme.sh` 只管 iTerm2，多终端那半边在 `config/themes/_apply_pro.sh`。

**付费**：4 套品牌主题（含 2 套亮色）+ 多终端同步 + 全生态同色 + 字体优先级表 + 跟随系统深浅色 + 速查卡 + 一年更新答疑。

| 免费（开源仓） | 付费（付费包） |
|---|---|
| `_generate.py` 完整 iTerm2 主题 | `generators/pro.py` 多终端 + 全生态生成器 |
| `palettes/community.py` 3 套社区色板 | `palettes/brand.py` 4 套品牌色板 |
| `config/keymap.json` 全局键映射 | `config/font.conf` 字体优先级表 |
| `theme.sh` 切 iTerm2 主题 / 画廊 / 预览 | `_apply_pro.sh` Ghostty·Warp·自带终端·全生态 |
| `import.sh`·`workspace.sh`·`palette.sh` 广告位 | `_import.py`·`_workspace_pro.sh`·`_derive.py` 引擎 |
| — | `references/terminals.md` 各 App 格式口径与踩坑 |

付费件不在时，生成器**照常出完整 iTerm2 主题**，并打印「以下属付费包，当前不生成」，不报错不留半成品。

- `./release.sh --oss <目录>` 导出开源版（剔付费件 → 跑生成器验证 → 扫夹带）
- `./release.sh --pack <zip>` 打付费包
- `./release.sh --check` 脚本自检 + 扫工作区与 **git 历史**里的真实 IP / 家目录 / 密钥

⚠️ **别把母版仓直接改成 public**：`--check` 会报出历史里哪些提交含真实服务器信息。
正确姿势是 `--oss` 导出干净副本，在**新仓**里 `git init`。

---

## 二、目录结构

```
hekouwang-iterm2-skill/
├── install.sh      一键安装（--dry-run 先预演要改什么）
├── migrate.sh      ⭐ 接管已有 .zshrc（搬进 .zshrc.local，不是覆盖）
├── uninstall.sh    ⭐ 一键还原（--dry-run；从备份还原、GUI 设置 defaults delete）
├── theme.sh        换肤（连 bat/fzf/eza/delta/tmux/四终端一起换）；--auto 跟随系统
│                   ⭐ --preview <名字> 单套整块预览 / --gallery 全套（截图用）
├── doctor.sh       自检（只读）；--fix 逐项修；--profile zprof 点名慢插件
├── update.sh       更新（--check 只看更了什么）
├── sync.sh         漂移检查 / --pull 对回 / --export 打包带去第二台机器
├── workspace.sh    ⭐付费 项目工作区：cd 进哪个项目，标签页自动变色 + 印项目名
├── palette.sh      ⭐付费 从一个品牌色推出整套主题
├── setup-gui.sh    GUI 自动化（Minimal 主题 / 默认 Profile / 键映射）
├── release.sh      ⭐ 分档导出：--oss / --pack / --check
├── lib/
│   ├── i18n.sh                 ⭐ shell 侧运行时语言层
│   ├── i18n.py                 ⭐ Python 生成器那半边的同款
│   └── i18n/{en,zh}/*.sh       词条表，一个脚本一份
├── config/
│   ├── zshrc.template[.zh]     .zshrc 模板（source 生态配色，不写死任何 hex）
│   ├── zshrc.local.example[.zh] 私有配置模板（SSH 别名 / 代理）
│   ├── keymap.json             全局键映射（Shift+Enter 等）
│   ├── font.conf               ⭐付费 字体优先级表
│   ├── starship.toml           Starship（用 ANSI 色名，随主题走）
│   ├── ghostty.config          Ghostty 主配置模板
│   └── themes/
│       ├── _generate.py        ⭐ 唯一真相源：色板 → iTerm2 完整主题
│       ├── _preview.py         ⭐ 画廊 / 整块预览渲染器（真彩色，与当前主题无关）
│       ├── names.json          ⭐ 主题显示名的中英对照（生成物）
│       ├── generators/pro.py   ⭐付费 多终端 + 全生态生成器
│       ├── palettes/           色板（community.py 免费 / brand.py 付费）
│       │   └── _derive.py      ⭐付费 色板推导器（品牌色 → 整套主题）
│       ├── <主题>.json          iTerm2 Dynamic Profile
│       ├── ghostty/ warp/      ⭐付费
│       └── ecosystem/          ⭐付费 colors.sh / bat / delta / tmux / 自带终端 / VS Code
├── docs/速查卡.html|.pdf        ⭐付费 A4 可打印
│   └── 录制手册.md · 录制沙盒.sh  内部：做内容用，两档都不进
└── references/
    ├── terminals.md            ⭐ 各终端实现细节与踩坑（字体 / Ghostty / Warp / 自带终端）
    ├── zshrc-explained.md      .zshrc 逐块详解 + 已知问题
    ├── iterm2-gui-settings.md  GUI 清单 + 高级功能（Triggers/Hotkey/tmux -CC）
    └── shortcuts.md            快捷键速查
```

---

## 三、使用流程

### 1. 全新 Mac 一键还原

```bash
./install.sh --dry-run   # 先看要改哪些文件、写哪些系统设置
./install.sh             # 国内网络：CN=1 ./install.sh
```

装完：iTerm2 + 字体 + CLI 全家桶 → 主题与生态配色 → bat 主题 → 挂进 git/tmux →
编辑器主题 → `.zshrc` → Shell Integration → GUI 设置 → `doctor.sh` 自检。约 3 分钟。

首次交互安装时会问一次语言，答案记进 `~/.config/hekouwang-terminal/lang`；
非交互（CI / 管道）永远不卡在这个问题上，直接走英文。

### 2. 用户已经有自己的 .zshrc

**别直接 `install.sh`**（那是覆盖）。先 `./migrate.sh` 看报告，再 `--apply`。

按**段落**判定（不是按行——按行会把 `for…done`、续行命令拦腰砍断，搬出去就是语法错的文件）；
写入前 `zsh -n` 验语法；写完**真起一个 shell 验**，起不来自动回滚
（`~/.zshrc` 和 `~/.zshrc.local` 都先备份、都能回滚 —— 以前只还原前者，
追加进 `.zshrc.local` 的那一坨会永远留着，回滚是假的，2026-07-23 补）。
`.zshrc` 与模板重合度 ≥60% 时直接拒绝迁移（那说明他本来就在用这套模板，该跑 `install.sh`）。

### 3. 解读 / 优化某台机器的 .zshrc

读 `references/zshrc-explained.md` 逐块解释；注意末尾「已知问题清单」（Node 管理器共存、重复加载、插件顺序）。也可直接 `./doctor.sh`。

### 4. 终端启动慢

```bash
./doctor.sh --profile
```

第 7 节跑 7 次 `zsh -i -c exit` 取中位数（<300ms 快 / <600ms 偏慢 / 更高明显卡）；
`--profile` 用临时 `ZDOTDIR` 挂 `zmodload zsh/zprof` 再 source 用户真实 `.zshrc`，点名耗时前 8。
典型元凶 `compinit` / `compdump`。

### 5. 换主题 / 加主题 / 改配色

- `./theme.sh` 画廊（每套带真彩色 16 色条）→ `./theme.sh <名字>`：**一条命令换四个终端 + 整条工具链**
- `./theme.sh --preview <名字>` 出一整块「假终端」：提示符 / eza 文件列表 / git diff /
  语法高亮 / ERROR·WARN 标色都在一张图里；`--gallery` 把全部主题挨个渲一遍。
  **这是给付费仓截主题图的那把工具** —— 它用 24 位真彩色画，跟当前终端用的是哪套主题无关，
  所以在任何终端里截出来都一致，不用为了截图先换七次肤。
  渲染器是 `config/themes/_preview.py`，色值从**生成出来的 `.json`** 读（不读色板 .py，
  这样开源版没有 brand.py 也照样能预览）。
- 换肤后打的是**分组回执**（终端 / 工具链），不是一堵平墙；抬头那行右对齐由
  `_preview.py --banner` 出 —— bash 的 `printf %-Ns` 按字节补齐，中文标题一定歪
- 跟随系统深浅色：`./theme.sh --auto [暗 亮]` / `--auto off`
  （launchd `WatchPaths` 盯 `~/Library/Preferences/.GlobalPreferences.plist`，`RunAtLoad` 保证登录也对一次）
- **改色只改 `palettes/*.py`，重跑 `_generate.py`**。别手改生成出来的 JSON/YAML/tmTheme
- 加自己的主题：新建 `palettes/mine.py` 写 `PALETTES = {...}`，会被自动发现
- 主题显示名分中英两套：生成产物里烧的一律是**英文名**，中文名在**部署那一刻**
  从 `config/themes/names.json` 注入。所以两种语言共用一套产物，不会有两份互相漂的 JSON

**从品牌 token 推主题的方法**（四套品牌主题就是这么来的，细节见 `brand.py` 注释）：

1. **色相取自品牌 token，别抄社区主题**——色相是身份
2. **明度用 WCAG 对比度反解**：normal→5.5:1、bright→9:1。
   ⚠️ 品牌原色**不能直接填进 ANSI**（落到暗底往往只有 3.7–4.3:1，当正文会糊）。
   **亮底方向相反**：对比度越高颜色越深，亮底的 bright 比 normal 更深
3. **饱和按各版性格定**：V2 编辑部 42%（墨色）、V1 科技 89%（霓虹是身份）、V3 财经 72%（Material 档）
4. **normal 与 bright 必须不同**——`ls`/`git diff`/语法高亮全靠这一对表达强调

### 6. 让 bat / fzf / eza / git diff 跟终端同色

`_generate.py` + `pro.py` 为每套主题生成 `ecosystem/<主题>/` → `theme.sh` 拷进
`~/.config/hekouwang-terminal/current/` → `.zshrc` 固定 `source` 那个路径。换肤不用改 `.zshrc`。

- bat 主题在 `install.sh` 阶段**一次装全套并 `bat cache --build`**；
  ⚠️ bat 按主题内部的 `name` 字段索引不是文件名；**认不出主题时静默回退默认配色不报错**，
  所以 `theme.sh` 有自愈、`doctor.sh` 查的是**当前这套**在不在（查「有没有 hekouwang-*」没有分辨力）
- delta 挂 `~/.gitconfig` 的 `[include]`；tmux 挂 `~/.tmux.conf` 的 `source-file`。
  这两处改的是**用户自己的**文件，所以 install 先备份、只加一行，uninstall 能精确摘掉
- **starship 不生成**：它的 style 用 ANSI 色名，天然跟随调色板。生成 hex 反而钉死它

### 7. 多终端 / 字体

**用法**在这儿，**实现细节与踩坑全在 [`references/terminals.md`](references/terminals.md)**（改这块前必读）：

- 换肤时 `theme.sh` 会**同时刷新主题文件本身**，不只是改 `theme =` 行（只改行会让 Ghostty 安静地用旧色，2.0 修的真 bug）
- 字体按 `config/font.conf` 优先级探测；**iTerm2 写 PostScript 名、Ghostty 写 family 名 + font-style**，两个 App 口径不同
- macOS 自带终端**只有一个字体字段**，没有 Symbols Nerd Font 兜底层 →
  `APPLE_TERMINAL_FONT=icons|match` 二选一（保图标 / 保字体统一）
- ⚠️ **Ghostty 与自带终端都不会保存即生效**，且**退出时会用内存配置覆盖**——验收要验运行中的 App，不是验配置文件

### 8. 为 AI 工作流准备的三件事（均属付费）

都从同一个场景来：**四个 tab 同时跑着四个 agent**。

- **项目工作区** `./workspace.sh add <路径>` —— cd 进哪个项目，标签页自动变色 + 印项目名。
  标签色从当前调色板取，永远在同色系里；换肤后 `theme.sh` 会自动重建。
  实现与踩坑见付费包的 `config/themes/_workspace_pro.sh` 文件头。
    ⭐ **卖点定位（写文案/分档时照此口径）**：给 tab 上色本身不难，一段 zsh precmd 钩子（十几行、发 iTerm2 `]6;1;bg;...` 转义码）免费就能做，但那颜色**写死、换肤不跟**。付费值钱的**唯一**一层是**「颜色跟着主题自动重算、永远同色系」**——别把「能上色」当卖点，「跟主题走」才是。演示图用真机截图 `docs/images/40-workspace.png`（3 个彩色 tab）。
  ⚠️ 依赖 Shell Integration（APS 靠它上报路径）+ `EnableAutomaticProfileSwitching` 总开关，
  `workspace.sh` 会替用户检查这两项。`theme.sh` 换肤后会调 `workspace.sh --rebuild` 重建，登记表 `~/.config/hekouwang-terminal/workspaces.conf` 是唯一真相源。
  ⚠️ 不走 Trigger 路线：那条路版式固定、删不掉「A trigger fired…」、说不出耗时与命令名。
  前台检测要起 osascript（约 50ms），但只有跑够久的命令才走到那步，日常敲命令零开销。
- **色板推导器** `./palette.sh --from "#hex" --name X [--light] [--preset 编辑|科技|数据]` ——
  把第 5 节那套推导方法固化成工具。付费卖的因此不是「4 套主题」，是**无限套 + 一套方法**。

> ⛔ **不要再尝试「启动加速」这个方向**：2026-07-22 实测做过又撤了。
> zprof 报的「compinit 占 86%」是被 zprof 自身插桩开销放大的；真实基线只有 ~175ms，
> 正确解法（自己 compinit -C + 给 omz 的那次打桩）实测 175→168ms，在噪声里。
> 而错误解法（自己跑一次 compinit 但没拦住 omz 那次）会让 compinit 跑两遍，**反而慢一倍**（189→400ms）。

### 9. 卸载 / 还原

`./uninstall.sh --dry-run` 看清单，再 `./uninstall.sh`。四条底线（改它前必读）：

1. 只删本套装自己装的。Homebrew 本体、oh-my-zsh、`~/.zshrc.local`、用户自己的 git/ssh 配置不碰
2. `~/.zshrc` 从 `.bak` **还原**而不是删掉；找不到备份就明说，不假装成功
3. GUI 设置用 `defaults delete` 恢复**出厂默认**，不是写一个「我们以为的默认值」
4. `Default Bookmark Guid` 只在它还指着本套装 Guid 时才删；`GlobalKeyMap` 只摘我们加的两个键

⚠️ `uninstall.sh` 和 `setup-gui.sh` 都会**拒绝在自己所在的终端里退出该终端**（否则把跑着脚本的窗口一起关掉，人停在半截）。判据用 `$ITERM_SESSION_ID` / `$TERM_PROGRAM`，不用 `pgrep`（沙箱下看不到 GUI 进程）。

---

### 10. 语言

- 一律默认英文。`--lang zh` 或 `HKW_LANG=zh` 切中文，`install.sh` 会把选择落进
  `~/.config/hekouwang-terminal/lang`，之后不用每次带参数
- 词条表在 `lib/i18n/{en,zh}/<脚本>.sh`，一个脚本一份，**先 en 打底再叠当前语言** ——
  某条没翻译就落回英文，不会打出空行
- ⚠️ macOS 自带 bash 是 3.2，**没有关联数组**。词条表是普通变量 + `${!name}` 间接展开，
  这是有意的；别「整理」成 `declare -A`，那只在装了 bash 5 的机器上能跑
- ⚠️ 所有词条走 `printf --`。不加 `--` 的话，以 `-` 开头的词条
  （`"--check mode, nothing was touched"`）会被 printf 当成自己的选项，什么都不打
- help 正文在词条表里，不在脚本头部注释里。老那套 `sed -n '3,13p' "$0"` 没法双语，必然漂

---

## 四、关键原则

1. **配置即代码**：Profile 用 Dynamic Profile JSON 管理，GUI 项用 `defaults write` 写，不手点
2. **一份色板管全链路**：多套色板各自手写就一定会漂（实测手工维护的 Warp 主题 16 槽错 8 个）
3. **多主题一个 Guid**：切主题=换激活文件不换 Guid，默认 Profile 绑定永不断
4. **字体只用自由许可**：默认 Maple Mono NF CN（SIL OFL）。
   ⚠️ 1.x 曾从第三方仓库拉 Operator Mono（H&Co 商业字体）—— 自用是灰色，**随产品分发就是侵权**，2.0 已移除
5. **加载顺序**：omz → 插件 → starship → 生态配色 → CLI 套件 → **syntax-highlighting 倒数第二** → iTerm2 integration 最后。
   ⚠️ 生态配色必须排在 CLI 套件**之前**（它导出的 `HEKOUWANG_SOLO_NF` 决定 eza 要不要带图标）
6. **brew 前缀自适应**：用 `brew --prefix` 探测，Apple Silicon / Intel 通吃
7. **脱敏红线**：SSH 别名、代理地址等私有内容永不进 git，放 `~/.zshrc.local`
8. **Node 管理器只留一个**：推荐 fnm，不要 nvm/fnm/brew node 混用
9. **defaults 写完别 killall cfprefsd**：会丢掉还没落盘的写入
10. **能装就要能卸**：每个写操作都要有对应还原路径，且都能 `--dry-run` 预演
11. ⛔ **`$变量` 后别紧跟全角字符**（`"$FOO）"`）：会被并进变量名，报 unbound variable 且**整个脚本当场退出**。
    写 `${FOO}`。开发 2.0 时连踩三次，已固化成 `release.sh --check` 的硬检查
