#!/bin/bash

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo "Docker未安装，请先安装Docker。"
    exit 1
fi

# 检查Docker Compose是否安装
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose未安装，请先安装Docker Compose。"
    exit 1
fi

# 列出所有正在运行的Docker容器
echo "正在列出所有正在运行的Docker容器..."
running_containers=$(docker ps --format "{{.Names}}")

if [ -z "$running_containers" ]; then
    echo "没有正在运行的容器。"
else
    echo "正在运行的容器列表："
    echo "$running_containers"
fi

# 列出所有正在运行的Docker Compose服务
echo "正在列出所有正在运行的Docker Compose服务..."
running_compose_services=$(docker-compose ps --services --filter "status=running")

if [ -z "$running_compose_services" ]; then
    echo "没有正在运行的Docker Compose服务。"
else
    echo "正在运行的Docker Compose服务列表："
    echo "$running_compose_services"
fi

# 选择容器或服务
read -p "请输入要操作的容器名称或服务名称（输入 'exit' 退出）： " name

if [ "$name" == "exit" ]; then
    exit 0
fi

# 检查容器是否存在
if echo "$running_containers" | grep -wq "$name"; then
    is_container=true
    is_service=false
else
    is_container=false
    is_service=false
fi

# 检查服务是否存在
if echo "$running_compose_services" | grep -wq "$name"; then
    is_container=false
    is_service=true
fi

if ! $is_container && ! $is_service; then
    echo "容器或服务 '$name' 不存在。"
    exit 1
fi

# 选择操作
echo "请选择操作："
echo "1. 停止容器/服务"
echo "2. 删除容器/服务"
echo "3. 更新容器/服务"
read -p "输入选择 (1/2/3)： " choice

case $choice in
    1)
        # 停止容器或服务
        if $is_container; then
            echo "正在停止容器 '$name'..."
            docker stop "$name"
        else
            echo "正在停止Docker Compose服务 '$name'..."
            docker-compose stop "$name"
        fi
        ;;
    2)
        # 删除容器或服务
        if $is_container; then
            echo "正在删除容器 '$name'..."
            docker rm "$name"
        else
            echo "正在删除Docker Compose服务 '$name'..."
            docker-compose rm -f "$name"
        fi
        ;;
    3)
        # 更新容器或服务
        if $is_container; then
            # 假设更新意味着重建并运行容器
            echo "正在更新容器 '$name'..."
            image_name=$(docker inspect --format='{{.Config.Image}}' "$name")
            if [ -z "$image_name" ]; then
                echo "无法确定容器 '$name' 的镜像名称。"
                exit 1
            fi

            # 停止并删除容器
            docker stop "$name"
            docker rm "$name"

            # 重新构建镜像
            echo "正在构建镜像 '$image_name'..."
            docker build -t "$image_name" .

            # 运行新的容器
            echo "正在运行新的容器 '$name'..."
            docker run -d --name "$name" "$image_name"
        else
            echo "正在更新Docker Compose服务 '$name'..."
            docker-compose up -d --no-deps --build "$name"
        fi
        ;;
    *)
        echo "无效的选择。"
        ;;
esac

echo "操作完成。"
