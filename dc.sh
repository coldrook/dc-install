#!/bin/bash

# 安装 Docker
echo "安装 Docker..."
sudo curl -sSL get.docker.com | sh

# 安装 Docker Compose
echo "安装 Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 验证 Docker Compose 安装
echo "验证 Docker Compose 版本..."
docker-compose --version

# 配置 Docker 日志大小限制
echo "配置 Docker 日志大小限制..."
sudo mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
        "log-driver": "json-file",
        "log-opts": {
                "max-file": "3",
                "max-size": "10m"
        }
}
EOF

# 重启 Docker 服务
echo "重启 Docker 服务..."
sudo systemctl daemon-reload
sudo systemctl restart docker

echo "Docker 安装和配置完成！"
