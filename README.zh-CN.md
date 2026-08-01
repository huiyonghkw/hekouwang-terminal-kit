<h1 align="center">hekouwang-terminal-kit</h1>

<p align="center">
  <b>AI 时代的终端，值得重新配一次。</b><br>
  无边框毛玻璃 · ERROR 自动标色 · Shift+Enter 写多行 prompt<br>
  配置即代码 · 敢装也敢卸
</p>

<p align="center">
  <a href="README.md">English</a> · <a href="README.zh-CN.md">简体中文</a>
  &nbsp;·&nbsp;
  <img src="https://img.shields.io/badge/license-MIT-00d4aa" alt="MIT">
</p>

<p align="center">
  <img src="docs/images/01-cover.png" width="88%" alt="装完后的终端工作台">
</p>

---

## 一分钟装上

需要：一台 Mac、能联网、会打开「终端」。

```bash
git clone https://github.com/huiyonghkw/hekouwang-terminal-kit.git
cd hekouwang-terminal-kit

./install.sh --dry-run    # 先看：改哪些文件、写哪些系统设置、什么绝对不碰
./install.sh              # 确认后再真装
```

国内网络卡住（`portable-ruby` / `SSL_ERROR_SYSCALL`）时：

```bash
CN=1 ./install.sh
```

已经有自己的 `.zshrc`？先迁移，别直接覆盖：

```bash
./migrate.sh              # 先看报告
./migrate.sh --apply      # 确认后再执行
```

跑完看到 `✅ 全部完成！`，关掉自带终端，打开 **iTerm2** 即生效。
细节与常见卡点 → [`docs/manual.zh-CN.md`](docs/manual.zh-CN.md)

---

## 装完你会得到

- **好看**：Minimal 无边框 · 毛玻璃 · 暗色三套社区主题
- **好用**：`ls`/`cat`/`git diff` 带色 · `Ctrl+R` 搜历史 · `z` 跳目录 · `Shift+Enter` 换行不提交
- **省心**：ERROR/WARN 自动标色 · 密码提示弹管理器 · 配置全在文件里，换电脑重跑即回
- **敢卸**：`./uninstall.sh` 从备份还原，GUI 设置恢复出厂

| 每天用的 | 做什么 |
|---|---|
| `ls` / `cat` / `git diff` | 已换成 eza / bat / delta，直接敲旧命令 |
| `Ctrl+R` / `Ctrl+T` / `z 词` | 搜历史 · 搜文件 · 跳目录 |
| `./theme.sh` | 列主题 / 切换（开源版 3 套社区色） |
| `./doctor.sh` · `--fix` · `--profile` | 体检 · 自动修 · 揪出拖慢启动的插件 |
| `./uninstall.sh` | 整套卸干净 |

完整命令与快捷键 → [`references/shortcuts.md`](references/shortcuts.md)

---

## 同一台机器，同一条命令，只差一个档位

<table>
<tr>
<th width="50%">开源版（免费 · MIT）</th>
<th width="50%">付费版 ¥19.9</th>
</tr>
<tr>
<td><img src="docs/images/cmp-iterm2-free.png" alt="免费：eza / bat / git diff 各说各话"></td>
<td><img src="docs/images/cmp-iterm2-paid.png" alt="付费：四样同一份色板"></td>
</tr>
</table>

左边不是「配色难看」——是三个工具各用各的色，还跟终端底色不搭。
右边是**同一份色板生成的**，所以是一家人。

我交过学费：手工维护的 Warp 主题，注释写着「与 iTerm2 完全一致」，实际 **16 个色槽错了 8 个**。

| | 开源版 | 付费版 |
|---|---|---|
| 安装 / 换肤 / 体检 / 卸载全套脚本 | ✅ | ✅ |
| Minimal + 毛玻璃 + Triggers + Shift+Enter + 现代 CLI | ✅ | ✅ |
| 主题 | 3 套社区 | + 4 套品牌（含 2 套亮色） |
| 一份色板 → 四终端 + bat/fzf/eza/git diff/tmux/VS Code | — | ✅ |
| 跟随系统深浅色 · 项目 tab 变色 · 色板推导 / 导入 | — | ✅ |
| Claude Code Skill（跟 AI 说「换亮色」「为什么慢」它自己跑） | — | ✅ |

开源版不是试用版——脚本一个不少，可以一直用。
付费买的是：**色板走出 iTerm2**，以及把这套教会 AI 的那份 Skill。

**想要付费版** → [购买页](https://huiyonghkw.github.io/hekouwang-terminal-kit/)（七天不合用直接退）
或微信 **`hekouwang`**（备注「终端套装」）

付费版怎么解锁、多终端与工作区怎么用 → 见付费包 / 付费仓内的买家首页（不在本开源仓）

---

## 出问题了

```bash
./doctor.sh            # 哪一步不对
./doctor.sh --fix      # 逐项确认后自动修
./doctor.sh --profile  # 启动慢？点名是哪个插件
./uninstall.sh         # 后悔了就卸
```

更多排查 → [`docs/manual.zh-CN.md`](docs/manual.zh-CN.md) 常见问题一节

---

## 文档

| 想做什么 | 去哪 |
|---|---|
| 装机细节 / 日常 / 进阶 / FAQ | [`docs/manual.zh-CN.md`](docs/manual.zh-CN.md) |
| 快捷键 | [`references/shortcuts.md`](references/shortcuts.md) |
| 更新记录 | [`CHANGELOG.md`](CHANGELOG.md) |
| English | [`README.md`](README.md) · [`docs/manual.md`](docs/manual.md) |

## License

开源版 [MIT](LICENSE.txt)。付费件另见付费包内授权说明。
