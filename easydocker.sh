#!/bin/bash

# 检查是否安装了 docker
if ! command -v docker &> /dev/null
then
    echo "错误: Docker 未安装。请先安装 Docker。"
    exit 1
fi

# 函数: 列出 Docker 容器并返回选择的容器 ID
function select_container() {
  local containers
  containers=$(docker container ls -a --format "{{.ID}}\t{{.Names}}\t{{.Status}}")

  if [[ -z "$containers" ]]; then
    echo "没有找到任何 Docker 容器。"
    return 1
  fi

  echo "已安装的 Docker 容器:"
  echo "---------------------------------------------------------"
  echo "编号\t容器 ID\t\t容器名称\t\t状态"
  echo "---------------------------------------------------------"

  IFS=$'\n' read -r -d '' -a container_lines <<< "$containers"
  local container_ids=()
  local container_names=()
  local count=1

  for line in "${container_lines[@]}"; do
    IFS=$'\t' read -r -a parts <<< "$line"
    container_id="${parts[0]}"
    container_name="${parts[1]}"
    container_status="${parts[2]}"
    echo "$count\t${container_id:0:12}...\t${container_name}\t\t${container_status}"
    container_ids+=("$container_id")
    container_names+=("$container_name")
    ((count++))
  done

  echo "---------------------------------------------------------"
  read -p "请选择要操作的容器编号 (或按 'q' 退出): " choice

  if [[ "$choice" == "q" ]]; then
    return 1 # 用户选择退出
  fi

  if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
    echo "无效的输入，请输入数字编号。"
    return 1
  fi

  if [[ "$choice" -lt 1 || "$choice" -gt $((count - 1)) ]]; then
    echo "无效的容器编号。"
    return 1
  fi

  selected_index=$((choice - 1))
  echo "你选择了容器: ${container_names[$selected_index]} (ID: ${container_ids[$selected_index]})"
  echo "---------------------------------------------------------"
  echo "请选择操作:"
  echo "1. 停止容器"
  echo "2. 删除容器"
  echo "3. 更新容器 (重新创建)"
  echo "---------------------------------------------------------"
  read -p "请选择操作编号 (1/2/3 或按 'q' 退出): " action_choice

  if [[ "$action_choice" == "q" ]]; then
    return 1 # 用户选择退出
  fi

  case "$action_choice" in
    1)
      docker stop "${container_ids[$selected_index]}"
      if [[ $? -eq 0 ]]; then
        echo "容器 '${container_names[$selected_index]}' 已成功停止。"
      else
        echo "停止容器 '${container_names[$selected_index]}' 失败。"
      fi
      ;;
    2)
      docker rm "${container_ids[$selected_index]}"
      if [[ $? -eq 0 ]]; then
        echo "容器 '${container_names[$selected_index]}' 已成功删除。"
      else
        echo "删除容器 '${container_names[$selected_index]}' 失败。"
      fi
      ;;
    3)
      # 更新容器 (这里我们假设更新是指重新创建容器)
      container_name="${container_names[$selected_index]}"
      container_id="${container_ids[$selected_index]}"

      echo "你选择了更新容器 '${container_name}'。"
      echo "请注意，'更新' 操作通常意味着重新创建容器。"
      echo "这通常涉及停止并删除旧容器，然后使用最新的镜像重新运行。"

      read -p "是否继续更新容器 '${container_name}'？ (y/n): " confirm_update
      if [[ "$confirm_update" == "y" ]]; then
        # 获取容器的配置信息 (这里只获取镜像名，更复杂的配置需要更详细的检查)
        image_name=$(docker inspect --format='{{.Config.Image}}' "$container_id")

        docker stop "$container_id"
        docker rm "$container_id"

        echo "正在使用镜像 '$image_name' 重新创建容器 '${container_name}'..."
        docker run --name "$container_name" "$image_name" # 简化的重新运行，可能需要根据实际情况添加更多参数

        if [[ $? -eq 0 ]]; then
          echo "容器 '${container_name}' 已成功更新 (重新创建)。"
        else
          echo "更新容器 '${container_name}' 失败。"
        fi
      else
        echo "取消更新操作。"
      fi
      ;;
    *)
      echo "无效的操作编号。"
      ;;
  esac
}

# 主程序
select_container

echo "脚本执行完毕。"

exit 0
