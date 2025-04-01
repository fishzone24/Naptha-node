#!/bin/bash

# 设置当遇到错误时立即退出
set -e

# 定义颜色
GREEN='\e[32m'
YELLOW='\e[33m'
RED='\e[31m'
BLUE='\e[34m'
RESET='\e[0m'

# 脚本当前路径
SCRIPT_PATH="$0"
SCRIPT_NAME=$(basename "$SCRIPT_PATH")

# Naptha 安装目录
INSTALL_DIR="$HOME/naptha-node"

# 自安装模式检测 - 如果脚本是通过curl等方式直接执行的，可能需要先保存到本地
if [[ "$SCRIPT_NAME" != "Naptha-node.sh" ]]; then
    echo -e "${BLUE}==================================================================${RESET}"
    echo -e "${GREEN}Naptha 节点一键安装脚本${RESET}"
    echo -e "${YELLOW}此脚本将下载并安装 Naptha 节点管理工具${RESET}"
    echo -e "${BLUE}==================================================================${RESET}"
    
    # 下载脚本到本地
    echo -e "${GREEN}正在下载 Naptha 节点管理脚本...${RESET}"
    curl -fsSL https://raw.githubusercontent.com/fishzone24/Naptha-node/master/Naptha-node.sh -o Naptha-node.sh
    
    # 检查下载是否成功
    if [ $? -ne 0 ]; then
        echo -e "${RED}下载失败，请检查网络连接或脚本地址是否正确${RESET}"
        exit 1
    fi
    
    # 设置执行权限
    echo -e "${GREEN}设置执行权限...${RESET}"
    chmod +x Naptha-node.sh
    
    # 运行脚本
    echo -e "${GREEN}启动 Naptha 节点管理脚本...${RESET}"
    ./Naptha-node.sh
    exit 0
fi

# 署名和说明
cat << "EOF"

   __   _         _                                    ___    _  _   
  / _| (_)       | |                                  |__ \  | || |  
 | |_   _   ___  | |__    ____   ___    _ __     ___     ) | | || |_ 
 |  _| | | / __| | '_ \  |_  /  / _ \  | '_ \   / _ \   / /  |__   _|
 | |   | | \__ \ | | | |  / /  | (_) | | | | | |  __/  / /_     | |  
 |_|   |_| |___/ |_| |_| /___|  \___/  |_| |_|  \___| |____|    |_|  
                                                                     
                                                                     

                                                                                                                                  

EOF
echo -e "${BLUE}==================================================================${RESET}"
echo -e "${GREEN}Naptha 节点一键管理脚本${RESET}"
echo -e "${YELLOW}脚本作者: fishzone24 - 推特: https://x.com/fishzone24${RESET}"
echo -e "${YELLOW}此脚本为免费开源脚本，如有问题请提交 issue${RESET}"
echo -e "${BLUE}==================================================================${RESET}"

# 生成随机端口号 (10000-65535)
generate_random_port() {
    echo $(( ( RANDOM % 55535 ) + 10000 ))
}

# 检查端口是否可用
check_port_available() {
    local port=$1
    if netstat -tuln | grep -q ":$port "; then
        return 1
    else
        return 0
    fi
}

# 获取可用端口
get_available_port() {
    local port
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        port=$(generate_random_port)
        if check_port_available $port; then
            echo $port
            return 0
        fi
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}无法找到可用端口，请手动指定端口${RESET}"
    return 1
}

# 检查并安装依赖
check_dependencies() {
    echo -e "${GREEN}正在检查系统依赖...${RESET}"
    
    # 检查并安装 python3-venv
    if ! dpkg -l | grep -q "python3-venv"; then
        echo -e "${YELLOW}检测到 python3-venv 未安装，正在安装...${RESET}"
        sudo apt update
        sudo apt install -y python3-venv
    fi
    
    # 检查并安装 Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Docker 未安装，正在安装 Docker...${RESET}"
        curl -fsSL https://get.docker.com | sudo bash
        sudo systemctl enable --now docker
    else
        echo -e "${GREEN}Docker 已安装${RESET}"
    fi

    # 检查并安装 Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${YELLOW}Docker Compose 未安装，正在安装...${RESET}"
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    else
        echo -e "${GREEN}Docker Compose 已安装${RESET}"
    fi
}

# 创建虚拟环境并安装依赖
create_virtualenv() {
    echo -e "${GREEN}正在创建 Python 虚拟环境并安装依赖...${RESET}"
    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip
    pip install docker requests
    echo -e "${GREEN}虚拟环境创建完成，依赖安装成功！${RESET}"
}

# 安装 Naptha 节点
install_naptha_node() {
    echo -e "${GREEN}正在安装 Naptha 节点...${RESET}"
    
    # 检查依赖
    check_dependencies
    
    # 询问 Ollama 端口
    local ollama_port
    echo -e "${YELLOW}Ollama 默认端口为 11434，如果该端口已被占用，您可以选择：${RESET}"
    echo -e "1. 使用随机端口"
    echo -e "2. 手动指定端口"
    echo -e "3. 使用默认端口 (11434)"
    read -p "请选择 [1/2/3]: " port_choice
    
    case $port_choice in
        1)
            ollama_port=$(get_available_port)
            if [ $? -ne 0 ]; then
                echo -e "${RED}获取随机端口失败，请稍后再试或手动指定端口${RESET}"
                return 1
            fi
            echo -e "${GREEN}已选择随机端口: ${YELLOW}$ollama_port${RESET}"
            ;;
        2)
            read -p "请输入要使用的端口号 (10000-65535): " custom_port
            if ! [[ "$custom_port" =~ ^[0-9]+$ ]] || [ "$custom_port" -lt 10000 ] || [ "$custom_port" -gt 65535 ]; then
                echo -e "${RED}无效的端口号，端口号必须是 10000-65535 之间的数字${RESET}"
                return 1
            fi
            if ! check_port_available $custom_port; then
                echo -e "${RED}端口 $custom_port 已被占用，请选择其他端口${RESET}"
                return 1
            fi
            ollama_port=$custom_port
            echo -e "${GREEN}已选择端口: ${YELLOW}$ollama_port${RESET}"
            ;;
        3|*)
            ollama_port=11434
            echo -e "${GREEN}将使用默认端口: ${YELLOW}$ollama_port${RESET}"
            ;;
    esac
    
    # 检查并删除已存在的安装目录
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}目标目录已存在，正在删除...${RESET}"
        rm -rf "$INSTALL_DIR"
    fi
    
    # 克隆仓库
    echo -e "${GREEN}正在克隆 Naptha 节点仓库...${RESET}"
    git clone https://github.com/NapthaAI/naptha-node.git "$INSTALL_DIR"
    
    # 进入安装目录
    cd "$INSTALL_DIR"
    
    # 创建虚拟环境并安装依赖
    create_virtualenv
    
    # 配置 .env 文件
    if [ -f .env.example ]; then
        cp .env.example .env
        echo -e "${GREEN}.env.example 文件已复制为 .env${RESET}"
        
        # 修改配置
        sed -i 's/LAUNCH_DOCKER=false/LAUNCH_DOCKER=true/' .env
        sed -i 's|HF_HOME=/home/<youruser>/.cache/huggingface|HF_HOME=/root/.cache/huggingface|' .env
        sed -i 's/^LLM_BACKEND=.*/LLM_BACKEND=ollama/' .env
        
        echo -e "${GREEN}已完成 .env 文件配置${RESET}"
    else
        echo -e "${RED}.env.example 文件不存在，无法配置环境${RESET}"
        return 1
    fi
    
    # 修改 docker-compose.yml 文件中的 Ollama 端口
    if [ -f "docker-compose.yml" ] && [ "$ollama_port" != "11434" ]; then
        echo -e "${GREEN}修改 Ollama 端口为 ${YELLOW}$ollama_port${RESET}"
        
        # 备份原始 docker-compose.yml 文件
        cp docker-compose.yml docker-compose.yml.bak
        echo -e "${GREEN}已备份原始 docker-compose.yml 文件为 ${YELLOW}docker-compose.yml.bak${RESET}"
        
        # 创建新的 docker-compose.yml 文件
        cat > docker-compose.yml << EOF
version: '3.8'

services:
  ollama:
    container_name: node-ollama
    image: ollama/ollama:latest
    restart: unless-stopped
    command: ["ollama", "serve", "--port", "$ollama_port"]
    ports:
      - "$ollama_port:$ollama_port"
    environment:
      - OLLAMA_PORT=$ollama_port
    volumes:
      - ~/.ollama:/root/.ollama
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]

  naptha:
    container_name: naptha-node
    image: napthaai/naptha-node:latest
    restart: unless-stopped
    ports:
      - "7001:7001"
    environment:
      - NODE_PRIVATE_KEY=${NODE_PRIVATE_KEY}
      - NODE_PUBLIC_KEY=${NODE_PUBLIC_KEY}
      - NODE_PORT=7001
      - OLLAMA_BASE_URL=http://node-ollama:$ollama_port
    volumes:
      - ./data:/app/data
    depends_on:
      - ollama
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
EOF

        echo -e "${GREEN}已完全重写 docker-compose.yml 文件${RESET}"
        echo -e "${YELLOW}新的 docker-compose.yml 配置:${RESET}"
        cat docker-compose.yml
        
        # 确保 .env 文件中有正确的 OLLAMA_BASE_URL 配置
        echo -e "${GREEN}更新应用程序连接配置，使用新的 Ollama 端口${RESET}"
        if grep -q "OLLAMA_BASE_URL" .env; then
            sed -i "s|OLLAMA_BASE_URL=.*|OLLAMA_BASE_URL=http://node-ollama:$ollama_port|" .env
        else
            echo "OLLAMA_BASE_URL=http://node-ollama:$ollama_port" >> .env
        fi
        
        echo -e "${GREEN}docker-compose.yml 和 .env 文件修改完成${RESET}"
    fi
    
    # 启动节点
    echo -e "${GREEN}正在启动 Naptha 节点...${RESET}"
    bash launch.sh
    
    echo -e "${GREEN}Naptha 节点已成功启动！${RESET}"
    echo -e "访问地址: ${YELLOW}http://$(hostname -I | awk '{print $1}'):7001${RESET}"
    if [ "$ollama_port" != "11434" ]; then
        echo -e "Ollama 端口: ${YELLOW}$ollama_port${RESET} (容器内外均使用此端口)"
    fi
}

# 查看 PRIVATE_KEY
view_private_key() {
    echo -e "${GREEN}查看 PRIVATE_KEY...${RESET}"
    # 寻找可能存在的 PEM 文件
    PEM_FILES=("$INSTALL_DIR"/*.pem)
    
    if [ ${#PEM_FILES[@]} -eq 0 ] || [ ! -f "${PEM_FILES[0]}" ]; then
        echo -e "${RED}没有找到 PEM 文件，请确认节点已正确安装${RESET}"
        return 1
    fi
    
    for pem_file in "${PEM_FILES[@]}"; do
        if [ -f "$pem_file" ]; then
            echo -e "${GREEN}文件: ${YELLOW}$pem_file${RESET}"
            echo -e "${BLUE}----------------------------------------${RESET}"
            cat "$pem_file"
            echo -e "${BLUE}----------------------------------------${RESET}"
        fi
    done
}

# 更换 PRIVATE_KEY 并重启节点
replace_private_key() {
    echo -e "${GREEN}更换 PRIVATE_KEY 并重启节点...${RESET}"
    
    # 检查安装目录是否存在
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}节点安装目录不存在，请先安装节点${RESET}"
        return 1
    fi
    
    # 寻找 PEM 文件
    cd "$INSTALL_DIR"
    PEM_FILES=(*.pem)
    
    if [ ${#PEM_FILES[@]} -eq 0 ] || [ ! -f "${PEM_FILES[0]}" ]; then
        echo -e "${RED}没有找到 PEM 文件，请确认节点已正确安装${RESET}"
        return 1
    fi
    
    PEM_FILE="${PEM_FILES[0]}"
    echo -e "${GREEN}找到 PEM 文件: ${YELLOW}$PEM_FILE${RESET}"
    
    # 请求新的 PRIVATE_KEY
    echo -e "${YELLOW}请输入新的 PRIVATE_KEY (输入后将不可见):${RESET}"
    read -s NEW_PRIVATE_KEY
    
    if [ -z "$NEW_PRIVATE_KEY" ]; then
        echo -e "${RED}PRIVATE_KEY 不能为空${RESET}"
        return 1
    fi
    
    # 备份原 PEM 文件
    cp "$PEM_FILE" "${PEM_FILE}.bak"
    echo -e "${GREEN}已备份原 PEM 文件为 ${YELLOW}${PEM_FILE}.bak${RESET}"
    
    # 写入新的 PRIVATE_KEY
    echo "$NEW_PRIVATE_KEY" > "$PEM_FILE"
    echo -e "${GREEN}新的 PRIVATE_KEY 已写入${RESET}"
    
    # 重启节点
    restart_node
}

# 停止节点
stop_node() {
    echo -e "${YELLOW}正在停止 Naptha 节点...${RESET}"
    
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}节点安装目录不存在，请先安装节点${RESET}"
        return 1
    fi
    
    cd "$INSTALL_DIR"
    if [ -f "docker-compose.yml" ]; then
        docker-compose down
        echo -e "${GREEN}Naptha 节点已停止${RESET}"
    else
        echo -e "${RED}找不到 docker-compose.yml 文件，无法停止节点${RESET}"
        return 1
    fi
}

# 重启节点
restart_node() {
    echo -e "${GREEN}正在重启 Naptha 节点...${RESET}"
    
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}节点安装目录不存在，请先安装节点${RESET}"
        return 1
    fi
    
    # 先停止节点
    cd "$INSTALL_DIR"
    if [ -f "docker-compose.yml" ]; then
        echo -e "${YELLOW}停止节点...${RESET}"
        docker-compose down
    fi
    
    # 启动节点
    echo -e "${GREEN}启动节点...${RESET}"
    bash launch.sh
    
    echo -e "${GREEN}Naptha 节点已重启${RESET}"
}

# 查看日志
view_logs() {
    echo -e "${GREEN}查看 Naptha 节点日志...${RESET}"
    
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}节点安装目录不存在，请先安装节点${RESET}"
        return 1
    fi
    
    cd "$INSTALL_DIR"
    if [ -f "docker-compose.yml" ]; then
        docker-compose logs -f --tail=300
    else
        echo -e "${RED}找不到 docker-compose.yml 文件，无法查看日志${RESET}"
        return 1
    fi
}

# 删除 Naptha 节点
remove_naptha_node() {
    echo -e "${YELLOW}正在删除 Naptha 节点...${RESET}"
    
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}节点安装目录不存在，无需删除${RESET}"
        return 0
    fi
    
    # 停止并删除容器
    cd "$INSTALL_DIR"
    if [ -f "docker-compose.yml" ]; then
        docker-compose down
    fi
    
    # 删除目录
    cd ~
    rm -rf "$INSTALL_DIR"
    
    echo -e "${GREEN}Naptha 节点已成功删除${RESET}"
}

# 主菜单
function main_menu() {
    while true; do
        echo -e "\n${BLUE}==================================================================${RESET}"
        echo -e "${GREEN}Naptha 节点管理菜单${RESET}"
        echo -e "${BLUE}==================================================================${RESET}"
        echo -e "1. 安装 Naptha 节点"
        echo -e "2. 查看 PRIVATE_KEY"
        echo -e "3. 更换 PRIVATE_KEY 并重启节点"
        echo -e "4. 停止节点"
        echo -e "5. 重启节点"
        echo -e "6. 查看日志"
        echo -e "7. 删除 Naptha 节点"
        echo -e "0. 退出脚本"
        echo -e "${BLUE}==================================================================${RESET}"
        
        read -p "请输入选项: " option
        
        case $option in
            1)
                install_naptha_node
                read -n 1 -s -r -p "按任意键继续..."
                ;;
            2)
                view_private_key
                read -n 1 -s -r -p "按任意键继续..."
                ;;
            3)
                replace_private_key
                read -n 1 -s -r -p "按任意键继续..."
                ;;
            4)
                stop_node
                read -n 1 -s -r -p "按任意键继续..."
                ;;
            5)
                restart_node
                read -n 1 -s -r -p "按任意键继续..."
                ;;
            6)
                view_logs
                # 日志查看工具会持续运行，不需要按键继续
                ;;
            7)
                read -p "确定要删除 Naptha 节点吗？(y/n): " confirm
                if [[ $confirm == [yY] ]]; then
                    remove_naptha_node
                fi
                read -n 1 -s -r -p "按任意键继续..."
                ;;
            0)
                echo -e "${GREEN}感谢使用，再见！${RESET}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选项，请重新选择${RESET}"
                read -n 1 -s -r -p "按任意键继续..."
                ;;
        esac
    done
}

# 开始执行主菜单
main_menu

# 一键安装命令
# 使用以下命令可以一键下载、设置权限并运行此脚本：
# curl -fsSL https://raw.githubusercontent.com/fishzone24/Naptha-node/master/Naptha-node.sh -o Naptha-node.sh && chmod +x Naptha-node.sh && ./Naptha-node.sh 