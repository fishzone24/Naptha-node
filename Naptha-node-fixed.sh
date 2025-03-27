#!/bin/bash

# 定义颜色
BLUE='\033[36m'  # 海蓝色
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

# NapthaAI 目录
INSTALL_DIR="/root/Naptha-Node"

# 展示标识
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

# 署名
AUTHOR="Fishzone24 节点教程分享 推特 https://x.com/fishzone24"

# 检查并安装 python3-venv 包
check_python_venv() {
    if ! dpkg -l | grep -q "python3-venv"; then
        echo -e "${YELLOW}检测到 python3-venv 未安装，正在安装...${RESET}"
        sudo apt update
        sudo apt install python3.10-venv
    fi
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

# 生成随机私钥
generate_private_key() {
    # 生成32字节（64个十六进制字符）的随机私钥
    openssl rand -hex 32
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

# 手动创建 .env 文件
create_env_file() {
    local username=$1
    local password=$2
    local private_key=$3
    local current_user=$4

    echo -e "${YELLOW}未找到 .env.example 文件，正在手动创建 .env 文件...${RESET}"
    
    cat > .env << EOF
# === NODE ===
# credentials
PRIVATE_KEY=${private_key}
HUB_USERNAME=${username}
HUB_PASSWORD=${password}

# LAUNCH_DOCKER: set to true if launching node w/ docker compose, false if launching node w/ systemd/launchd services
LAUNCH_DOCKER=true
# DOCKER_DEV_MODE: set to true to use Dockerfile-node-dev for development
DOCKER_DEV_MODE=false
NUM_GPUS=0
# DOCKER_JOBS: set to true if you want to run Naptha Modules in Docker containers
DOCKER_JOBS=false

# Servers
USER_COMMUNICATION_PORT=7001
# USER_COMMUNICATION_PROTOCOL options: [http, https]
USER_COMMUNICATION_PROTOCOL=http
NUM_NODE_COMMUNICATION_SERVERS=1
NODE_COMMUNICATION_PORT=7002
# NODE_COMMUNICATION_PROTOCOL options: [grpc, ws]
NODE_COMMUNICATION_PROTOCOL=ws
NODE_IP=localhost
ROUTING_TYPE=direct
ROUTING_URL=ws://node.naptha.ai:8765

# rabbitmq instance 
RMQ_USER=username
RMQ_PASSWORD=password

# === INFERENCE ===
# LLM_BACKEND options: [ollama, vllm]
LLM_BACKEND=ollama
# OLLAMA_MODELS and VLLM_MODELS: use string of models separated by commas
OLLAMA_MODELS=hermes3:8b
VLLM_MODELS=NousResearch/Hermes-3-Llama-3.1-8B

# hosted models
OPENAI_MODELS=gpt-4o-mini
OPENAI_API_KEY=sk-

# for litellm -- set to secure values
LITELLM_MASTER_KEY=sk-abc123
LITELLM_SALT_KEY=sk-abc123

# huggingface - set token to your token that has permission to pull the models you want; home should be your HF home dir
HUGGINGFACE_TOKEN=
HF_HOME=/home/${current_user}/.cache/huggingface

# === STORAGE ===
# local db storage
LOCAL_DB_POSTGRES_PORT=5432
LOCAL_DB_POSTGRES_NAME=naptha
LOCAL_DB_POSTGRES_USERNAME=naptha
LOCAL_DB_POSTGRES_PASSWORD=napthapassword

# file system storage
BASE_OUTPUT_DIR=node/storage/fs
MODULES_SOURCE_DIR=node/storage/hub/modules

# ipfs storage
IPFS_GATEWAY_URL=https://ipfs-api.naptha.work

# === LOCAL HUB ===
# LOCAL_HUB: set to true if you want to run a local hub
LOCAL_HUB=false
# REGISTER_NODE_WITH_HUB: set to true if you want your node to be available as a provider
REGISTER_NODE_WITH_HUB=false
HUB_DB_SURREAL_ROOT_USER=root
HUB_DB_SURREAL_ROOT_PASS=root
HUB_DB_SURREAL_PORT=3001
HUB_DB_SURREAL_NS="naptha"
HUB_DB_SURREAL_NAME="naptha"
EOF

    echo -e "${GREEN}.env 文件已创建！${RESET}"
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

    # 更新 .env 文件中的 PRIVATE_KEY
    sed -i "s/^PRIVATE_KEY=.*/PRIVATE_KEY=$new_private_key/" "$INSTALL_DIR/.env"
    
    return 0
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

    # 获取当前用户名
    CURRENT_USER=$(whoami)

    # 提示用户输入 Hub-Username
    read -p "请输入您的 Hub-Username: " hub_username
    
    # 提示用户输入 Hub-Password
    read -sp "请输入您的 Hub-Password: " hub_password
    echo

    # 生成私钥
    echo -e "${BLUE}正在生成私钥...${RESET}"
    private_key=$(generate_private_key)
    echo -e "${GREEN}私钥已生成！${RESET}"

    # 复制 .env 配置文件
    if [ ! -f ".env" ]; then
        echo -e "${BLUE}创建 .env 配置文件...${RESET}"
        if [ -f ".env.example" ]; then
            cp .env.example .env
            sed -i 's/^LAUNCH_DOCKER=.*/LAUNCH_DOCKER=true/' .env
            sed -i 's/^LLM_BACKEND=.*/LLM_BACKEND=ollama/' .env
            
            # 替换 HF_HOME 中的 <youruser>
            sed -i "s|/home/<youruser>/.cache|/home/$CURRENT_USER/.cache|g" .env
            
            # 设置 Hub 用户名、密码和私钥
            sed -i "s/^HUB_USERNAME=.*/HUB_USERNAME=$hub_username/" .env
            sed -i "s/^HUB_PASSWORD=.*/HUB_PASSWORD=$hub_password/" .env
            sed -i "s/^PRIVATE_KEY=.*/PRIVATE_KEY=$private_key/" .env
        else
            # 如果找不到 .env.example 文件，则手动创建 .env 文件
            create_env_file "$hub_username" "$hub_password" "$private_key" "$CURRENT_USER"
        fi
    fi
    
    # 创建 PEM 文件
    echo -e "${BLUE}创建 PEM 文件...${RESET}"
    echo "$private_key" > "${hub_username}.pem"
    
    # 启动 NapthaAI 节点
    echo -e "${BLUE}启动 NapthaAI 节点...${RESET}"
    bash launch.sh

    echo -e "${GREEN}NapthaAI 节点已成功启动！${RESET}"
    echo -e "访问地址: ${YELLOW}http://$(hostname -I | awk '{print $1}'):7001${RESET}"
    echo -e "您的私钥: ${YELLOW}$private_key${RESET}"
    echo -e "${RED}请妥善保存您的私钥，遗失后将无法恢复！${RESET}"
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

# 菜单
while true; do
    echo -e "\n${BLUE}NapthaAI 一键管理脚本 - ${AUTHOR}${RESET}"
    echo -e "1. 安装 NapthaAI 节点"
    echo -e "2. 导出 PRIVATE_KEY"
    echo -e "3. 查看日志 (显示最后 200 行)"
    echo -e "4. 卸载 NapthaAI"
    echo -e "5. 更换 PEM 文件中的私钥并重新启动节点"
    echo -e "0. 退出"
    read -p "请选择操作: " choice

    case "$choice" in
        1) install_node ;;
        2) export_private_key ;;
        3) view_logs ;;
        4) uninstall_node ;;
        5) 
            # 更换 PEM 文件中的私钥并重新启动节点
            if replace_private_key_in_pem; then
                stop_and_remove_containers
                cd "$INSTALL_DIR"
                bash launch.sh
                echo -e "${GREEN}密钥已更换并重新启动节点！${RESET}"
            fi
            ;;
        0) echo -e "${BLUE}退出脚本。${RESET}"; exit 0 ;;
        *) echo -e "${RED}无效选项，请重新输入！${RESET}" ;;
    esac
done