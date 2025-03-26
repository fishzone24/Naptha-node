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

# 安装 Docker
install_docker() {
    echo -e "${BLUE}正在安装 Docker...${RESET}"
    apt-get update
    apt-get install -y ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl enable docker
    systemctl start docker
    echo -e "${GREEN}Docker 安装完成！${RESET}"
}

# 用户注册
register_user() {
    echo -e "${BLUE}开始 NapthaAI 用户注册...${RESET}"
    
    # 提示用户输入用户名和密码
    read -p "请输入您的 NapthaAI Hub 用户名: " HUB_USERNAME
    read -s -p "请输入您的 NapthaAI Hub 密码: " HUB_PASSWORD
    echo
    
    # 创建 .env 文件
    cat > "$INSTALL_DIR/.env" << EOL
# 用户认证
HUB_USERNAME=${HUB_USERNAME}
HUB_PASSWORD=${HUB_PASSWORD}

# Docker 设置
DOCKER_COMPOSE_VERSION=v2.24.5
DOCKER_COMPOSE_ARCH=linux-x86_64
DOCKER_COMPOSE_BASE_URL=https://github.com/docker/compose/releases/download

# SurrealDB 设置
HUB_DB_SURREAL_USER=root
HUB_DB_SURREAL_PASS=root
HUB_DB_SURREAL_PORT=3001
HUB_DB_SURREAL_NS=test
HUB_DB_SURREAL_DB=test
HUB_DB_SURREAL_HOST=surreal

# RabbitMQ 设置
RABBITMQ_DEFAULT_USER=username
RABBITMQ_DEFAULT_PASS=password
RABBITMQ_DEFAULT_VHOST=/
RABBITMQ_ERLANG_COOKIE=secret_cookie
RABBITMQ_MANAGEMENT_PORT=15672

# 节点设置
NODE_PORT=7001
REGISTER_NODE_WITH_HUB=true
LOCAL_HUB=true
EOL

    echo -e "${GREEN}用户注册完成！${RESET}"
}

# 安装 NapthaAI 节点
install_node() {
    echo -e "${BLUE}正在安装 NapthaAI 节点...${RESET}"
    
    # 创建必要的目录
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/data/surreal"
    mkdir -p "$INSTALL_DIR/data/rabbitmq"
    mkdir -p "$INSTALL_DIR/data/postgres"
    
    # 创建 docker-compose.yml 文件
    cat > "$INSTALL_DIR/docker-compose.yml" << 'EOL'
version: '3.8'

services:
  node-app:
    image: napthaai/node:latest
    container_name: node-app
    ports:
      - "7001:7001"
    environment:
      - NODE_PORT=7001
      - REGISTER_NODE_WITH_HUB=true
      - LOCAL_HUB=true
      - HUB_USERNAME=${HUB_USERNAME}
      - HUB_PASSWORD=${HUB_PASSWORD}
    volumes:
      - ./data:/data
    depends_on:
      - surreal
      - rabbitmq
      - pgvector
    networks:
      - naptha-network

  surreal:
    image: surrealdb/surrealdb:latest
    container_name: surreal
    ports:
      - "3001:3001"
    environment:
      - SURREAL_USER=root
      - SURREAL_PASS=root
    volumes:
      - ./data/surreal:/data
    networks:
      - naptha-network

  rabbitmq:
    image: rabbitmq:3-management
    container_name: rabbitmq
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      - RABBITMQ_DEFAULT_USER=username
      - RABBITMQ_DEFAULT_PASS=password
      - RABBITMQ_DEFAULT_VHOST=/
      - RABBITMQ_ERLANG_COOKIE=secret_cookie
    volumes:
      - ./data/rabbitmq:/var/lib/rabbitmq
    networks:
      - naptha-network

  pgvector:
    image: ankane/pgvector:latest
    container_name: pgvector
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=postgres
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
    networks:
      - naptha-network

networks:
  naptha-network:
    driver: bridge
EOL

    # 启动服务
    cd "$INSTALL_DIR"
    docker-compose down
    docker-compose up -d
    
    echo -e "${GREEN}NapthaAI 节点安装完成！${RESET}"
    echo -e "访问地址: ${YELLOW}http://$(hostname -I | awk '{print $1}'):7001${RESET}"
    echo -e "RabbitMQ 管理界面: ${YELLOW}http://$(hostname -I | awk '{print $1}'):15672${RESET}"
    echo -e "用户名: ${YELLOW}username${RESET}"
    echo -e "密码: ${YELLOW}password${RESET}"
}

# 检查是否是一键安装命令
if [ "$1" = "--auto-install" ]; then
    echo -e "${BLUE}开始自动安装 NapthaAI 节点...${RESET}"
    install_docker
    register_user
    install_node
    echo -e "${GREEN}安装完成！${RESET}"
    echo -e "访问地址: ${YELLOW}http://$(hostname -I | awk '{print $1}'):7001${RESET}"
    echo -e "RabbitMQ 管理界面: ${YELLOW}http://$(hostname -I | awk '{print $1}'):15672${RESET}"
    echo -e "用户名: ${YELLOW}username${RESET}"
    echo -e "密码: ${YELLOW}password${RESET}"
    exit 0
fi

# 炫酷的 @fishzone24 字符标识
cat << "EOF"

 

   __   _         _                                    ___    _  _   
  / _| (_)       | |                                  |__ \  | || |  
 | |_   _   ___  | |__    ____   ___    _ __     ___     ) | | || |_ 
 |  _| | | / __| | '_ \  |_  /  / _ \  | '_ \   / _ \   / /  |__   _|
 | |   | | \__ \ | | | |  / /  | (_) | | | | | |  __/  / /_     | |  
 |_|   |_| |___/ |_| |_| /___|  \___/  |_| |_|  \___| |____|    |_|  
                                                                     
                                                                     

                                                                                                                                  

EOF

echo -e "${BLUE}x.com/fishzone24${RESET}"

# 署名
AUTHOR="Fishzone24  推特 https://x.com/fishzone24"

# 检查并安装 python3-venv 包
check_python_venv() {
    if ! dpkg -l | grep -q "python3-venv"; then
        echo -e "${YELLOW}检测到 python3-venv 未安装，正在安装...${RESET}"
        sudo apt update
        sudo apt install python3.10-venv
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

# 停止节点容器
stop_containers() {
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}正在停止节点容器...${RESET}"
        cd "$INSTALL_DIR"
        docker-compose stop
    else
        echo -e "${RED}未找到 NapthaAI 节点，无法停止容器！${RESET}"
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

# 重新启动节点
restart_node() {
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}正在重新启动节点...${RESET}"
        cd "$INSTALL_DIR"
        docker-compose down
        docker-compose up -d
        echo -e "${GREEN}节点已重新启动！${RESET}"
    else
        echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
    fi
}

# 卸载 NapthaAI
uninstall_node() {
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}正在停止并删除 NapthaAI 节点的容器和所有文件...${RESET}"
        cd "$INSTALL_DIR"
        docker-compose down --volumes
        cd ~
        rm -rf "$INSTALL_DIR"
        echo -e "${GREEN}NapthaAI 节点已成功卸载，所有容器和数据已删除！${RESET}"
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
    echo -e "6. 停止节点运行 (不删除容器)"
    echo -e "7. 重新启动节点"
    echo -e "8. 查看服务状态"
    echo -e "0. 退出"
    read -p "请选择操作: " choice

    case "$choice" in
        1) install_node ;;
        2) export_private_key ;;
        3) view_logs ;;
        4) uninstall_node ;;
        5) 
            if replace_private_key_in_pem; then
                restart_node
            fi
            ;;
        6) stop_containers ;;
        7) restart_node ;;
        8)
            if [ -d "$INSTALL_DIR" ]; then
                echo -e "${BLUE}显示服务状态...${RESET}"
                cd "$INSTALL_DIR"
                docker-compose ps
            else
                echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
            fi
            ;;
        0) echo -e "${BLUE}退出脚本。${RESET}"; exit 0 ;;
        *) echo -e "${RED}无效选项，请重新输入！${RESET}" ;;
    esac
done
