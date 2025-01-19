#!/bin/bash

# 检查是否以 root 用户运行
if [[ $EUID -ne 0 ]]; then
  echo "错误: 请使用 sudo 或 root 用户运行此脚本。"
  exit 1
fi

# 安装必要的软件包
echo "安装 logrotate, cron 和 rsyslog..."
sudo apt update
sudo apt install -y logrotate cron rsyslog

# 获取 /etc/logrotate.d/rsyslog 文件内容
if [[ ! -f /etc/logrotate.d/rsyslog ]]; then
  echo "错误: /etc/logrotate.d/rsyslog 文件不存在。"
  exit 1
fi
echo "原始 /etc/logrotate.d/rsyslog 文件内容:"
sudo cat /etc/logrotate.d/rsyslog
OLD_CONFIG=$(sudo cat /etc/logrotate.d/rsyslog)

# 定义新的配置内容
NEW_CONFIG=$(cat <<EOF
{
    weekly
    rotate 3
    maxsize 100M
    missingok
    notifempty
    compress
    delaycompress
    sharedscripts
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}
EOF
)
echo "新的配置内容:"
echo "$NEW_CONFIG"

# 使用 awk 替换 {} 之间的内容 (非贪婪匹配)
echo "修改 /etc/logrotate.d/rsyslog 文件..."
MODIFIED_CONFIG=$(echo "$OLD_CONFIG" | awk -v new_config="$NEW_CONFIG" '{
    print "原始行: " $0
    gsub(/\{[^\}]*\}/, new_config)
    print "修改后行: " $0
    print
}')
echo "修改后的配置内容:"
echo "$MODIFIED_CONFIG"

# 将修改后的内容写回文件
echo "$MODIFIED_CONFIG" | sudo tee /etc/logrotate.d/rsyslog > /dev/null
echo "写入文件完成"

# 检查 logrotate 服务状态
echo "检查 logrotate 服务状态..."
sudo systemctl status logrotate.service
sudo systemctl status logrotate.timer

# 检查文件内容
echo "修改后的 /etc/logrotate.d/rsyslog 文件内容:"
sudo cat /etc/logrotate.d/rsyslog

echo "logrotate 配置完成。"
exit 0
