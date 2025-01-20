#!/bin/bash

# 打印欢迎信息
echo "欢迎使用 Dockge 安装/卸载脚本!"
echo "请选择操作:"
echo "1. 安装/更新 Dockge"
echo "2. 卸载 Dockge"
read -p "请输入选项 (1/2): " operation

case "$operation" in
    1)
        # 安装/更新部分
        echo "请选择安装位置:"
        echo "1. 默认位置 (/opt/stacks 和 /opt/dockge)"
        echo "2. Home 位置 (/home/stacks 和 /home/dockge)"
        echo "3. 自定义位置"
        read -p "请输入选项 (1/2/3): " choice

        case "$choice" in
            1)
                echo "选择默认位置安装/更新..."
                STACKS_PATH="/opt/stacks"
                DOCKGE_PATH="/opt/dockge"
                PORT="5001" # 默认端口
                ;;
            2)
                echo "选择 Home 位置安装/更新..."
                STACKS_PATH="/home/stacks"
                DOCKGE_PATH="/home/dockge"
                read -p "请输入自定义端口号 (例如: 57949): " PORT
                # 检查端口是否为空
                if [ -z "$PORT" ]; then
                  PORT="5001" # 如果用户没有输入，则使用默认端口
                fi
                ;;
            3)
                read -p "请输入自定义 stacks 目录路径 (例如: /mnt/my_stacks): " STACKS_PATH
                read -p "请输入自定义 dockge 目录路径 (例如: /mnt/my_dockge): " DOCKGE_PATH
                read -p "请输入自定义端口号 (例如: 57949): " PORT

                # 检查路径是否为空
                if [ -z "$STACKS_PATH" ] || [ -z "$DOCKGE_PATH" ]; then
                  echo "错误：自定义路径不能为空。请重新运行脚本。"
                  exit 1
                fi
                ;;
            *)
                echo "无效的选项，请重新运行脚本。"
                exit 1
                ;;
        esac

        # 检查 Dockge 是否已安装
        if [ -d "$DOCKGE_PATH" ]; then
            echo "检测到 Dockge 已安装，正在尝试更新..."
            cd "$DOCKGE_PATH"
             # 下载 compose.yaml
            echo "正在下载 compose.yaml 文件..."
            if [ "$choice" -eq 1 ]; then
              curl "https://raw.githubusercontent.com/louislam/dockge/master/compose.yaml" --output compose.yaml
            else
              curl "https://dockge.kuma.pet/compose.yaml?port=$PORT&stacksPath=$STACKS_PATH" --output compose.yaml
            fi

             if [ $? -ne 0 ]; then
                echo "下载 compose.yaml 文件失败，请检查网络连接。"
                exit 1
            fi
            docker compose pull
            docker compose up -d
            if [ $? -ne 0 ]; then
            echo "更新 Dockge 失败，请检查 Docker 是否正常运行。"
            exit 1
            fi

        else
            echo "未检测到 Dockge 安装，正在进行安装..."
             # 创建目录
            echo "正在创建目录：$STACKS_PATH 和 $DOCKGE_PATH"
            mkdir -p "$STACKS_PATH"
            mkdir -p "$DOCKGE_PATH"

            # 进入 dockge 目录
            cd "$DOCKGE_PATH"

            # 下载 compose.yaml
            echo "正在下载 compose.yaml 文件..."
            if [ "$choice" -eq 1 ]; then
                curl "https://raw.githubusercontent.com/louislam/dockge/master/compose.yaml" --output compose.yaml
            else
                curl "https://dockge.kuma.pet/compose.yaml?port=$PORT&stacksPath=$STACKS_PATH" --output compose.yaml
            fi

            if [ $? -ne 0 ]; then
                echo "下载 compose.yaml 文件失败，请检查网络连接。"
                exit 1
            fi

            # 启动 Dockge
            echo "正在启动 Dockge..."
            docker compose up -d

            if [ $? -ne 0 ]; then
                echo "启动 Dockge 失败，请检查 Docker 是否正常运行。"
                exit 1
            fi
        fi

        # 获取所有 IPv4 地址，并取最后一个
        IPV4_ADDRESSES=$(ip -4 route get 1 2>/dev/null | grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | tail -n 1)
        if [ -z "$IPV4_ADDRESSES" ]; then
            IPV4_ADDRESSES=$(hostname -I | awk '{print $NF}' 2>/dev/null)
        fi
        
        # 获取 IPv6 地址
        IPV6_ADDRESS=$(ip -6 route get 1 2>/dev/null | awk '{print $NF;exit}')

        # 选择 IP 地址
        if [ -n "$IPV4_ADDRESSES" ]; then
            IP_ADDRESS="$IPV4_ADDRESSES"
        elif [ -n "$IPV6_ADDRESS" ] && [[ "$IPV6_ADDRESS" != "1" ]]; then
            IP_ADDRESS="[$IPV6_ADDRESS]" # IPv6 地址需要用方括号括起来
        else
            IP_ADDRESS="localhost" # 如果都获取不到，则使用 localhost
            echo "无法获取有效的 IPv4 或 IPv6 地址，回退到使用 localhost。"
        fi

        # 输出访问地址
        echo "Dockge 安装/更新完成!"
        echo "访问地址：http://$IP_ADDRESS:$PORT"
        echo "请使用 docker ps 查看容器是否正常运行"
        ;;
    2)
        # 卸载部分
        echo "开始卸载 Dockge..."
        echo "请选择卸载位置:"
        echo "1. 默认位置 (/opt/stacks 和 /opt/dockge)"
        echo "2. Home 位置 (/home/stacks 和 /home/dockge)"
        echo "3. 自定义位置"
        read -p "请输入选项 (1/2/3): " uninstall_choice

        case "$uninstall_choice" in
            1)
                echo "选择默认位置卸载..."
                STACKS_PATH="/opt/stacks"
                DOCKGE_PATH="/opt/dockge"
                ;;
            2)
                echo "选择 Home 位置卸载..."
                STACKS_PATH="/home/stacks"
                DOCKGE_PATH="/home/dockge"
                ;;
            3)
                read -p "请输入自定义 stacks 目录路径 (例如: /mnt/my_stacks): " STACKS_PATH
                read -p "请输入自定义 dockge 目录路径 (例如: /mnt/my_dockge): " DOCKGE_PATH
                if [ -z "$STACKS_PATH" ] || [ -z "$DOCKGE_PATH" ]; then
                    echo "错误：自定义路径不能为空。请重新运行脚本。"
                    exit 1
                fi
                ;;
            *)
                echo "无效的选项，请重新运行脚本。"
                exit 1
                ;;
        esac


        # 停止并删除容器
        echo "正在停止并删除 Dockge 容器..."
        cd "$DOCKGE_PATH"
        docker compose down

        # 获取 Dockge 使用的镜像
        DOCKGE_IMAGE=$(docker compose images | awk 'NR==2 {print $3}')

         # 删除镜像
        if [ -n "$DOCKGE_IMAGE" ]; then
            echo "正在删除 Dockge 镜像：$DOCKGE_IMAGE"
            docker rmi "$DOCKGE_IMAGE"
        fi

        # 获取上一级目录
        DOCKGE_PARENT_DIR=$(dirname "$DOCKGE_PATH")

        # 压缩备份文件
        BACKUP_FILE="$DOCKGE_PARENT_DIR/dockge_backup_$(date +%Y%m%d%H%M%S).tar.gz"
        echo "正在备份文件到：$BACKUP_FILE"
        tar -czvf "$BACKUP_FILE" "$DOCKGE_PATH"

         # 检查备份是否成功
        if [ $? -ne 0 ]; then
            echo "备份文件失败，请检查是否有权限写入备份文件。"
            exit 1
        fi

        # 删除目录
        echo "正在删除安装目录：$DOCKGE_PATH 和 $STACKS_PATH"
        rm -rf "$DOCKGE_PATH"
        rm -rf "$STACKS_PATH"

        # 删除 Docker 卷
        echo "正在清理 Docker 卷..."
        docker volume prune -f

        # 删除 Docker 网络
        echo "正在清理 Docker 网络..."
        docker network prune -f

        # 删除未使用的镜像
        echo "正在清理未使用的 Docker 镜像..."
        docker image prune -a -f

        echo "Dockge 卸载完成！备份文件已保存到：$BACKUP_FILE"
        ;;
    *)
        echo "无效的选项，请重新运行脚本。"
        exit 1
        ;;
esac

