#!/bin/bash
# ============================================================
# hekouwang-terminal-kit — 对外链接的唯一真相源
#
# 为什么要单独一个文件：这个地址会同时出现在
#   换肤回执（theme.sh）/ 体检汇总（doctor.sh）/ 装完收尾（install.sh）
#   / README.md / README.zh-CN.md / .github/FUNDING.yml / docs/index.html
# 七个位置。写进各自的词条表就是七份拷贝，换一次渠道必漂 —— 跟付费件清单
# 被硬编码三份、同一天漂两次是同一个教训（见 release.sh 里 PAID_PATHS 的注释）。
# release.sh --check 有一道门，会拿这里的值去扫上面那些文件，对不上就拒发。
#
# ⭐ 为什么脚本里不直接写收款方式：**落地页是唯一的中转点。**
#    脚本一旦装到用户机器上就冻在那个版本了，而收款渠道是会变的
#    （现在只走微信，以后可能加爱发电 / Lemon Squeezy 收海外卡）。
#    只要所有 CTA 都指向落地页，换渠道＝改一个 HTML，已装出去的几百份脚本
#    一行都不用动、也不用逼用户升级。别图省事把二维码或收款链接写进词条表。
#
# ⚠️ 这个文件被 lib/i18n.sh 自动 source（每个脚本开头都会载 i18n.sh），
#    所以脚本里直接用 $HKW_URL_BUY 即可，不用各自再 source 一次。
# ============================================================

# 落地页 = GitHub Pages，从公开仓 main 分支的 /docs 目录出。
# ⚠️ 改这个值之前先确认 GitHub 仓库 Settings → Pages 的 Source 也跟着改，
#    否则这里指向一个 404，而所有脚本都在往那儿送人。
HKW_URL_BUY="https://huiyonghkw.github.io/hekouwang-terminal-kit/"

# 公开仓本体（README 徽章、落地页「看源码」按钮用）
HKW_URL_REPO="https://github.com/huiyonghkw/hekouwang-terminal-kit"
