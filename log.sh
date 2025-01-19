#!/bin/bash

# 1. 检查软件包是否已安装
echo "检查软件包是否已安装..."
if ! dpkg -s logrotate >/dev/null 2>&1; then
  echo "logrotate 未安装，正在安装..."
  sudo apt update
  sudo apt install -y logrotate
else
  echo "logrotate 已安装，跳过安装。"
fi

if ! dpkg -s cron >/dev/null 2>&1; then
  echo "cron 未安装，正在安装..."
  sudo apt install -y cron
else
  echo "cron 已安装，跳过安装。"
fi

if ! dpkg -s rsyslog >/dev/null 2>&1; then
  echo "rsyslog 未安装，正在安装..."
  sudo apt install -y rsyslog
else
  echo "rsyslog 已安装，跳过安装。"
fi

# 2. 检查 /etc/logrotate.d 目录是否存在
if [ ! -d "/etc/logrotate.d" ]; then
    echo "/etc/logrotate.d 目录不存在，正在创建..."
    sudo mkdir -p /etc/logrotate.d
fi

# 3. 检查 /etc/logrotate.d/rsyslog 文件是否存在
if [ -f "/etc/logrotate.d/rsyslog" ]; then
    echo "/etc/logrotate.d/rsyslog 文件存在，正在修改..."

    # 合并操作：检查并修改 maxsize, rotate, weekly 和 compress
    sudo sed -i '/{/{
        /maxsize 100M/!a \ \ \ \ maxsize 100M
        s/rotate [0-9]\+/rotate 3/g
        s/daily/weekly/g
        /compress/!a \ \ \ \ compress
    }' /etc/logrotate.d/rsyslog
    echo "已确保 maxsize 100M, rotate 3, weekly 和 compress 配置在 {} 内部。"

else
    echo "/etc/logrotate.d/rsyslog 文件不存在，正在创建..."
    # 创建文件，并写入配置
    cat << EOF | sudo tee /etc/logrotate.d/rsyslog
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
fi

# 4. 检查服务状态
echo "检查服务状态..."
echo "logrotate 服务状态:"
sudo systemctl status logrotate.service
echo ""
echo "logrotate 定时器状态:"
sudo systemctl status logrotate.timer

echo "配置完成。"
