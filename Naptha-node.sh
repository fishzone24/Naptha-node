@ -0,0 +1,218 @@
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
        sed -i 's/^LLM_BACKEND=.*/LLM_BACKEND=ollama/' "$INSTALL_DIR/.env"
        
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
        
        # 询问是否设置本地 Hub
        read -p "是否运行本地 Hub？(y/n): " run_local_hub
        if [[ "$run_local_hub" == "y" ]]; then
            sed -i 's/^LOCAL_HUB=.*/LOCAL_HUB=true/' "$INSTALL_DIR/.env"
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
        
        # 配置 LLM 模型
        read -p "请选择要使用的 Ollama 模型 (默认为 hermes3:8b): " ollama_models
        if [[ -z "$ollama_models" ]]; then
            ollama_models="hermes3:8b"
        fi
        sed -i "s/^OLLAMA_MODELS=.*/OLLAMA_MODELS=$ollama_models/" "$INSTALL_DIR/.env"
    else
        echo -e "${GREEN}.env 文件已存在，跳过配置...${RESET}"
    fi
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

# 菜单
while true; do
    echo -e "\n${BLUE}NapthaAI 一键管理脚本 - ${AUTHOR}${RESET}"
    echo -e "1. 安装 NapthaAI 节点"
    echo -e "2. 导出 PRIVATE_KEY"
    echo -e "3. 查看所有容器日志 (显示最后 200 行)"
    echo -e "4. 查看特定服务日志"
    echo -e "5. 更换 PEM 文件中的私钥并重新启动节点"
    echo -e "6. 更新 NapthaAI 节点"
    echo -e "7. 显示节点状态"
    echo -e "8. 重置数据库"
    echo -e "9. 运行 SDK 示例"
    echo -e "10. 卸载 NapthaAI"
    echo -e "0. 退出"
    read -p "请选择操作: " choice

    case "$choice" in
        1) install_node ;;
        2) export_private_key ;;
        3) view_logs ;;
        4) view_service_logs ;;
        5) 
            # 更换 PEM 文件中的私钥并重新启动节点
            if replace_private_key_in_pem; then
                stop_and_remove_containers
                cd "$INSTALL_DIR"
                bash launch.sh
                echo -e "${GREEN}密钥已更换并重新启动节点！${RESET}"
            fi
            ;;
        6) update_node ;;
        7) show_node_status ;;
        8) reset_database ;;
        9) run_sdk_example ;;
        10) uninstall_node ;;
        0) echo -e "${BLUE}退出脚本。${RESET}"; exit 0 ;;
        *) echo -e "${RED}无效选项，请重新输入！${RESET}" ;;
    esac
done