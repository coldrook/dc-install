#!/bin/bash

# 检查是否以 root 用户运行
if [[ $EUID -ne 0 ]]; then
  echo "错误: 请使用 sudo 或 root 用户运行此脚本。"
  exit 1
fi

# 安装必要的软件包
echo "正在安装 logrotate, cron, 和 rsyslog..."
sudo apt update
sudo apt install -y logrotate cron rsyslog

# 备份 /etc/logrotate.d/rsyslog
if [[ -f /etc/logrotate.d/rsyslog ]]; then
  echo "正在备份 /etc/logrotate.d/rsyslog..."
  sudo cp /etc/logrotate.d/rsyslog /etc/logrotate.d/rsyslog.bak
else
  echo "警告: /etc/logrotate.d/rsyslog 文件不存在，跳过备份。"
fi

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

# 使用 awk 替换配置块
echo "使用 awk 替换配置块..."
OLD_CONFIG=$(sudo cat /etc/logrotate.d/rsyslog)
MODIFIED_CONFIG=$(echo "$OLD_CONFIG" | awk -v new_config="$NEW_CONFIG" '
BEGIN {
    in_block = 0
}
/^\{/ {
    in_block = 1
    print new_config
    next
}
/^}/ {
    in_block = 0
    next
}
{
    if (!in_block) {
        print
    }
}
')

echo "$MODIFIED_CONFIG" | sudo tee /etc/logrotate.d/rsyslog > /dev/null
echo "写入文件完成"

# 检查 logrotate 服务状态
echo "正在检查 logrotate 服务状态..."
echo "logrotate.service 状态:"
sudo systemctl status logrotate.service
echo "logrotate.timer 状态:"
sudo systemctl status logrotate.timer

echo "logrotate 配置完成。"
exit 0
