#!/bin/bash

set -e  # 遇到错误立即退出

# 定义颜色
BLUE='\e[36m'  # 海蓝色
GREEN='\e[32m'
YELLOW='\e[33m'
RED='\e[31m'
RESET='\e[0m'

# NapthaAI 目录
INSTALL_DIR="/root/Naptha-Node"

# 版本信息
VERSION="1.0.0"

# 炫酷的 @fishzone24 字符标识
echo -e "${BLUE}"
cat << "EOF"

  @@@@@@@@  @@@  @@@@@@@  @@@  @@@  @@@@@@@@   @@@@@@   @@@  @@@  @@@@@@@@  @@@@@@   @@@  @@@
  @@@@@@@@  @@@  @@@@@@@  @@@  @@@  @@@@@@@@  @@@@@@@@  @@@@ @@@  @@@@@@@@  @@@@@@@@  @@@  @@@
  @@!       @@!    @@!    @@!  @@@       @@!  @@!  @@@  @@!@!@@@  @@!       @@!  @@@  @@!  !@@
  !@!       !@!    !@!    !@!  @!@      !@!   !@!  @!@  !@!!@!@!  !@!       !@!  @!@  !@!  @!!
  @!!!:!    !!@    @!!    @!@!@!@!     @!!    @!@  !@!  @!@ !!@!  @!!!:!    @!@!@!@!  @!@@!@! 
  !!!!!:    !!!    !!!    !!!@!!!!    !!!     !@!  !!!  !@!  !!!  !!!!!:    !!!@!!!!  !!@!!!  
  !!:       !!:    !!:    !!:  !!!   !!:      !!:  !!!  !!:  !!!  !!:       !!:  !!!  !!: :!! 
  :!:       :!:    :!:    :!:  !:!  :!:       :!:  !:!  :!:  !:!  :!:       :!:  !:!  :!:  !:! 
   ::        ::     ::    ::   :::   :: ::::  ::::: ::   ::   ::   :: ::::  ::   :::   ::  ::: 
   :        :       :      :   : :  : :: : :   : :  :   ::    :   : :: ::    :   : :   :   :: 
EOF
echo -e "${RESET}"

echo -e "${BLUE}x.com/fishzone24${RESET}"
echo -e "${BLUE}NapthaAI 一键管理脚本 v${VERSION}${RESET}"

# 署名
AUTHOR="Fishzone24 节点教程分享 推特 https://x.com/fishzone24"

# 函数列表
# 1. 基础函数
# check_python_venv - 检查并安装 python3-venv
# get_architecture - 检测当前系统架构
# install_docker - 安装 Docker 和 Docker Compose
# create_virtualenv - 创建虚拟环境并安装依赖
# check_prerequisites - 检查系统先决条件

# 2. 节点管理
# install_node - 安装 NapthaAI 节点
# update_node - 更新 NapthaAI 节点
# uninstall_node - 卸载 NapthaAI 节点
# replace_private_key_in_pem - 更换 PEM 文件中的私钥
# export_private_key - 导出 PRIVATE_KEY
# configure_env - 配置环境变量
# switch_launch_mode - 切换启动模式（Docker 或 systemd）

# 3. 服务与容器管理
# stop_and_remove_containers - 停止并删除节点容器
# view_logs - 查看所有容器日志
# view_service_logs - 查看特定服务的日志
# reset_database - 重置数据库
# show_node_status - 显示节点状态
# manage_ollama_models - 管理 Ollama 模型
# manage_vllm_models - 管理 vLLM 模型
# manage_litellm - 管理 LiteLLM 服务
# test_model_capabilities - 测试模型能力
# show_recommended_models - 显示推荐模型信息

# 4. 辅助功能
# run_sdk_example - 运行 SDK 示例
# backup_restore - 备份和恢复配置

# 检查并安装 python3-venv 包
check_python_venv() {
    if ! dpkg -l | grep -q "python3-venv"; then
        echo -e "${YELLOW}检测到 python3-venv 未安装，正在安装...${RESET}"
        sudo apt update
        sudo apt install python3.10-venv
    fi
}

# 检测当前系统架构
get_architecture() {
    arch=$(uname -m)
    case $arch in
        x86_64|amd64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            echo "${RED}不支持的架构: $arch${RESET}" >&2
            exit 1
            ;;
    esac
}

# 安装 Docker 和 Docker Compose
install_docker() {
    echo -e "${BLUE}检查并安装 Docker 和 Docker Compose...${RESET}"
    if ! command -v docker &> /dev/null; then
        echo -e "${BLUE}安装 Docker...${RESET}"
        curl -fsSL https://get.docker.com | sudo bash
        sudo systemctl enable --now docker
    fi

    if ! command -v docker-compose &> /dev/null; then
        echo -e "${BLUE}安装 Docker Compose...${RESET}"
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
}

# 创建虚拟环境并安装依赖
create_virtualenv() {
    check_python_venv
    echo -e "${BLUE}创建虚拟环境并安装依赖...${RESET}"
    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip
    pip install docker requests # 直接安装必要的依赖
}

# 检查系统先决条件
check_prerequisites() {
    echo -e "${BLUE}检查系统先决条件...${RESET}"
    
    # 检查操作系统类型
    os=$(uname)
    if [[ "$os" != "Linux" ]]; then
        echo -e "${RED}警告: 当前脚本主要为 Linux 系统设计，在 $os 上可能有兼容性问题${RESET}"
        read -p "是否继续? (y/n): " continue_anyway
        if [[ "$continue_anyway" != "y" ]]; then
            echo -e "${YELLOW}退出安装${RESET}"
            exit 1
        fi
    fi
    
    # 检查必要的命令
    for cmd in curl git sudo; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${YELLOW}未找到命令: $cmd, 正在安装...${RESET}"
            apt update && apt install -y $cmd
        fi
    done
    
    # 检查内存
    total_mem=$(free -m | awk '/^Mem:/{print $2}')
    if (( total_mem < 4000 )); then
        echo -e "${RED}警告: 系统内存小于推荐的 4GB (当前: ${total_mem}MB)${RESET}"
        read -p "是否继续? (y/n): " continue_mem
        if [[ "$continue_mem" != "y" ]]; then
            echo -e "${YELLOW}退出安装${RESET}"
            exit 1
        fi
    else
        echo -e "${GREEN}内存检查通过: ${total_mem}MB${RESET}"
    fi
    
    # 检查硬盘空间
    free_space=$(df -h / | awk 'NR==2 {print $4}')
    echo -e "${BLUE}可用磁盘空间: $free_space${RESET}"
    
    # 检查是否有GPU
    if command -v nvidia-smi &> /dev/null; then
        gpu_info=$(nvidia-smi --query-gpu=name --format=csv,noheader)
        echo -e "${GREEN}检测到 GPU: $gpu_info${RESET}"
    else
        echo -e "${YELLOW}未检测到 NVIDIA GPU, 将使用 CPU 模式${RESET}"
    fi
    
    echo -e "${GREEN}系统先决条件检查完成${RESET}"
}

# 安装 NapthaAI 节点
install_node() {
    install_docker
    echo -e "${BLUE}安装 NapthaAI 节点...${RESET}"
    if [ ! -d "$INSTALL_DIR" ]; then
        git clone https://github.com/NapthaAI/naptha-node.git "$INSTALL_DIR"
    fi
    cd "$INSTALL_DIR"

    # 创建虚拟环境并安装依赖
    create_virtualenv

    # 配置环境变量
    configure_env

    # 启动 NapthaAI 节点
    echo -e "${BLUE}启动 NapthaAI 节点...${RESET}"
    bash launch.sh

    # 检查节点是否启动成功
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}NapthaAI 节点已成功启动！${RESET}"
        echo -e "访问地址: ${YELLOW}http://$(hostname -I | awk '{print $1}'):7001${RESET}"
    else
        echo -e "${RED}NapthaAI 节点启动失败，请检查日志！${RESET}"
    fi
}

# 更换 PEM 文件中的私钥
replace_private_key_in_pem() {
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
        return 1
    fi
    
    # 提示用户输入 Hub-Username
    read -p "请输入您的 Hub-Username: " hub_username
    
    # 检查 PEM 文件是否存在
    PEM_FILE="$INSTALL_DIR/${hub_username}.pem"
    if [ ! -f "$PEM_FILE" ]; then
        echo -e "${RED}未找到 ${hub_username}.pem 文件！${RESET}"
        return 1
    fi
    
    # 提示用户输入新的私钥
    echo -e "${BLUE}请粘贴新的私钥并按回车:${RESET}"
    read -r new_private_key
    
    # 将新的私钥写入 PEM 文件
    echo "$new_private_key" > "$PEM_FILE"
    echo -e "${GREEN}私钥已更新！${RESET}"
    return 0
}

# 配置环境变量
configure_env() {
    if [ ! -f "$INSTALL_DIR/.env" ]; then
        echo -e "${BLUE}创建 .env 配置文件...${RESET}"
        cp "$INSTALL_DIR/.env.example" "$INSTALL_DIR/.env"
        
        # 设置基本配置
        sed -i 's/^LAUNCH_DOCKER=.*/LAUNCH_DOCKER=true/' "$INSTALL_DIR/.env"
        
        # 检测是否有GPU并配置
        if command -v nvidia-smi &> /dev/null; then
            echo -e "${GREEN}检测到 NVIDIA GPU，配置为使用 vLLM 后端...${RESET}"
            sed -i 's/^LLM_BACKEND=.*/LLM_BACKEND=vllm/' "$INSTALL_DIR/.env"
            sed -i 's/^NUM_GPUS=.*/NUM_GPUS=1/' "$INSTALL_DIR/.env"
            
            read -p "请输入要使用的 vLLM 模型 (默认为 NousResearch/Hermes-3-Llama-3.1-8B): " vllm_models
            if [[ -z "$vllm_models" ]]; then
                vllm_models="NousResearch/Hermes-3-Llama-3.1-8B"
            fi
            sed -i "s|^VLLM_MODELS=.*|VLLM_MODELS=$vllm_models|" "$INSTALL_DIR/.env"
            
            # 询问是否配置 HuggingFace Token
            read -p "是否配置 HUGGINGFACE_TOKEN？部分模型需要此权限 (y/n): " config_hf
            if [[ "$config_hf" == "y" ]]; then
                read -p "请输入您的 HUGGINGFACE_TOKEN: " hf_token
                sed -i "s|^HUGGINGFACE_TOKEN=.*|HUGGINGFACE_TOKEN=$hf_token|" "$INSTALL_DIR/.env"
            fi
            
            # 设置HF_HOME
            username=$(whoami)
            sed -i "s|^HF_HOME=.*|HF_HOME=/home/$username/.cache/huggingface|" "$INSTALL_DIR/.env"
        else
            echo -e "${YELLOW}未检测到 GPU，配置为使用 Ollama 后端...${RESET}"
            sed -i 's/^LLM_BACKEND=.*/LLM_BACKEND=ollama/' "$INSTALL_DIR/.env"
            
            read -p "请选择要使用的 Ollama 模型 (默认为 hermes3:8b): " ollama_models
            if [[ -z "$ollama_models" ]]; then
                ollama_models="hermes3:8b"
            fi
            sed -i "s/^OLLAMA_MODELS=.*/OLLAMA_MODELS=$ollama_models/" "$INSTALL_DIR/.env"
        fi
        
        # 询问是否需要配置 PRIVATE_KEY
        read -p "是否已有 PRIVATE_KEY？(y/n): " has_private_key
        if [[ "$has_private_key" == "y" ]]; then
            read -p "请输入您的 PRIVATE_KEY: " private_key
            sed -i "s/^PRIVATE_KEY=.*/PRIVATE_KEY=$private_key/" "$INSTALL_DIR/.env"
        fi
        
        # 询问是否需要配置 HUB_USERNAME 和 HUB_PASSWORD
        read -p "请输入您的 HUB_USERNAME: " hub_username
        sed -i "s/^HUB_USERNAME=.*/HUB_USERNAME=$hub_username/" "$INSTALL_DIR/.env"
        
        read -p "请输入您的 HUB_PASSWORD: " hub_password
        sed -i "s/^HUB_PASSWORD=.*/HUB_PASSWORD=$hub_password/" "$INSTALL_DIR/.env"
        
        # 询问是否配置 OPENAI_API_KEY
        read -p "是否配置 OPENAI_API_KEY？(y/n): " config_openai
        if [[ "$config_openai" == "y" ]]; then
            read -p "请输入您的 OPENAI_API_KEY: " openai_key
            sed -i "s/^OPENAI_API_KEY=.*/OPENAI_API_KEY=$openai_key/" "$INSTALL_DIR/.env"
        fi
        
        # 询问是否配置 STABILITY_API_KEY
        read -p "是否配置 STABILITY_API_KEY？(y/n): " config_stability
        if [[ "$config_stability" == "y" ]]; then
            read -p "请输入您的 STABILITY_API_KEY: " stability_key
            sed -i "s/^STABILITY_API_KEY=.*/STABILITY_API_KEY=$stability_key/" "$INSTALL_DIR/.env"
        fi
        
        # 配置LiteLLM
        echo -e "${BLUE}配置 LiteLLM 服务...${RESET}"
        read -p "请设置 LITELLM_MASTER_KEY (默认为随机生成): " litellm_master_key
        if [[ -z "$litellm_master_key" ]]; then
            litellm_master_key="sk-$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 16)"
        fi
        sed -i "s/^LITELLM_MASTER_KEY=.*/LITELLM_MASTER_KEY=$litellm_master_key/" "$INSTALL_DIR/.env"
        
        read -p "请设置 LITELLM_SALT_KEY (默认为随机生成): " litellm_salt_key
        if [[ -z "$litellm_salt_key" ]]; then
            litellm_salt_key="sk-$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 16)"
        fi
        sed -i "s/^LITELLM_SALT_KEY=.*/LITELLM_SALT_KEY=$litellm_salt_key/" "$INSTALL_DIR/.env"
        
        # 询问是否设置本地 Hub
        read -p "是否运行本地 Hub？(y/n): " run_local_hub
        if [[ "$run_local_hub" == "y" ]]; then
            sed -i 's/^LOCAL_HUB=.*/LOCAL_HUB=true/' "$INSTALL_DIR/.env"
            
            # 配置SurrealDB
            echo -e "${BLUE}配置 SurrealDB 服务...${RESET}"
            read -p "请设置 HUB_DB_SURREAL_ROOT_USER (默认为root): " surreal_user
            if [[ -z "$surreal_user" ]]; then
                surreal_user="root"
            fi
            sed -i "s/^HUB_DB_SURREAL_ROOT_USER=.*/HUB_DB_SURREAL_ROOT_USER=$surreal_user/" "$INSTALL_DIR/.env"
            
            read -p "请设置 HUB_DB_SURREAL_ROOT_PASS (默认为root): " surreal_pass
            if [[ -z "$surreal_pass" ]]; then
                surreal_pass="root"
            fi
            sed -i "s/^HUB_DB_SURREAL_ROOT_PASS=.*/HUB_DB_SURREAL_ROOT_PASS=$surreal_pass/" "$INSTALL_DIR/.env"
        else
            sed -i 's/^LOCAL_HUB=.*/LOCAL_HUB=false/' "$INSTALL_DIR/.env"
        fi
        
        # 询问是否注册节点到 Hub
        read -p "是否将节点注册到 Hub？(y/n): " register_to_hub
        if [[ "$register_to_hub" == "y" ]]; then
            sed -i 's/^REGISTER_NODE_WITH_HUB=.*/REGISTER_NODE_WITH_HUB=true/' "$INSTALL_DIR/.env"
            
            # 获取当前服务器 IP
            SERVER_IP=$(hostname -I | awk '{print $1}')
            sed -i "s/^NODE_IP=.*/NODE_IP=$SERVER_IP/" "$INSTALL_DIR/.env"
        else
            sed -i 's/^REGISTER_NODE_WITH_HUB=.*/REGISTER_NODE_WITH_HUB=false/' "$INSTALL_DIR/.env"
        fi
        
        # 配置数据库
        echo -e "${BLUE}配置 PostgreSQL 数据库...${RESET}"
        read -p "请设置 LOCAL_DB_POSTGRES_USERNAME (默认为naptha): " pg_user
        if [[ -z "$pg_user" ]]; then
            pg_user="naptha"
        fi
        sed -i "s/^LOCAL_DB_POSTGRES_USERNAME=.*/LOCAL_DB_POSTGRES_USERNAME=$pg_user/" "$INSTALL_DIR/.env"
        
        read -p "请设置 LOCAL_DB_POSTGRES_PASSWORD (默认为随机生成): " pg_pass
        if [[ -z "$pg_pass" ]]; then
            pg_pass="$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 16)"
        fi
        sed -i "s/^LOCAL_DB_POSTGRES_PASSWORD=.*/LOCAL_DB_POSTGRES_PASSWORD=$pg_pass/" "$INSTALL_DIR/.env"
    else
        echo -e "${GREEN}.env 文件已存在，跳过配置...${RESET}"
    fi
}

# 导出 PRIVATE_KEY
export_private_key() {
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
        return 1
    fi
    
    # 提示用户输入 Hub-Username
    read -p "请输入您的 Hub-Username: " hub_username
    
    # 检查 PEM 文件是否存在
    PEM_FILE="$INSTALL_DIR/${hub_username}.pem"
    if [ -f "$PEM_FILE" ]; then
        PRIVATE_KEY=$(cat "$PEM_FILE")
        if [ -n "$PRIVATE_KEY" ]; then
            echo -e "${BLUE}您的 PRIVATE_KEY:${RESET} ${YELLOW}$PRIVATE_KEY${RESET}"
        else
            echo -e "${RED}未找到 PRIVATE_KEY，请确认节点已安装并正确配置。${RESET}"
        fi
    else
        echo -e "${RED}未找到 ${hub_username}.pem 文件，节点可能未安装！${RESET}"
    fi
}

# 查看日志
view_logs() {
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${BLUE}显示 NapthaAI 日志...${RESET}"
        cd "$INSTALL_DIR"
        docker-compose logs -f --tail=200
    else
        echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
    fi
}

# 查看特定服务的日志
view_service_logs() {
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
        return 1
    fi
    
    cd "$INSTALL_DIR"
    
    # 获取当前运行的容器列表
    echo -e "${BLUE}当前运行的服务:${RESET}"
    docker-compose ps --services
    
    # 让用户选择要查看的服务
    read -p "请输入要查看日志的服务名称: " service_name
    
    # 检查服务是否存在
    if docker-compose ps | grep -q "$service_name"; then
        echo -e "${BLUE}显示 $service_name 的日志...${RESET}"
        docker-compose logs -f --tail=200 "$service_name"
    else
        echo -e "${RED}服务 $service_name 不存在或未运行！${RESET}"
    fi
}

# 停止并删除节点容器
stop_and_remove_containers() {
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}正在停止并删除节点容器...${RESET}"
        cd "$INSTALL_DIR"
        docker-compose down
    else
        echo -e "${RED}未找到 NapthaAI 节点，无法停止容器！${RESET}"
    fi
}

# 卸载 NapthaAI
uninstall_node() {
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}正在停止并删除 NapthaAI 节点的容器和所有文件...${RESET}"
        stop_and_remove_containers
        cd ~
        rm -rf "$INSTALL_DIR"
        echo -e "${GREEN}NapthaAI 节点已成功卸载，所有容器已删除！${RESET}"
    else
        echo -e "${RED}未找到 NapthaAI 节点，无需卸载。${RESET}"
    fi
}

# 更新 NapthaAI 节点
update_node() {
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
        return 1
    fi
    
    echo -e "${BLUE}正在更新 NapthaAI 节点...${RESET}"
    cd "$INSTALL_DIR"
    
    # 备份当前的 .env 文件
    cp .env .env.backup
    
    # 停止当前容器
    docker-compose down
    
    # 拉取最新代码
    git pull
    
    # 恢复 .env 文件
    cp .env.backup .env
    
    # 重启节点
    bash launch.sh
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}NapthaAI 节点已成功更新！${RESET}"
    else
        echo -e "${RED}NapthaAI 节点更新失败，请检查日志！${RESET}"
    fi
}

# 重置数据库
reset_database() {
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
        return 1
    fi
    
    echo -e "${YELLOW}警告: 此操作将删除所有数据库数据！${RESET}"
    read -p "是否继续？(y/n): " confirm
    
    if [[ "$confirm" != "y" ]]; then
        echo -e "${BLUE}操作已取消。${RESET}"
        return 0
    fi
    
    cd "$INSTALL_DIR"
    
    # 停止容器
    docker-compose down
    
    # 列出所有卷
    echo -e "${BLUE}当前的 Docker 卷:${RESET}"
    docker volume ls | grep naptha
    
    # 删除相关卷
    read -p "是否删除所有 naptha 相关的卷？(y/n): " delete_volumes
    
    if [[ "$delete_volumes" == "y" ]]; then
        docker volume ls | grep naptha | awk '{print $2}' | xargs docker volume rm
        echo -e "${GREEN}已删除所有 naptha 相关的卷。${RESET}"
    fi
    
    # 重启节点
    bash launch.sh
}

# 显示节点状态
show_node_status() {
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
        return 1
    fi
    
    cd "$INSTALL_DIR"
    
    echo -e "${BLUE}节点状态:${RESET}"
    docker-compose ps
    
    # 显示节点 API 地址
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo -e "\n${BLUE}节点 API 地址:${RESET} ${GREEN}http://$SERVER_IP:7001${RESET}"
    
    # 显示 LiteLLM 状态
    if curl -s "http://localhost:7001/v1/models" > /dev/null; then
        echo -e "${BLUE}LiteLLM 状态:${RESET} ${GREEN}运行中${RESET}"
    else
        echo -e "${BLUE}LiteLLM 状态:${RESET} ${RED}未运行${RESET}"
    fi
}

# 使用 naptha-sdk 示例
run_sdk_example() {
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
        return 1
    fi
    
    # 检查是否已安装 naptha-sdk
    if ! pip show naptha > /dev/null 2>&1; then
        echo -e "${YELLOW}未检测到 naptha-sdk，正在安装...${RESET}"
        pip install naptha
    fi
    
    # 创建临时目录
    SDK_DIR="/tmp/naptha-sdk-examples"
    mkdir -p "$SDK_DIR"
    cd "$SDK_DIR"
    
    # 下载示例
    echo -e "${BLUE}下载 SDK 示例...${RESET}"
    git clone https://github.com/NapthaAI/naptha-sdk.git .
    
    # 配置环境变量
    SERVER_IP=$(hostname -I | awk '{print $1}')
    export NODE_URL="http://$SERVER_IP:7001"
    
    # 显示可用示例
    echo -e "${BLUE}可用示例:${RESET}"
    ls -la examples
    
    # 让用户选择要运行的示例
    read -p "请输入要运行的示例文件名 (例如: simple_agent.py): " example_file
    
    if [ -f "examples/$example_file" ]; then
        echo -e "${BLUE}运行示例: $example_file${RESET}"
        python "examples/$example_file"
    else
        echo -e "${RED}示例文件不存在: $example_file${RESET}"
    fi
}

# 切换启动模式（Docker 或 systemd）
switch_launch_mode() {
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
        return 1
    fi
    
    cd "$INSTALL_DIR"
    
    # 读取当前模式
    current_mode=$(grep "^LAUNCH_DOCKER=" .env | cut -d= -f2)
    
    if [[ "$current_mode" == "true" ]]; then
        echo -e "${BLUE}当前模式为 Docker. 是否切换到 systemd/launchd 模式? (y/n)${RESET}"
        read -p "> " switch_to_systemd
        if [[ "$switch_to_systemd" == "y" ]]; then
            echo -e "${YELLOW}正在切换到 systemd/launchd 模式...${RESET}"
            
            # 停止当前的 Docker 容器
            docker-compose down
            
            # 修改配置文件
            sed -i 's/^LAUNCH_DOCKER=.*/LAUNCH_DOCKER=false/' .env
            
            # 启动节点
            bash launch.sh
            
            echo -e "${GREEN}已成功切换到 systemd/launchd 模式${RESET}"
        else
            echo -e "${BLUE}保持 Docker 模式${RESET}"
        fi
    else
        echo -e "${BLUE}当前模式为 systemd/launchd. 是否切换到 Docker 模式? (y/n)${RESET}"
        read -p "> " switch_to_docker
        if [[ "$switch_to_docker" == "y" ]]; then
            echo -e "${YELLOW}正在切换到 Docker 模式...${RESET}"
            
            # 停止当前的服务
            bash stop_service.sh
            
            # 修改配置文件
            sed -i 's/^LAUNCH_DOCKER=.*/LAUNCH_DOCKER=true/' .env
            
            # 启动节点
            bash launch.sh
            
            echo -e "${GREEN}已成功切换到 Docker 模式${RESET}"
        else
            echo -e "${BLUE}保持 systemd/launchd 模式${RESET}"
        fi
    fi
}

# 管理 Ollama 模型
manage_ollama_models() {
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
        return 1
    fi
    
    cd "$INSTALL_DIR"
    
    # 检查 Ollama 是否安装
    if ! command -v ollama &> /dev/null; then
        echo -e "${RED}Ollama 未安装，无法管理模型${RESET}"
        return 1
    fi
    
    while true; do
        echo -e "\n${BLUE}Ollama 模型管理${RESET}"
        echo -e "1. 列出当前已安装的模型"
        echo -e "2. 拉取新模型"
        echo -e "3. 删除现有模型"
        echo -e "4. 更新已安装的模型"
        echo -e "5. 返回主菜单"
        read -p "请选择操作: " ollama_choice
        
        case "$ollama_choice" in
            1)
                echo -e "${BLUE}已安装的 Ollama 模型:${RESET}"
                ollama list
                ;;
            2)
                read -p "请输入要拉取的模型名称 (例如: llama3:8b): " model_name
                echo -e "${BLUE}拉取模型 $model_name...${RESET}"
                ollama pull $model_name
                # 更新 .env 文件中的模型列表
                read -p "是否将此模型添加到 .env 中的 OLLAMA_MODELS? (y/n): " update_env
                if [[ "$update_env" == "y" ]]; then
                    current_models=$(grep "^OLLAMA_MODELS=" .env | cut -d= -f2)
                    sed -i "s/^OLLAMA_MODELS=.*/OLLAMA_MODELS=$current_models,$model_name/" .env
                    echo -e "${GREEN}已更新 .env 文件${RESET}"
                fi
                ;;
            3)
                echo -e "${BLUE}已安装的 Ollama 模型:${RESET}"
                ollama list
                read -p "请输入要删除的模型名称: " model_name
                echo -e "${YELLOW}删除模型 $model_name...${RESET}"
                ollama rm $model_name
                ;;
            4)
                echo -e "${BLUE}已安装的 Ollama 模型:${RESET}"
                ollama list
                read -p "请输入要更新的模型名称: " model_name
                echo -e "${BLUE}更新模型 $model_name...${RESET}"
                ollama pull $model_name
                ;;
            5)
                return 0
                ;;
            *)
                echo -e "${RED}无效选项，请重新输入！${RESET}"
                ;;
        esac
    done
}

# 管理 LiteLLM 服务
manage_litellm() {
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
        return 1
    fi
    
    cd "$INSTALL_DIR"
    
    # 检查 Docker 是否在运行
    if ! docker ps &> /dev/null; then
        echo -e "${RED}Docker 未运行，无法管理 LiteLLM${RESET}"
        return 1
    fi
    
    # 检查 LiteLLM 容器是否存在
    if ! docker ps | grep -q "litellm"; then
        echo -e "${RED}LiteLLM 容器未运行${RESET}"
        read -p "是否启动 LiteLLM 容器? (y/n): " start_litellm
        if [[ "$start_litellm" == "y" ]]; then
            docker-compose up -d litellm
            echo -e "${GREEN}LiteLLM 容器已启动${RESET}"
        else
            return 1
        fi
    fi
    
    while true; do
        echo -e "\n${BLUE}LiteLLM 服务管理${RESET}"
        echo -e "1. 查看可用的模型"
        echo -e "2. 测试 LiteLLM 服务"
        echo -e "3. 查看 LiteLLM 日志"
        echo -e "4. 重启 LiteLLM 服务"
        echo -e "5. 返回主菜单"
        read -p "请选择操作: " litellm_choice
        
        case "$litellm_choice" in
            1)
                echo -e "${BLUE}查询可用的模型...${RESET}"
                curl -s http://localhost:4000/v1/models | jq 2>/dev/null || echo "请安装 jq 以获得更好的输出格式"
                ;;
            2)
                echo -e "${BLUE}测试 LiteLLM 服务...${RESET}"
                read -p "请输入提示词: " prompt
                server_ip=$(hostname -I | awk '{print $1}')
                echo -e "${YELLOW}向 http://$server_ip:4000/v1/chat/completions 发送测试请求...${RESET}"
                curl -s http://$server_ip:4000/v1/chat/completions \
                  -H "Content-Type: application/json" \
                  -H "Authorization: Bearer $(grep LITELLM_MASTER_KEY .env | cut -d= -f2)" \
                  -d "{\"model\": \"ollama/hermes3:8b\", \"messages\": [{\"role\": \"user\", \"content\": \"$prompt\"}]}" | jq 2>/dev/null || cat
                ;;
            3)
                echo -e "${BLUE}显示 LiteLLM 日志...${RESET}"
                docker logs -f litellm
                ;;
            4)
                echo -e "${YELLOW}重启 LiteLLM 服务...${RESET}"
                docker-compose restart litellm
                echo -e "${GREEN}LiteLLM 服务已重启${RESET}"
                ;;
            5)
                return 0
                ;;
            *)
                echo -e "${RED}无效选项，请重新输入！${RESET}"
                ;;
        esac
    done
}

# 备份和恢复配置
backup_restore() {
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
        return 1
    fi
    
    # 创建备份目录
    BACKUP_DIR="$HOME/naptha-backups"
    mkdir -p "$BACKUP_DIR"
    
    while true; do
        echo -e "\n${BLUE}备份和恢复${RESET}"
        echo -e "1. 创建配置备份"
        echo -e "2. 恢复配置备份"
        echo -e "3. 列出可用备份"
        echo -e "4. 删除备份"
        echo -e "5. 返回主菜单"
        read -p "请选择操作: " backup_choice
        
        case "$backup_choice" in
            1)
                timestamp=$(date +"%Y%m%d_%H%M%S")
                backup_file="$BACKUP_DIR/naptha_backup_$timestamp.tar.gz"
                echo -e "${BLUE}创建备份文件: $backup_file${RESET}"
                
                cd "$INSTALL_DIR"
                tar -czf "$backup_file" .env *.pem node/storage/fs node/storage/hub/modules 2>/dev/null
                
                if [ -f "$backup_file" ]; then
                    echo -e "${GREEN}备份已创建: $backup_file${RESET}"
                else
                    echo -e "${RED}备份创建失败${RESET}"
                fi
                ;;
            2)
                echo -e "${BLUE}可用备份:${RESET}"
                ls -lh "$BACKUP_DIR" | grep "naptha_backup"
                
                read -p "请输入要恢复的备份文件名: " backup_name
                backup_path="$BACKUP_DIR/$backup_name"
                
                if [ -f "$backup_path" ]; then
                    echo -e "${YELLOW}正在恢复备份: $backup_path${RESET}"
                    
                    # 停止服务
                    cd "$INSTALL_DIR"
                    source .env
                    if [[ "$LAUNCH_DOCKER" == "true" ]]; then
                        docker-compose down
                    else
                        bash stop_service.sh
                    fi
                    
                    # 创建备份恢复临时目录
                    RESTORE_TMP="$INSTALL_DIR/backup_restore_tmp"
                    mkdir -p "$RESTORE_TMP"
                    
                    # 解压到临时目录
                    tar -xzf "$backup_path" -C "$RESTORE_TMP"
                    
                    # 恢复文件
                    cp -f "$RESTORE_TMP/.env" "$INSTALL_DIR/" 2>/dev/null
                    cp -f "$RESTORE_TMP/"*.pem "$INSTALL_DIR/" 2>/dev/null
                    cp -rf "$RESTORE_TMP/node/storage/fs/"* "$INSTALL_DIR/node/storage/fs/" 2>/dev/null
                    cp -rf "$RESTORE_TMP/node/storage/hub/modules/"* "$INSTALL_DIR/node/storage/hub/modules/" 2>/dev/null
                    
                    # 清理
                    rm -rf "$RESTORE_TMP"
                    
                    echo -e "${GREEN}备份已恢复${RESET}"
                    read -p "是否重启服务? (y/n): " restart_service
                    if [[ "$restart_service" == "y" ]]; then
                        cd "$INSTALL_DIR"
                        bash launch.sh
                    fi
                else
                    echo -e "${RED}备份文件不存在: $backup_path${RESET}"
                fi
                ;;
            3)
                echo -e "${BLUE}可用备份:${RESET}"
                ls -lh "$BACKUP_DIR" | grep "naptha_backup"
                ;;
            4)
                echo -e "${BLUE}可用备份:${RESET}"
                ls -lh "$BACKUP_DIR" | grep "naptha_backup"
                
                read -p "请输入要删除的备份文件名 (或输入 'all' 删除所有备份): " delete_name
                
                if [[ "$delete_name" == "all" ]]; then
                    echo -e "${YELLOW}删除所有备份...${RESET}"
                    rm -f "$BACKUP_DIR/naptha_backup_"*
                    echo -e "${GREEN}所有备份已删除${RESET}"
                elif [ -f "$BACKUP_DIR/$delete_name" ]; then
                    echo -e "${YELLOW}删除备份: $delete_name${RESET}"
                    rm -f "$BACKUP_DIR/$delete_name"
                    echo -e "${GREEN}备份已删除${RESET}"
                else
                    echo -e "${RED}备份文件不存在: $delete_name${RESET}"
                fi
                ;;
            5)
                return 0
                ;;
            *)
                echo -e "${RED}无效选项，请重新输入！${RESET}"
                ;;
        esac
    done
}

# 显示当前支持的推荐模型
show_recommended_models() {
    echo -e "${BLUE}Naptha支持的推荐模型:${RESET}"
    
    echo -e "\n${GREEN}▶ Ollama 推荐模型:${RESET}"
    echo -e "- hermes3:8b    - 支持工具调用与多轮对话的主流模型"
    echo -e "- llama3:8b     - Meta的最新开源模型，通用性能良好"
    echo -e "- qwen2.5-7b    - 阿里巴巴的强大模型，工具调用可靠性高"
    echo -e "- mistral:7b    - 法国Mistral公司的基础模型，适合简单任务"
    echo -e "- wizard:7b     - 指令跟随能力优秀的模型"
    
    echo -e "\n${GREEN}▶ vLLM 推荐模型(需要GPU):${RESET}"
    echo -e "- NousResearch/Hermes-3-Llama-3.1-8B   - 工具调用性能出色，适合Naptha Agent"
    echo -e "- Qwen/Qwen2.5-7B-Instruct            - 阿里巴巴出品，多轮对话和工具调用均表现出色"
    echo -e "- meta-llama/Llama-3.1-8B-Instruct    - Meta官方微调版本，需要HuggingFace授权"
    echo -e "- Team-ACE/ToolACE-8B                 - 专注于工具调用的模型"
    echo -e "- meetkai/functionary-small-v3.1      - 轻量级功能调用模型"
    
    echo -e "\n${YELLOW}注意:${RESET}"
    echo -e "1. 大多数小模型在温度为0时工具调用效果最佳"
    echo -e "2. 多任务工具调用建议使用Hermes-3或Qwen2.5系列模型"
    echo -e "3. 访问部分模型(如Llama系列)需要HuggingFace授权令牌"
    echo -e "4. vLLM模型需要GPU支持，且不同模型有不同的显存需求"
}

# 管理 vLLM 模型
manage_vllm_models() {
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
        return 1
    fi
    
    cd "$INSTALL_DIR"
    
    # 检查 NVIDIA 驱动和 GPU
    if ! command -v nvidia-smi &> /dev/null; then
        echo -e "${RED}未检测到 NVIDIA GPU，无法管理 vLLM 模型${RESET}"
        return 1
    fi
    
    # 获取当前配置的模型
    current_models=$(grep "^VLLM_MODELS=" .env | cut -d= -f2 | tr -d '"')
    gpu_count=$(nvidia-smi --query-gpu=count --format=csv,noheader,nounits)
    
    while true; do
        echo -e "\n${BLUE}vLLM 模型管理${RESET}"
        echo -e "检测到 ${GREEN}$gpu_count${RESET} 个 GPU"
        echo -e "当前配置的模型: ${GREEN}$current_models${RESET}"
        echo -e "1. 查看推荐的 vLLM 模型"
        echo -e "2. 添加 vLLM 模型"
        echo -e "3. 移除 vLLM 模型"
        echo -e "4. 查看模型信息与显存需求"
        echo -e "5. 设置 HuggingFace Token"
        echo -e "6. 返回主菜单"
        read -p "请选择操作: " vllm_choice
        
        case "$vllm_choice" in
            1)
                echo -e "${BLUE}推荐的 vLLM 模型:${RESET}"
                echo -e "- NousResearch/Hermes-3-Llama-3.1-8B (需要约8GB显存)"
                echo -e "- Qwen/Qwen2.5-7B-Instruct (需要约8GB显存)"
                echo -e "- meta-llama/Llama-3.1-8B-Instruct (需要约8GB显存，需要HF Token)"
                echo -e "- Team-ACE/ToolACE-8B (需要约8GB显存)"
                echo -e "- meetkai/functionary-small-v3.1 (需要约8GB显存)"
                echo -e "- deepseek-ai/DeepSeek-R1-Distill-Qwen-32B (需要约24GB显存)"
                echo -e "- mistralai/Mistral-Small-24B-Instruct-2501 (需要约24GB显存)"
                echo -e "- Qwen/QwQ-32B-Preview (需要约24GB显存)"
                ;;
            2)
                read -p "请输入要添加的模型名称 (例如: NousResearch/Hermes-3-Llama-3.1-8B): " model_name
                if [ -z "$model_name" ]; then
                    echo -e "${RED}模型名称不能为空${RESET}"
                    continue
                fi
                # 更新 .env 文件中的模型列表
                if [ -z "$current_models" ]; then
                    sed -i "s/^VLLM_MODELS=.*/VLLM_MODELS=\"$model_name\"/" .env
                else
                    sed -i "s/^VLLM_MODELS=.*/VLLM_MODELS=\"$current_models,$model_name\"/" .env
                fi
                current_models=$(grep "^VLLM_MODELS=" .env | cut -d= -f2 | tr -d '"')
                echo -e "${GREEN}已添加模型 $model_name${RESET}"
                ;;
            3)
                echo -e "${BLUE}当前模型:${RESET}"
                IFS=',' read -ra MODELS <<< "$current_models"
                for i in "${!MODELS[@]}"; do
                    echo -e "$((i+1)). ${MODELS[$i]}"
                done
                read -p "请输入要删除的模型编号: " model_num
                if [ -z "$model_num" ] || ! [[ "$model_num" =~ ^[0-9]+$ ]] || [ "$model_num" -lt 1 ] || [ "$model_num" -gt "${#MODELS[@]}" ]; then
                    echo -e "${RED}无效的模型编号${RESET}"
                    continue
                fi
                
                # 删除选择的模型
                model_to_remove="${MODELS[$((model_num-1))]}"
                new_models=""
                for model in "${MODELS[@]}"; do
                    if [ "$model" != "$model_to_remove" ]; then
                        if [ -z "$new_models" ]; then
                            new_models="$model"
                        else
                            new_models="$new_models,$model"
                        fi
                    fi
                done
                
                sed -i "s/^VLLM_MODELS=.*/VLLM_MODELS=\"$new_models\"/" .env
                current_models="$new_models"
                echo -e "${GREEN}已移除模型 $model_to_remove${RESET}"
                ;;
            4)
                echo -e "${BLUE}模型信息与显存需求:${RESET}"
                echo -e "7-8B 模型 (如Hermes-3, Qwen2.5-7B等): 约需8GB显存"
                echo -e "24-32B 模型 (如Mistral-Small-24B等): 约需24GB显存"
                echo -e "70B 模型: 约需70GB显存，可使用多GPU模式"
                
                echo -e "\n${YELLOW}注意:${RESET}"
                echo -e "1. 显存需求与量化选项和推理配置有关"
                echo -e "2. 使用多个模型时确保有足够的总显存"
                echo -e "3. 最好为系统预留至少2GB显存"
                ;;
            5)
                read -p "请输入您的 HuggingFace Token: " hf_token
                if [ -z "$hf_token" ]; then
                    echo -e "${RED}Token不能为空${RESET}"
                    continue
                fi
                sed -i "s/^HUGGINGFACE_TOKEN=.*/HUGGINGFACE_TOKEN=$hf_token/" .env
                echo -e "${GREEN}已设置 HuggingFace Token${RESET}"
                
                # 设置HF_HOME
                username=$(whoami)
                sed -i "s|^HF_HOME=.*|HF_HOME=/home/$username/.cache/huggingface|" .env
                echo -e "${GREEN}已设置 HF_HOME 路径${RESET}"
                ;;
            6)
                return 0
                ;;
            *)
                echo -e "${RED}无效选项，请重新输入！${RESET}"
                ;;
        esac
    done
}

# 模型能力测试
test_model_capabilities() {
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
        return 1
    fi
    
    cd "$INSTALL_DIR"
    
    # 检查LiteLLM是否运行
    if ! curl -s http://localhost:4000/v1/models > /dev/null; then
        echo -e "${RED}LiteLLM服务未运行，无法测试模型${RESET}"
        read -p "是否启动LiteLLM服务？(y/n): " start_litellm
        if [[ "$start_litellm" == "y" ]]; then
            docker-compose up -d litellm
            echo -e "${GREEN}正在启动LiteLLM服务，请稍候...${RESET}"
            sleep 5
        else
            return 1
        fi
    fi
    
    # 查询可用模型
    echo -e "${BLUE}获取可用模型...${RESET}"
    models=$(curl -s http://localhost:4000/v1/models | grep -o '"id": "[^"]*"' | cut -d'"' -f4)
    
    if [ -z "$models" ]; then
        echo -e "${RED}未找到可用模型${RESET}"
        return 1
    fi
    
    echo -e "${GREEN}可用模型:${RESET}"
    i=1
    IFS=$'\n'
    for model in $models; do
        echo -e "$i. $model"
        i=$((i+1))
    done
    
    read -p "请选择要测试的模型编号: " model_num
    if ! [[ "$model_num" =~ ^[0-9]+$ ]] || [ "$model_num" -lt 1 ] || [ "$model_num" -gt "$i" ]; then
        echo -e "${RED}无效的模型编号${RESET}"
        return 1
    fi
    
    model_name=$(echo "$models" | sed -n "${model_num}p")
    
    while true; do
        echo -e "\n${BLUE}模型能力测试 - $model_name${RESET}"
        echo -e "1. 基本对话测试"
        echo -e "2. 工具调用测试"
        echo -e "3. JSON格式输出测试"
        echo -e "4. 返回主菜单"
        read -p "请选择测试类型: " test_choice
        
        case "$test_choice" in
            1)
                read -p "请输入提示词: " prompt
                echo -e "${BLUE}发送请求...${RESET}"
                
                master_key=$(grep "^LITELLM_MASTER_KEY=" .env | cut -d= -f2)
                
                curl -s http://localhost:4000/v1/chat/completions \
                  -H "Content-Type: application/json" \
                  -H "Authorization: Bearer $master_key" \
                  -d "{\"model\": \"$model_name\", \"messages\": [{\"role\": \"user\", \"content\": \"$prompt\"}]}" | jq 2>/dev/null || cat
                ;;
            2)
                echo -e "${BLUE}执行工具调用测试...${RESET}"
                
                master_key=$(grep "^LITELLM_MASTER_KEY=" .env | cut -d= -f2)
                
                # 创建工具调用测试的JSON请求
                cat > /tmp/tool_test.json << EOL
{
  "model": "$model_name",
  "messages": [
    {
      "role": "user",
      "content": "今天日期是多少？然后计算123加456"
    }
  ],
  "tools": [
    {
      "type": "function",
      "function": {
        "name": "get_current_date",
        "description": "获取当前日期",
        "parameters": {
          "type": "object",
          "properties": {},
          "required": []
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "calculator",
        "description": "计算两个数的加减乘除",
        "parameters": {
          "type": "object",
          "properties": {
            "num1": {
              "type": "number",
              "description": "第一个数字"
            },
            "num2": {
              "type": "number",
              "description": "第二个数字"
            },
            "operation": {
              "type": "string",
              "description": "运算类型：add(加法)，subtract(减法)，multiply(乘法)，divide(除法)",
              "enum": ["add", "subtract", "multiply", "divide"]
            }
          },
          "required": ["num1", "num2", "operation"]
        }
      }
    }
  ]
}
EOL
                
                curl -s http://localhost:4000/v1/chat/completions \
                  -H "Content-Type: application/json" \
                  -H "Authorization: Bearer $master_key" \
                  -d @/tmp/tool_test.json | jq 2>/dev/null || cat
                
                rm /tmp/tool_test.json
                ;;
            3)
                echo -e "${BLUE}执行JSON格式输出测试...${RESET}"
                
                master_key=$(grep "^LITELLM_MASTER_KEY=" .env | cut -d= -f2)
                
                # 创建JSON输出测试的JSON请求
                cat > /tmp/json_test.json << EOL
{
  "model": "$model_name",
  "messages": [
    {
      "role": "user",
      "content": "生成一个包含以下字段的用户信息：姓名、年龄、职业、兴趣爱好（数组）"
    }
  ],
  "response_format": {
    "type": "json_object"
  }
}
EOL
                
                curl -s http://localhost:4000/v1/chat/completions \
                  -H "Content-Type: application/json" \
                  -H "Authorization: Bearer $master_key" \
                  -d @/tmp/json_test.json | jq 2>/dev/null || cat
                
                rm /tmp/json_test.json
                ;;
            4)
                return 0
                ;;
            *)
                echo -e "${RED}无效选项，请重新输入！${RESET}"
                ;;
        esac
    done
}

# 菜单
while true; do
    echo -e "\n${BLUE}NapthaAI 一键管理脚本 - ${AUTHOR}${RESET}"
    echo -e "======== 基本操作 ========"
    echo -e "1. 安装 NapthaAI 节点"
    echo -e "2. 更新 NapthaAI 节点"
    echo -e "3. 显示节点状态"
    echo -e "4. 卸载 NapthaAI"
    
    echo -e "\n======== 配置管理 ========"
    echo -e "5. 导出 PRIVATE_KEY"
    echo -e "6. 更换 PEM 文件中的私钥并重新启动节点"
    echo -e "7. 切换启动模式 (Docker/systemd)"
    echo -e "8. 备份/恢复配置"
    
    echo -e "\n======== 服务与模型管理 ========"
    echo -e "9. 查看所有容器日志"
    echo -e "10. 查看特定服务日志"
    echo -e "11. 管理 Ollama 模型"
    echo -e "12. 管理 vLLM 模型"
    echo -e "13. 管理 LiteLLM 服务"
    echo -e "14. 模型能力测试"
    echo -e "15. 查看推荐模型信息"
    echo -e "16. 重置数据库"
    
    echo -e "\n======== 开发与测试 ========"
    echo -e "17. 运行 SDK 示例"
    echo -e "18. 检查系统先决条件"
    
    echo -e "\n0. 退出"
    read -p "请选择操作: " choice

    case "$choice" in
        1) 
           check_prerequisites
           install_node 
           ;;
        2) update_node ;;
        3) show_node_status ;;
        4) uninstall_node ;;
        5) export_private_key ;;
        6) 
            # 更换 PEM 文件中的私钥并重新启动节点
            if replace_private_key_in_pem; then
                stop_and_remove_containers
                cd "$INSTALL_DIR"
                bash launch.sh
                echo -e "${GREEN}密钥已更换并重新启动节点！${RESET}"
            fi
            ;;
        7) switch_launch_mode ;;
        8) backup_restore ;;
        9) view_logs ;;
        10) view_service_logs ;;
        11) manage_ollama_models ;;
        12) manage_vllm_models ;;
        13) manage_litellm ;;
        14) test_model_capabilities ;;
        15) show_recommended_models ;;
        16) reset_database ;;
        17) run_sdk_example ;;
        18) check_prerequisites ;;
        0) echo -e "${BLUE}退出脚本。${RESET}"; exit 0 ;;
        *) echo -e "${RED}无效选项，请重新输入！${RESET}" ;;
    esac
done