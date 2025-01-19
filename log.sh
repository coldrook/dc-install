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

# 函数: 替换配置块
replace_config() {
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
}

# 函数: 恢复配置
restore_config() {
  if [[ -f /etc/logrotate.d/rsyslog.bak ]]; then
    echo "正在恢复 /etc/logrotate.d/rsyslog..."
    sudo cp /etc/logrotate.d/rsyslog.bak /etc/logrotate.d/rsyslog
    echo "恢复完成。"
  else
    echo "错误: 没有找到备份文件 /etc/logrotate.d/rsyslog.bak。"
  fi
}

# 主菜单
while true; do
  echo "请选择操作:"
  echo "1. 修改 logrotate 配置"
  echo "2. 恢复 logrotate 配置"
  echo "3. 退出"
  read -p "请输入选项 (1/2/3): " choice

  case $choice in
    1)
      # 备份 /etc/logrotate.d/rsyslog
      if [[ -f /etc/logrotate.d/rsyslog ]]; then
        echo "正在备份 /etc/logrotate.d/rsyslog..."
        sudo cp /etc/logrotate.d/rsyslog /etc/logrotate.d/rsyslog.bak
      else
        echo "警告: /etc/logrotate.d/rsyslog 文件不存在，跳过备份。"
      fi
      replace_config
      break
      ;;
    2)
      restore_config
      break
      ;;
    3)
      echo "退出脚本。"
      exit 0
      ;;
    *)
      echo "无效选项，请重新选择。"
      ;;
  esac
done

# 检查 logrotate 服务状态
echo "正在检查 logrotate 服务状态..."
echo "logrotate.service 状态:"
sudo systemctl status logrotate.service
echo "logrotate.timer 状态:"
sudo systemctl status logrotate.timer

echo "操作完成。"
exit 0
