# MacBook 安全自查手册

装过来路不明或权限很大的软件之后担心安全?这套工具帮你系统性地把 MacBook 查一遍。

包含:

- `audit.sh` —— 一键安全自查脚本(**只读**,不修改系统任何东西)
- 本手册 —— 怎么运行、结果怎么看、查出问题怎么处理

---

## 1. 快速开始

在你的 MacBook 上打开「终端」(Terminal),执行:

```bash
# 下载本仓库(或直接把 audit.sh 拷到 Mac 上)
git clone https://github.com/MrLidonghai/MrLidonghai.git
cd MrLidonghai/macbook-security-audit

chmod +x audit.sh
sudo ./audit.sh        # 推荐用 sudo,能查得更全;不放心可先不加 sudo 跑一遍
```

跑完后报告自动保存在 **桌面**,文件名类似 `mac_audit_report_20260714_120000.txt`。

在报告里搜索 `[!!]`,每一条都是需要你人工确认的点。

> 脚本只做“读取和列出”,不会删除、关闭、修改任何配置,随时可以放心运行。

---

## 2. 关于你装的 “Open car”

这个名字对应两个常见软件,隐患完全不同,脚本对两种都做了检测(报告第 2、3 节):

### 情况 A:OpenCore / OpenCore Legacy Patcher(给老 Mac 装新系统的引导工具)

它本身是知名开源项目,**不是病毒**,但为了工作它通常会:

- 关闭 SIP(系统完整性保护)
- 削弱 AMFI / 库验证(代码签名检查)
- 注入未签名的驱动

这意味着系统的“出厂防护”被拆掉了一部分,恶意软件一旦进来会更容易站稳脚跟。

**处理建议:**
- 如果你的 Mac 其实是官方支持当前系统的机型 → 建议卸载 OCLP、重装官方系统、重新开启 SIP(`csrutil enable`,需在恢复模式执行)。
- 如果必须靠 OCLP 才能用新系统 → 只从官方渠道 [github.com/dortania/OpenCore-Legacy-Patcher](https://github.com/dortania/OpenCore-Legacy-Patcher) 更新;其余防护(FileVault、防火墙、不装来路不明软件)都要拉满,弥补 SIP 缺失。

### 情况 B:OpenClaw 之类的开源 AI 助手 / 自动化代理

这类工具的特点是:**能执行命令、读写你的文件、访问网络,配置里还存着你的 API 密钥**,等于把电脑钥匙交给了它。风险点:

1. 它保存过的所有密钥(Anthropic/OpenAI key、各种 token)都可能已被读取
2. 若它开了本地网关端口且绑定到 `0.0.0.0`,同一 Wi-Fi 下的人可能直接访问
3. 它安装的技能/插件可能来自第三方,质量参差

**不再使用时的彻底卸载步骤:**

```bash
# 1. 停止并删除相关服务(先看有哪些)
launchctl list | grep -iE "openclaw|clawdbot|moltbot"
ls ~/Library/LaunchAgents | grep -iE "openclaw|clawdbot|moltbot"
# 确认后: launchctl bootout gui/$(id -u)/<服务名> 并删除对应 plist

# 2. 删除程序与配置(里面有密钥,删除前不要发给别人)
rm -rf ~/.openclaw ~/.clawdbot ~/.moltbot
npm uninstall -g openclaw 2>/dev/null

# 3. 【最重要】轮换所有它接触过的密钥:
#    - Anthropic/OpenAI 控制台里 revoke 旧 key、生成新 key
#    - 它连接过的 Telegram/WhatsApp/Slack 等的 bot token 全部重置
```

---

## 3. 报告各章节怎么看

| 章节 | 查什么 | 什么算有问题 |
|---|---|---|
| 1 核心防护 | SIP / Gatekeeper / FileVault / 防火墙 | 任何一项是 disabled(装过 OCLP 时 SIP 关闭是预期的,见上) |
| 2 OpenCore | 引导注入、第三方内核扩展 | 你不认识的 kext / 系统扩展 |
| 4 持久化项 | 开机自启、LaunchAgents/Daemons、cron | 随机命名的 plist、指向 `/tmp` 或用户目录深处的可执行文件 |
| 5 描述文件 | MDM / 配置描述文件 | 存在任何不是你或公司主动装的描述文件(可远程控制整台电脑,**发现即删**) |
| 6 网络 | 监听端口、代理、hosts、DNS | 陌生程序监听端口;你没设置过的代理/PAC;hosts 里有陌生条目 |
| 7 账户远程 | 隐藏账户、SSH、authorized_keys、sudoers | 陌生账户;不是你放的 SSH 公钥;远程登录莫名开启 |
| 8 Shell 配置 | .zshrc 等里的 `curl \| sh`、base64 解码执行 | 命中的任何一条 |
| 9 软件与扩展 | 最近安装的 pkg、签名校验、浏览器扩展 | 不记得装过的软件;签名校验失败的 App;陌生浏览器扩展 |
| 10 隐私权限 | 辅助功能 / 完全磁盘访问 / 录屏 / 键盘监控 | **陌生程序出现在这四类权限里 = 最高危**,立即移除权限并卸载 |

---

## 4. 查出问题后的处置顺序

1. **断网处置**(确认有恶意软件时):先关 Wi-Fi 再清理,防止数据继续外传。
2. **移除持久化**:删除对应的 LaunchAgent/LaunchDaemon plist(先 `launchctl bootout`),删除描述文件(系统设置 > 通用 > 设备管理)。
3. **卸载程序本体**并清理 `~/Library/Application Support/<名字>` 残留。
4. **收回权限**:系统设置 > 隐私与安全性,把辅助功能/完全磁盘访问/录屏/输入监控里所有陌生条目移除。
5. **改密码、换密钥**:
   - Apple ID、开机密码、浏览器里保存的重要账号密码
   - 所有 API key、SSH key、云服务 token(凡是可疑软件可能读到的都换)
   - 开启所有重要账号的两步验证
6. **拿不准就重装**:时间机器备份*资料*(不要备份应用和系统),抹掉磁盘全新安装 macOS,是最彻底的方案。老机型上要注意:重装官方系统前先确认机型支持,OCLP 机器重装流程见其官方文档。
7. **补一层保护**(可选):跑一次免费的 [KnockKnock](https://objective-see.org/products/knockknock.html)(Objective-See 出品,macOS 安全界口碑工具)交叉验证持久化项;日常可装同家的 BlockBlock / LuLu。

---

## 5. 日常安全习惯清单

- [ ] 系统和浏览器保持自动更新
- [ ] FileVault 开启,防火墙开启
- [ ] 软件只从 App Store / 官网 / Homebrew 装,不用破解版
- [ ] 给任何软件“辅助功能/完全磁盘访问”权限前想三秒
- [ ] AI 助手类工具用独立的、限额的 API key,不复用主 key
- [ ] 重要账号全部开两步验证
- [ ] 每隔几个月重跑一次 `audit.sh` 对比报告变化
