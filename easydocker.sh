#!/bin/bash
set -x

# 检查是否安装了 docker
if ! command -v docker &> /dev/null
then
    echo "错误: Docker 未安装。请先安装 Docker。"
    exit 1
fi

# 检查 docker-compose 是否可用 (同时兼容 docker-compose 和 docker compose)
if command -v docker-compose &> /dev/null; then
  COMPOSE_COMMAND="docker-compose"
elif command -v docker compose &> /dev/null; then
  COMPOSE_COMMAND="docker compose"
else
  echo "错误: Docker Compose 未安装。请先安装 Docker Compose。"
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


# 函数: 列出 Docker Compose 项目并返回选择的项目名称
function select_compose_project() {
  local projects
  projects=$("$COMPOSE_COMMAND" ls --format "{{.Name}}\t{{.Status}}")

  if [[ -z "$projects" ]]; then
    echo "没有找到任何 Docker Compose 项目。"
    return 1
  fi

  echo "已找到 Docker Compose 项目:"
  echo "-----------------------------------------"
  echo "编号\t项目名称\t\t状态"
  echo "-----------------------------------------"

  IFS=$'\n' read -r -d '' -a project_lines <<< "$projects"
  local project_names=()
  local count=1

  for line in "${project_lines[@]}"; do
    IFS=$'\t' read -r -a parts <<< "$line"
    project_name="${parts[0]}"
    project_status="${parts[1]}" # 状态可能不太准确，docker compose ls 的状态比较简单
    echo "$count\t${project_name}\t\t${project_status}"
    project_names+=("$project_name")
    ((count++))
  done

  echo "-----------------------------------------"
  read -p "请选择要操作的 Docker Compose 项目编号 (或按 'q' 退出): " choice

  if [[ "$choice" == "q" ]]; then
    return 1 # 用户选择退出
  fi

  if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
    echo "无效的输入，请输入数字编号。"
    return 1
  fi

  if [[ "$choice" -lt 1 || "$choice" -gt $((count - 1)) ]]; then
    echo "无效的项目编号。"
    return 1
  fi

  selected_index=$((choice - 1))
  selected_project_name="${project_names[$selected_index]}"
  echo "你选择了 Docker Compose 项目: ${selected_project_name}"
  echo "-----------------------------------------"
  echo "请选择操作:"
  echo "1. 启动项目 (up -d)"
  echo "2. 停止项目 (down)"
  echo "3. 重启项目 (restart)"
  echo "4. 删除项目 (down --rmi all --volumes --remove-orphans -v)" # 更彻底的删除
  echo "-----------------------------------------"
  read -p "请选择操作编号 (1/2/3/4 或按 'q' 退出): " action_choice

  if [[ "$action_choice" == "q" ]]; then
    return 1 # 用户选择退出
  fi

  case "$action_choice" in
    1)
      echo "正在启动 Docker Compose 项目 '${selected_project_name}'..."
      pushd "$selected_project_name" > /dev/null 2>&1  # 假设项目目录名和项目名相同，并切换到项目目录
      "$COMPOSE_COMMAND" up -d
      popd > /dev/null 2>&1 # 返回原来的目录
      if [[ $? -eq 0 ]]; then
        echo "Docker Compose 项目 '${selected_project_name}' 已成功启动。"
      else
        echo "启动 Docker Compose 项目 '${selected_project_name}' 失败。"
      fi
      ;;
    2)
      echo "正在停止 Docker Compose 项目 '${selected_project_name}'..."
      pushd "$selected_project_name" > /dev/null 2>&1 # 假设项目目录名和项目名相同，并切换到项目目录
      "$COMPOSE_COMMAND" down
      popd > /dev/null 2>&1 # 返回原来的目录
      if [[ $? -eq 0 ]]; then
        echo "Docker Compose 项目 '${selected_project_name}' 已成功停止。"
      else
        echo "停止 Docker Compose 项目 '${selected_project_name}' 失败。"
      fi
      ;;
    3)
      echo "正在重启 Docker Compose 项目 '${selected_project_name}'..."
      pushd "$selected_project_name" > /dev/null 2>&1 # 假设项目目录名和项目名相同，并切换到项目目录
      "$COMPOSE_COMMAND" restart
      popd > /dev/null 2>&1 # 返回原来的目录
      if [[ $? -eq 0 ]]; then
        echo "Docker Compose 项目 '${selected_project_name}' 已成功重启。"
      else
        echo "重启 Docker Compose 项目 '${selected_project_name}' 失败。"
      fi
      ;;
    4)
      echo "正在删除 Docker Compose 项目 '${selected_project_name}' (包括镜像和卷)..."
      pushd "$selected_project_name" > /dev/null 2>&1 # 假设项目目录名和项目名相同，并切换到项目目录
      "$COMPOSE_COMMAND" down --rmi all --volumes --remove-orphans -v
      popd > /dev/null 2>&1 # 返回原来的目录
      if [[ $? -eq 0 ]]; then
        echo "Docker Compose 项目 '${selected_project_name}' 已成功删除。"
      else
        echo "删除 Docker Compose 项目 '${selected_project_name}' 失败。"
      fi
      ;;
    *)
      echo "无效的操作编号。"
      ;;
  esac
}


# 主程序
echo "请选择要管理的对象:"
echo "1. Docker 容器"
echo "2. Docker Compose 项目"
echo "-----------------------------------------"
read -p "请选择 (1/2 或按 'q' 退出): " management_choice

if [[ "$management_choice" == "q" ]]; then
  echo "退出脚本。"
  exit 0
fi

case "$management_choice" in
  1)
    select_container
    ;;
  2)
    select_compose_project
    ;;
  *)
    echo "无效的选择。"
    exit 1
    ;;
esac


echo "脚本执行完毕。"
exit 0
