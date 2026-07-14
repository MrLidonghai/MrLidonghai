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

## 2. OpenClaw 的已知安全风险(为什么你的担心是有道理的)

OpenClaw(前身 Clawdbot / MoltBot)是一个常驻后台的 AI 代理:**能执行 shell 命令、读写全部文件、访问网络、接入 Telegram/WhatsApp 等聊天软件,配置里明文保存着 API 密钥**。2026 年初以来,安全社区披露了多起与它相关的严重问题:

| 风险 | 具体情况 |
|---|---|
| **RCE 漏洞** | [CVE-2026-25253](https://www.kaspersky.com/blog/openclaw-vulnerabilities-exposed/55263/)(CVSS 8.8):攻击者可远程执行代码、完全接管代理;另有 CVE-2026-27487(macOS 钥匙串集成的命令注入) |
| **公网暴露** | 网关(默认端口 **18789**)若绑定 `0.0.0.0`,任何人可直接连入。[SecurityScorecard 发现 13.5 万+ 实例暴露公网](https://www.penligent.ai/hackinglabs/multiple-hacking-groups-exploit-openclaw-instances-to-steal-api-keys-and-deploy-malware/),其中 1.5 万可被远程执行代码;[Bitsight 也扫到 3 万+](https://www.bitsight.com/blog/openclaw-ai-security-risks-exposed-instances) |
| **明文密钥** | Anthropic/OpenAI key、Telegram bot token 等都明文存在 `~/.openclaw/` 下,研究者已实际拿到过[受害者的 API 密钥、Slack 账户和数月完整聊天记录](https://www.oasis.security/blog/openclaw-vulnerability) |
| **恶意技能** | 技能市场 ClawHub 上 [2857 个技能中发现 341 个恶意](https://blog.cyberdesserts.com/openclaw-malicious-skills-security/),其中 335 个传播 **AMOS 窃密木马**(专偷 macOS 钥匙串、浏览器密码、加密货币钱包) |
| **提示注入** | 别人给你的 bot 发消息、或它读到的网页/文件内容,都可能[诱导代理执行恶意操作](https://www.giskard.ai/knowledge/openclaw-security-vulnerabilities-include-data-leakage-and-prompt-injection-risks) |

脚本的 **第 3 节** 会针对这些逐项检查:版本、网关端口绑定、已装技能清单、明文密钥文件、launchd 服务、消息平台接入。

### 2a. 如果你想【继续使用】OpenClaw

1. 立即升级到最新版(修复了 CVE-2026-25253):`npm update -g openclaw`
2. 确保网关只监听本机:配置中 `gateway.bind` 设为 `127.0.0.1`(loopback),并设置访问令牌
3. 把已装技能全部过一遍,不能确认来源的删掉;以后只装能看到源码、作者可信的技能
4. 给它单独的、设了额度上限的 API key,别用你的主 key
5. 别让它接触 SSH 私钥、钱包、公司代码等高价值目录(用独立 macOS 账户跑它是最干净的隔离)

### 2b. 如果你决定【彻底卸载】(不再用时推荐)

按官方卸载文档([docs.openclaw.ai/install/uninstall](https://docs.openclaw.ai/install/uninstall))执行:

```bash
# 1. 停掉并卸载网关服务
openclaw gateway uninstall
# 如果命令已不可用, 手动清理 launchd(新旧版本的服务名都查一遍):
launchctl bootout gui/$UID/ai.openclaw.gateway 2>/dev/null
launchctl bootout gui/$UID/com.openclaw.gateway 2>/dev/null
launchctl bootout gui/$UID/com.clawdbot.gateway 2>/dev/null
rm -f ~/Library/LaunchAgents/{ai.openclaw,com.openclaw,com.clawdbot}.gateway.plist

# 2. 删除 CLI、应用和全部状态/配置(里面有密钥,删除前不要把目录发给别人)
npm rm -g openclaw 2>/dev/null   # 用 pnpm/bun 装的对应换成 pnpm remove -g / bun remove -g
rm -rf ~/.openclaw ~/.clawdbot ~/.moltbot
rm -rf /Applications/OpenClaw.app

# 3. 验证删干净了
launchctl list | grep -iE "openclaw|clawdbot" || echo "服务已清除"
lsof -nP -iTCP:18789 -sTCP:LISTEN || echo "端口 18789 已无监听"
```

### 2c. 无论去留,这一步都必须做:轮换所有密钥

OpenClaw 保存过/能读到的密钥,一律按**已泄露**处理:

- Anthropic / OpenAI 等控制台:**作废**旧 API key,生成新的
- 它接过的 Telegram / WhatsApp / Slack / Discord bot token:全部重置
- 如果装过来源不明的技能(可能中了 AMOS 窃密木马):再加上 → 修改 macOS 登录密码和 Apple ID 密码、修改浏览器里保存的重要账号密码、转移检查加密货币钱包、并强烈建议抹盘重装系统(见第 4 节)

---

## 3. 报告各章节怎么看

| 章节 | 查什么 | 什么算有问题 |
|---|---|---|
| 1 核心防护 | SIP / Gatekeeper / FileVault / 防火墙 | 任何一项是 disabled |
| 2 引导与内核 | OpenCore 痕迹、第三方内核/系统扩展 | 你不认识的 kext / 系统扩展 |
| 3 OpenClaw | 版本、网关端口绑定、技能、明文密钥、服务 | 网关绑 `0.0.0.0`;来源不明的技能;含密钥的文件 |
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
