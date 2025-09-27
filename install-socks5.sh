#!/bin/bash
# 一键安装 Socks5 代理 (Ubuntu/Debian)
# Author: Ray

set -e

# ---------- 自动修复 CRLF 换行符 ----------
sed -i 's/\r$//' "$0" 2>/dev/null || true

echo "========== Socks5 一键安装脚本 =========="

# 检查 root 权限
if [ "$(id -u)" != "0" ]; then
  echo "❌ 请使用 root 权限运行此脚本"
  exit 1
fi

# 输入配置参数
read -p "请输入 Socks5 端口 (默认 1080): " PORT
PORT=${PORT:-1080}

read -p "请输入 Socks5 用户名 (默认 socksuser): " USER
USER=${USER:-socksuser}

read -p "请输入 Socks5 密码 (默认 sockspass): " PASS
PASS=${PASS:-sockspass}

# 获取公网 IP
IP=$(curl -s ipv4.icanhazip.com || wget -qO- ipv4.icanhazip.com)

# 安装 dante-server
apt update -y
apt install -y dante-server

# 备份原配置
mv /etc/danted.conf /etc/danted.conf.bak 2>/dev/null || true

# 写入新配置
cat > /etc/danted.conf <<EOF
logoutput: syslog

internal: 0.0.0.0 port = ${PORT}
external: $(ip route get 1 | awk '{print $5;exit}')

method: username

user.notprivileged: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    command: bind connect udpassociate
    log: connect disconnect error
}
EOF

# 创建 socks5 用户
id -u ${USER} &>/dev/null || useradd -M -s /bin/false ${USER}
echo "${USER}:${PASS}" | chpasswd

# 启动并设置开机自启
systemctl enable danted
systemctl restart danted

echo "======================================"
echo "✅ Socks5 安装完成"
echo "服务器 IP: ${IP}"
echo "端口: ${PORT}"
echo "用户名: ${USER}"
echo "密码: ${PASS}"
echo "配置文件: /etc/danted.conf"
echo "======================================"
