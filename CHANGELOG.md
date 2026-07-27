# 更新日志

> 公开版更新日志：只记**你用得到的变化**。
> 付费包另有一份完整版，逐条记着每个坑是怎么调出来的。

本项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

---

## [2.3.0]

- 新增项目主页 <https://huiyonghkw.github.io/hekouwang-terminal-kit/>：
  免费/付费对比图、分档表、怎么买、七天退款、能力边界，中英双语
- `theme.sh` / `doctor.sh` / `install.sh` 在开源版下各多打一行，说明付费档在哪儿。
  只有一行、只在付费件缺席时打；装了付费包之后一句都不会出现
- 🐞 修：发版脚本 `--update` 用的 `rsync -a` 会静默漏发**等长**改动
  （版本号升位、改一个字符的 typo），已改成按校验和比对
- 🐞 修：**这份更新日志以前根本没进过公开仓**（导出脚本的 `.gitignore` 把它自己
  生成的这份忽略掉了，全程零报错）。所以 2.3.0 之前没有历史记录，不是没改过
- 🐞 修：`install.sh` 装完的收尾写着「换肤（连 bat/fzf/git diff 一起换）」，
  但开源版只同步 iTerm2，工具链同色是付费能力。这行文案说的不是开源版能做到的事，
  已改成「换肤：./theme.sh」

## [2.2.0]

**语言：默认英文，可切中文**

- 全线脚本、生成器、模板的对外文案默认英文；`--lang zh` 或 `HKW_LANG=zh` 切中文
- `install.sh` 首次交互安装时问一次语言并记住（`~/.config/hekouwang-terminal/lang`），
  之后所有命令跟着走；非交互运行永远不卡在这个问题上
- 文档双语并列：`README.md` / `README.zh-CN.md`、`SKILL.md` / `SKILL.zh-CN.md`
- `.zshrc` 模板分语言（`config/zshrc.template` / `.zh`），落进你家目录的注释是你选的那种语言
- 主题显示名分中英两套：产物里烧英文名，中文名在部署那一刻注入 ——
  两种语言共用同一套生成产物，不会有两份互相漂的 JSON
- 英文版模板里的 Homebrew 国内镜像改为默认注释掉（在国外网络上它只会更慢）

**修复**

- `migrate.sh` 自动回滚现在真的还原 `~/.zshrc.local`：以前 `$LOCAL_BAK` 从没被赋值，
  追加进去的内容永远留着，回滚是假的
- `uninstall.sh --dry-run` 不再谎报「已还原 ~/.zshrc」——它一个字节都没动
- `uninstall.sh` / `install.sh` 认 Ghostty config 与自带终端 Profile 时中英两种标记都认，
  换语言重装后不会漏删、也不会每次多备份一份
- `install.sh` 里 `setup-gui.sh` 失败不再把整个安装带走

---

## [2.1.0]

**换肤**

- 换肤回执改成分组（终端 / 工具链），一眼看清哪些真生效了、哪些跳过了
- `./theme.sh --preview <名字>` 出一整块「假终端」：提示符、文件列表、git diff、
  语法高亮、ERROR/WARN 标色都在一张图里，不用真换肤就能挑
- `./theme.sh --gallery` 把全部主题挨个渲一遍
- 标题栏默认与背景同色，整窗一块画布

**主题**

- 主题生成器新增旧产物清理：移除一套色板后，它留下的文件会一并清掉，
  不再永远赖在目录里

**修**

- 修 iTerm2 在 GUI 里编辑过 Dynamic Profile 后，文件被回写成存根导致换肤失效
- 修 `Send text at start` 被 GUI 手滑写入后，每开一个 tab 都自动敲一行命令，
  换肤/重装都清不掉（Dynamic Profile 只覆盖 JSON 里出现过的键，现已显式声明为空）

## [2.0.0]

**这一版把「一台配好的 iTerm2」做完整了。**

- **Minimal 窗口形态**：无标题栏 · 无边框 · 无滚动条 · 无限回滚
- **配色**：3 套社区主题（catppuccin-mocha / tokyo-night / gruvbox-dark），
  走同一份色板生成，改色只改一个文件
- **质感层**：毛玻璃 · 透明度 · 光标形态
- **Triggers**（随 Profile 交付，不用手点 GUI）：ERROR / WARN / SUCCESS 自动标色，
  密码提示自动弹密码管理器
- **`Shift+Enter` 换行不提交**：给 AI CLI 写多行 prompt 用
- **现代 CLI 全家桶**：eza / bat / fzf / fd / zoxide / ripgrep / atuin / delta
- **`./migrate.sh`**：接管已有 `.zshrc`（搬进 `.zshrc.local`，**不是覆盖**）。
  按段落判定，写入前 `zsh -n` 验语法，写完真起一个 shell 验，起不来自动回滚
- **`./doctor.sh`**：只读自检；`--fix` 逐项修；`--profile` 用 zprof 点名慢插件
- **`./uninstall.sh`**：一键还原，`--dry-run` 先看清单。
  `.zshrc` 从备份**还原**而不是删掉；GUI 设置用 `defaults delete` 回出厂默认
- 全部写操作都能 `--dry-run` 预演

⚠️ **字体**：1.x 曾从第三方仓库拉 Operator Mono（商业字体）—— 自用是灰色地带，
随产品分发就是侵权。2.0 已移除，默认改用 Maple Mono NF CN（SIL OFL，可商用可分发）。

## [1.3.1] 及更早

早期版本的迭代记录（安装脚本、主题生成器、`.zshrc` 模板成型的过程）不在公开版列出。
从 2.0.0 开始是当前形态。
