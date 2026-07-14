#!/bin/bash
# =============================================================================
# macOS 安全自查脚本 (macOS Security Audit Script)
#
# 用途: 全面检查 MacBook 上的常见安全隐患,包括:
#   - 系统核心防护状态 (SIP / Gatekeeper / FileVault / 防火墙)
#   - OpenCore / OpenCore Legacy Patcher 痕迹及其带来的防护降级
#   - OpenClaw 等开源 AI 助手/自动化工具的痕迹
#   - 持久化项 (LaunchAgents / LaunchDaemons / 登录项 / cron)
#   - 描述文件、内核扩展、系统扩展
#   - 网络监听端口、代理设置、hosts 文件
#   - 账户、sudo、SSH、远程访问
#   - Shell 配置文件中的可疑内容
#   - 最近安装的软件包、浏览器扩展
#
# 本脚本【只读】,不会修改、删除任何东西,可放心运行。
#
# 用法:
#   chmod +x audit.sh
#   ./audit.sh              # 普通模式
#   sudo ./audit.sh         # 推荐: 用 sudo 运行能检查更多系统级项目
#
# 运行结束后会在桌面生成报告: ~/Desktop/mac_audit_report_<日期>.txt
# =============================================================================

REPORT="$HOME/Desktop/mac_audit_report_$(date +%Y%m%d_%H%M%S).txt"
# sudo 运行时 HOME 是 /var/root,把报告写到真实用户桌面
if [ -n "$SUDO_USER" ]; then
    REAL_HOME=$(dscl . -read "/Users/$SUDO_USER" NFSHomeDirectory 2>/dev/null | awk '{print $2}')
    [ -n "$REAL_HOME" ] && REPORT="$REAL_HOME/Desktop/mac_audit_report_$(date +%Y%m%d_%H%M%S).txt"
else
    REAL_HOME="$HOME"
fi

exec > >(tee "$REPORT") 2>&1

section() {
    echo ""
    echo "============================================================"
    echo "== $1"
    echo "============================================================"
}

warn() {
    echo "  [!!] 注意: $1"
}

ok() {
    echo "  [OK] $1"
}

info() {
    echo "  [--] $1"
}

echo "macOS 安全自查报告"
echo "生成时间: $(date)"
echo "报告保存在: $REPORT"
[ "$(id -u)" -ne 0 ] && echo "(提示: 未用 sudo 运行,部分系统级检查会被跳过,建议 sudo ./audit.sh 再跑一次)"

# -----------------------------------------------------------------------------
section "0. 系统基本信息"
# -----------------------------------------------------------------------------
sw_vers
sysctl -n hw.model 2>/dev/null
uname -m

# -----------------------------------------------------------------------------
section "1. 系统核心防护状态 (最重要)"
# -----------------------------------------------------------------------------
# SIP (系统完整性保护)
SIP_STATUS=$(csrutil status 2>/dev/null)
echo "SIP: $SIP_STATUS"
if echo "$SIP_STATUS" | grep -qi "enabled"; then
    ok "SIP (系统完整性保护) 已开启"
else
    warn "SIP 被关闭或部分关闭! 这是 OpenCore Legacy Patcher 的典型特征, 系统防护大幅降级"
fi

# Gatekeeper
GK=$(spctl --status 2>/dev/null)
echo "Gatekeeper: $GK"
if echo "$GK" | grep -qi "enabled"; then
    ok "Gatekeeper (门禁) 已开启"
else
    warn "Gatekeeper 被关闭! 任何未签名软件都能直接运行"
fi

# FileVault
FV=$(fdesetup status 2>/dev/null)
echo "FileVault: $FV"
if echo "$FV" | grep -qi "is On"; then
    ok "FileVault 磁盘加密已开启"
else
    warn "FileVault 磁盘加密未开启, 电脑丢失时数据可被直接读取"
fi

# 应用防火墙
FW=$(defaults read /Library/Preferences/com.apple.alf globalstate 2>/dev/null)
case "$FW" in
    1|2) ok "应用防火墙已开启 (状态: $FW)" ;;
    0)   warn "应用防火墙未开启" ;;
    *)   info "无法读取防火墙状态 (可能需要 sudo)" ;;
esac

# 库验证 / AMFI (OpenCore Legacy Patcher 常见降级项)
AMFI_ARGS=$(nvram boot-args 2>/dev/null)
if echo "$AMFI_ARGS" | grep -qi "amfi"; then
    warn "boot-args 中含有 AMFI 相关参数, 代码签名验证被削弱: $AMFI_ARGS"
elif [ -n "$AMFI_ARGS" ]; then
    info "boot-args: $AMFI_ARGS (非默认, 请人工确认)"
else
    ok "boot-args 为空 (默认状态)"
fi

# XProtect / MRT 版本
info "XProtect 版本: $(defaults read /Library/Apple/System/Library/CoreServices/XProtect.bundle/Contents/Info.plist CFBundleShortVersionString 2>/dev/null || echo '未知')"

# 自动安全更新
AUTOUPD=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall 2>/dev/null)
[ "$AUTOUPD" = "1" ] && ok "自动安装安全响应更新: 开启" || info "自动安全更新状态: ${AUTOUPD:-未知}, 建议在系统设置里确认开启"

# -----------------------------------------------------------------------------
section "2. OpenCore / OpenCore Legacy Patcher 检测"
# -----------------------------------------------------------------------------
FOUND_OC=0
OC_VER=$(nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version 2>/dev/null)
if [ -n "$OC_VER" ]; then
    FOUND_OC=1
    warn "检测到 OpenCore 引导: $OC_VER"
fi
for p in "/Library/Application Support/Dortania" "/Applications/OpenCore-Patcher.app" "$REAL_HOME/Applications/OpenCore-Patcher.app"; do
    if [ -e "$p" ]; then
        FOUND_OC=1
        warn "发现 OpenCore Legacy Patcher 相关文件: $p"
    fi
done
if [ "$FOUND_OC" = "1" ]; then
    echo ""
    echo "  说明: OpenCore/OCLP 本身是知名开源项目, 不是病毒。"
    echo "  但它为了让老 Mac 跑新系统, 通常会关闭 SIP、削弱签名验证、注入未签名驱动,"
    echo "  这会让整机防护等级下降。请结合第 1 节的 SIP/Gatekeeper 状态综合判断。"
else
    ok "未发现 OpenCore / OCLP 痕迹"
fi

# 非 Apple 内核扩展
echo ""
echo "-- 非 Apple 第三方内核扩展 (kext):"
KEXTS=$(kextstat 2>/dev/null | grep -v com.apple | grep -v "^Index" | grep -v "^ *Index")
if [ -n "$KEXTS" ]; then
    echo "$KEXTS"
    warn "存在第三方内核扩展, 请逐条确认来源"
else
    ok "没有第三方内核扩展"
fi

echo ""
echo "-- 系统扩展 (System Extensions):"
systemextensionsctl list 2>/dev/null || info "无法列出系统扩展"

# -----------------------------------------------------------------------------
section "3. OpenClaw / AI 助手类工具检测"
# -----------------------------------------------------------------------------
# OpenClaw (原 Clawdbot/Moltbot) 及常见 AI agent 的配置目录与进程
FOUND_AI=0
for d in "$REAL_HOME/.openclaw" "$REAL_HOME/.clawdbot" "$REAL_HOME/.moltbot" \
         "$REAL_HOME/openclaw" "$REAL_HOME/.config/openclaw"; do
    if [ -e "$d" ]; then
        FOUND_AI=1
        warn "发现 AI 助手配置目录: $d"
    fi
done
AI_PROC=$(ps aux | grep -iE "openclaw|clawdbot|moltbot" | grep -v grep)
if [ -n "$AI_PROC" ]; then
    FOUND_AI=1
    warn "发现相关进程正在运行:"
    echo "$AI_PROC"
fi
if [ "$FOUND_AI" = "1" ]; then
    echo ""
    echo "  说明: 这类 AI 助手通常拥有执行命令、读写文件、访问网络的权限,"
    echo "  并且配置文件里往往保存着 API 密钥。如果不再使用, 建议彻底卸载,"
    echo "  并轮换其中保存过的所有密钥/令牌 (详见 README 第 4 节)。"
else
    ok "未发现 OpenClaw 等 AI 助手痕迹"
fi

# 泄露风险: 明文密钥文件
echo ""
echo "-- 家目录下常见的明文密钥/凭据文件:"
for f in "$REAL_HOME/.env" "$REAL_HOME/.aws/credentials" "$REAL_HOME/.npmrc" "$REAL_HOME/.netrc"; do
    [ -f "$f" ] && info "存在 $f (请确认里面的密钥是否还需要, 是否曾被第三方工具读取)"
done

# -----------------------------------------------------------------------------
section "4. 开机自启与持久化项 (木马最爱藏的地方)"
# -----------------------------------------------------------------------------
echo "-- 用户 LaunchAgents ($REAL_HOME/Library/LaunchAgents):"
ls -la "$REAL_HOME/Library/LaunchAgents" 2>/dev/null || info "(空)"
echo ""
echo "-- 全局 LaunchAgents (/Library/LaunchAgents):"
ls -la /Library/LaunchAgents 2>/dev/null || info "(空)"
echo ""
echo "-- 全局 LaunchDaemons (/Library/LaunchDaemons):"
ls -la /Library/LaunchDaemons 2>/dev/null || info "(空)"
echo ""
echo "  判断方法: 以上列表里, 文件名不是 com.apple.* 的都值得核实。"
echo "  常见正常项: com.google.*, com.microsoft.*, com.adobe.*, homebrew 相关。"
echo "  可疑特征: 随机字符串命名、指向 /tmp 或 ~/Library 深处的可执行文件。"
echo ""
echo "-- 每个 plist 实际执行的程序路径:"
for plist in "$REAL_HOME"/Library/LaunchAgents/*.plist /Library/LaunchAgents/*.plist /Library/LaunchDaemons/*.plist; do
    [ -f "$plist" ] || continue
    PROG=$(defaults read "$plist" ProgramArguments 2>/dev/null | sed -n '2p' | tr -d ' ",' )
    [ -z "$PROG" ] && PROG=$(defaults read "$plist" Program 2>/dev/null)
    echo "  $(basename "$plist") -> ${PROG:-?}"
done

echo ""
echo "-- 登录项 (系统设置里的'登录时打开'):"
osascript -e 'tell application "System Events" to get the name of every login item' 2>/dev/null || info "无法读取 (可能需要授权自动化权限)"

echo ""
echo "-- 后台登录项 (BTM, 含隐藏的后台服务):"
sfltool dumpbtm 2>/dev/null | grep -E "Name:|URL:" | head -80 || info "需要 sudo 才能完整读取"

echo ""
echo "-- crontab 计划任务:"
crontab -l 2>/dev/null || info "(当前用户无 crontab)"
if [ "$(id -u)" -eq 0 ] && [ -n "$SUDO_USER" ]; then
    crontab -l -u "$SUDO_USER" 2>/dev/null
fi
ls -la /usr/lib/cron/tabs 2>/dev/null

echo ""
echo "-- /etc/periodic 与 emond (老式持久化位置):"
ls -la /etc/periodic/daily /etc/periodic/weekly /etc/periodic/monthly 2>/dev/null | grep -v "^total"
ls -la /private/var/db/emondClients 2>/dev/null

# -----------------------------------------------------------------------------
section "5. 描述文件与 MDM (可静默控制整台电脑)"
# -----------------------------------------------------------------------------
if [ "$(id -u)" -eq 0 ]; then
    PROFILES=$(profiles list 2>/dev/null)
else
    PROFILES=$(profiles list -type configuration 2>/dev/null)
fi
if echo "$PROFILES" | grep -qi "no configuration profiles"; then
    ok "没有安装任何描述文件"
elif [ -n "$PROFILES" ]; then
    warn "存在描述文件, 请确认每一个都是你自己/公司主动安装的:"
    echo "$PROFILES"
else
    info "无法读取描述文件列表, 请到 系统设置 > 通用 > 设备管理 里人工查看"
fi

# -----------------------------------------------------------------------------
section "6. 网络: 监听端口 / 对外连接 / 代理 / hosts / DNS"
# -----------------------------------------------------------------------------
echo "-- 正在监听端口的进程 (LISTEN):"
lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | awk 'NR==1 || $1 !~ /^(rapportd|ControlCe|sharingd)$/'
echo ""
echo "  判断方法: 每一行的 COMMAND 都应该是你认识的软件。"
echo "  可疑特征: python/node/sh 等解释器监听端口、监听 0.0.0.0 的陌生程序。"
echo "  提示: OpenClaw 之类的 AI 网关默认监听本地端口 (如 18789/3000 等), 若绑定 0.0.0.0 则局域网可直接访问, 风险高。"

echo ""
echo "-- 当前已建立的对外连接 (前 30 条):"
lsof -nP -iTCP -sTCP:ESTABLISHED 2>/dev/null | head -31

echo ""
echo "-- 系统代理设置 (被恶意软件劫持流量的常见位置):"
for svc in "Wi-Fi" "Ethernet" "USB 10/100/1000 LAN"; do
    networksetup -getwebproxy "$svc" 2>/dev/null | grep -q "Enabled: Yes" && warn "$svc 启用了 HTTP 代理: $(networksetup -getwebproxy "$svc" | tr '\n' ' ')"
    networksetup -getsecurewebproxy "$svc" 2>/dev/null | grep -q "Enabled: Yes" && warn "$svc 启用了 HTTPS 代理: $(networksetup -getsecurewebproxy "$svc" | tr '\n' ' ')"
    networksetup -getautoproxyurl "$svc" 2>/dev/null | grep -q "Enabled: Yes" && warn "$svc 启用了 PAC 自动代理: $(networksetup -getautoproxyurl "$svc" | tr '\n' ' ')"
done
scutil --proxy | grep -E "Enable : 1" >/dev/null 2>&1 && warn "scutil 显示存在启用的代理, 请核实" || ok "未发现启用的系统代理 (若你自己开了梯子/Clash 属正常)"

echo ""
echo "-- /etc/hosts 中的非默认条目:"
HOSTS_EXTRA=$(grep -vE "^\s*#|^\s*$|localhost|broadcasthost" /etc/hosts)
if [ -n "$HOSTS_EXTRA" ]; then
    warn "hosts 文件有自定义条目 (确认是否本人添加):"
    echo "$HOSTS_EXTRA"
else
    ok "hosts 文件干净"
fi

echo ""
echo "-- DNS 服务器:"
scutil --dns 2>/dev/null | grep "nameserver\[" | sort -u

# -----------------------------------------------------------------------------
section "7. 账户 / sudo / SSH / 远程访问"
# -----------------------------------------------------------------------------
echo "-- 本机全部账户 (UID>=500 为真实用户):"
dscl . list /Users UniqueID | awk '$2 >= 500 || $2 == 0'
echo ""
echo "-- admin 组成员:"
dscacheutil -q group -a name admin | grep users
echo ""
echo "-- 隐藏账户检查 (UID 在 500 以下但有 shell 的非系统账户请人工核实):"
dscl . list /Users UniqueID | awk '$2 < 500 && $2 > 0 {print}' | head -40

echo ""
echo "-- SSH 远程登录状态:"
if [ "$(id -u)" -eq 0 ]; then
    systemsetup -getremotelogin 2>/dev/null
else
    info "需要 sudo 才能查询, 或到 系统设置 > 通用 > 共享 里查看'远程登录'"
fi

echo ""
echo "-- SSH authorized_keys (别人能免密登录你电脑的钥匙):"
for u in "$REAL_HOME"; do
    if [ -f "$u/.ssh/authorized_keys" ]; then
        warn "存在 $u/.ssh/authorized_keys, 里面每一行都代表一个可登录本机的公钥:"
        cat "$u/.ssh/authorized_keys"
    else
        ok "无 authorized_keys 文件"
    fi
done

echo ""
echo "-- sudoers 的非默认修改:"
if [ "$(id -u)" -eq 0 ]; then
    grep -vE "^\s*#|^\s*$|^Defaults|^root|^%admin|^@includedir" /etc/sudoers 2>/dev/null && warn "sudoers 有自定义条目 (见上)" || ok "sudoers 无自定义条目"
    ls -la /etc/sudoers.d/ 2>/dev/null | grep -v "^total"
else
    info "需要 sudo 才能检查 /etc/sudoers"
fi

echo ""
echo "-- 屏幕共享 / 远程管理:"
ps aux | grep -iE "ARDAgent|screensharingd" | grep -v grep && warn "远程管理/屏幕共享进程在运行, 请确认是否本人开启" || ok "未发现屏幕共享进程"

# -----------------------------------------------------------------------------
section "8. Shell 配置文件中的可疑内容"
# -----------------------------------------------------------------------------
for f in .zshrc .zprofile .zshenv .bashrc .bash_profile .profile; do
    FILE="$REAL_HOME/$f"
    [ -f "$FILE" ] || continue
    SUS=$(grep -nE "curl.*\|\s*(ba)?sh|wget.*\|\s*(ba)?sh|base64\s+(-d|--decode)|eval.*\\\$\(curl|nc -l|/dev/tcp/" "$FILE" 2>/dev/null)
    if [ -n "$SUS" ]; then
        warn "$f 中发现可疑命令:"
        echo "$SUS"
    else
        ok "$f 无明显可疑内容"
    fi
done
# launchd 环境变量注入
ls -la "$REAL_HOME/Library/LaunchAgents" 2>/dev/null | grep -i "environment" && warn "发现环境变量注入型 LaunchAgent"

# -----------------------------------------------------------------------------
section "9. 最近安装的软件与浏览器扩展"
# -----------------------------------------------------------------------------
echo "-- 最近 20 个安装的 pkg 包:"
if [ -d /var/db/receipts ]; then
    ls -lat /var/db/receipts/*.plist 2>/dev/null | head -20 | awk '{print $6, $7, $8, $NF}'
fi
echo ""
echo "-- /Applications 下最近修改的 App (前 15 个):"
ls -lat /Applications 2>/dev/null | head -16 | grep -v "^total"
echo ""
echo "-- 未签名或被 Gatekeeper 拦截过的 App 快速抽查 (前 10 个非苹果 App):"
COUNT=0
for app in /Applications/*.app; do
    [ $COUNT -ge 10 ] && break
    RES=$(codesign -dv "$app" 2>&1 | grep "Authority" | head -1)
    if ! codesign --verify --deep "$app" >/dev/null 2>&1; then
        warn "$(basename "$app") 签名校验失败或无签名"
        COUNT=$((COUNT+1))
    fi
done
[ $COUNT -eq 0 ] && ok "抽查的 App 签名均正常"

echo ""
echo "-- Homebrew 已安装 (若使用):"
if command -v brew >/dev/null 2>&1; then
    brew list 2>/dev/null | tr '\n' ' '; echo ""
elif [ -n "$SUDO_USER" ] && sudo -u "$SUDO_USER" command -v brew >/dev/null 2>&1; then
    sudo -u "$SUDO_USER" brew list 2>/dev/null | tr '\n' ' '; echo ""
else
    info "未安装 Homebrew"
fi

echo ""
echo "-- Chrome 扩展目录:"
CHROME_EXT="$REAL_HOME/Library/Application Support/Google/Chrome/Default/Extensions"
if [ -d "$CHROME_EXT" ]; then
    for ext in "$CHROME_EXT"/*/; do
        ID=$(basename "$ext")
        VERDIR=$(ls "$ext" 2>/dev/null | head -1)
        NAME=$(defaults read "$ext$VERDIR/manifest.plist" name 2>/dev/null)
        [ -z "$NAME" ] && NAME=$(python3 -c "import json,sys;print(json.load(open('$ext$VERDIR/manifest.json')).get('name',''))" 2>/dev/null)
        echo "  $ID  ${NAME:-(名称需在 chrome://extensions 查看)}"
    done
else
    info "未发现 Chrome 扩展目录"
fi
echo "  (Safari 扩展请到 Safari > 设置 > 扩展 查看; Edge 同理在 edge://extensions)"

# -----------------------------------------------------------------------------
section "10. 隐私权限 (TCC): 哪些软件拿到了高危权限"
# -----------------------------------------------------------------------------
TCC_DB="$REAL_HOME/Library/Application Support/com.apple.TCC/TCC.db"
if sqlite3 "$TCC_DB" "SELECT service, client FROM access WHERE auth_value > 0;" 2>/dev/null | head -50; then
    echo ""
    echo "  重点关注: kTCCServiceAccessibility(辅助功能=可控制电脑)、"
    echo "  kTCCServiceScreenCapture(录屏)、kTCCServiceSystemPolicyAllFiles(完全磁盘访问)、"
    echo "  kTCCServiceListenEvent(键盘监听)。陌生程序出现在这些权限里 = 高危。"
else
    info "无法直接读取 TCC 数据库 (正常, 需要完全磁盘访问权限)。"
    info "请人工检查: 系统设置 > 隐私与安全性 > 辅助功能 / 完全磁盘访问 / 录屏与系统录音 / 输入监控"
fi

# -----------------------------------------------------------------------------
section "11. 汇总"
# -----------------------------------------------------------------------------
WARN_COUNT=$(grep -c "\[!!\]" "$REPORT" 2>/dev/null || echo "?")
echo "本次检查共发现 $WARN_COUNT 条 [!!] 注意项 (在报告中搜索 [!!] 逐条查看)。"
echo ""
echo "下一步:"
echo "  1. 打开报告 (已保存到桌面), 搜索 [!!] 逐条核实"
echo "  2. 不确定的条目, 把报告发给可信的人/AI 协助分析"
echo "  3. 处置建议见仓库中的 README.md"
echo ""
echo "检查完成: $(date)"
