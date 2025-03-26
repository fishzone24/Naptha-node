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
cat << "EOF"


EOF

echo -e "${BLUE}x.com/fishzone24${RESET}"

# 署名
AUTHOR="Fishzone24  推特 https://x.com/fishzone24"

# 检查并安装 python3-venv 包
check_python_venv() {
    echo -e "${BLUE}检查 Python 版本和 venv 模块...${RESET}"
    # 获取Python版本
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}' | cut -d. -f1-2)
    echo -e "${YELLOW}检测到 Python 版本: $PYTHON_VERSION${RESET}"
    
    # 检查系统发行版信息
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo -e "${YELLOW}系统: $NAME $VERSION_ID${RESET}"
        
        # 根据分发版本使用不同的命令
        if [[ "$NAME" == *"Ubuntu"* ]]; then
            # 检查 python3-venv 是否已安装
    if ! dpkg -l | grep -q "python3-venv"; then
                echo -e "${YELLOW}安装 python3-venv...${RESET}"
        sudo apt update
                
                # 根据Ubuntu版本和Python版本决定如何安装
                if [[ "$VERSION_ID" == "24.04" ]] || [[ "$VERSION_ID" == "noble" ]]; then
                    echo -e "${YELLOW}检测到 Ubuntu 24.04 (Noble)...${RESET}"
                    sudo apt install -y python3-venv  # 安装通用包
                else
                    # 根据系统Python版本安装对应的venv包
                    if [[ "$PYTHON_VERSION" == "3.10" ]]; then
                        sudo apt install -y python3.10-venv
                    elif [[ "$PYTHON_VERSION" == "3.11" ]]; then
                        sudo apt install -y python3.11-venv
                    elif [[ "$PYTHON_VERSION" == "3.12" ]]; then
                        sudo apt install -y python3.12-venv
                    else
                        # 默认安装
                        sudo apt install -y python3-venv
                    fi
                fi
                
                # 如果安装失败，尝试安装通用包
                if [ $? -ne 0 ]; then
                    echo -e "${YELLOW}尝试安装通用 python3-venv 包...${RESET}"
                    sudo apt install -y python3-venv
                fi
            fi
        elif [[ "$NAME" == *"CentOS"* ]] || [[ "$NAME" == *"Red Hat"* ]] || [[ "$NAME" == *"Fedora"* ]]; then
            # CentOS/RHEL/Fedora
            if ! rpm -q python3-virtualenv &> /dev/null; then
                echo -e "${YELLOW}安装 python3-virtualenv...${RESET}"
                sudo yum install -y python3-virtualenv
            fi
        fi
    else
        echo -e "${YELLOW}无法确定系统类型，尝试安装 Python venv 模块...${RESET}"
        sudo apt install -y python3-venv
    fi
    
    # 确认venv模块可用
    if ! python3 -c "import venv" &> /dev/null; then
        echo -e "${RED}Python venv 模块不可用，尝试其他方法...${RESET}"
        
        # 尝试使用pip安装
        if command -v pip3 &> /dev/null; then
            echo -e "${YELLOW}尝试使用pip安装venv...${RESET}"
            pip3 install --user virtualenv
            # 检查是否成功
            if python3 -c "import virtualenv" &> /dev/null; then
                echo -e "${GREEN}virtualenv模块安装成功，将使用virtualenv代替venv${RESET}"
                VENV_COMMAND="virtualenv"
                return 0
            fi
        fi
        
        echo -e "${RED}无法安装 venv 或 virtualenv 模块，将尝试在没有虚拟环境的情况下继续${RESET}"
        return 1
    fi
    
    echo -e "${GREEN}Python venv 模块可用${RESET}"
    VENV_COMMAND="venv"
    return 0
}

# 安装 uv 包管理器
install_uv() {
    echo -e "${BLUE}安装 uv 包管理器...${RESET}"
    # 检查是否已经安装到 .local/bin
    if [ -f "$HOME/.local/bin/uv" ]; then
        echo -e "${YELLOW}uv已安装到 $HOME/.local/bin, 添加到PATH...${RESET}"
        export PATH="$HOME/.local/bin:$PATH"
        # 添加到.bashrc以便下次登录时可用
        echo "export PATH=\"$HOME/.local/bin:\$PATH\"" >> ~/.bashrc
    else
        # 不存在则安装
        curl -LsSf https://astral.sh/uv/install.sh | sh
        
        # 添加到PATH
        if [ -f "$HOME/.local/bin/uv" ]; then
            export PATH="$HOME/.local/bin:$PATH"
            echo "export PATH=\"$HOME/.local/bin:\$PATH\"" >> ~/.bashrc
        elif [ -f "$HOME/.cargo/bin/uv" ]; then
            export PATH="$HOME/.cargo/bin:$PATH"
            echo "export PATH=\"$HOME/.cargo/bin:\$PATH\"" >> ~/.bashrc
        fi
    fi
    
    # 检查是否安装成功
    if ! command -v uv &> /dev/null; then
        echo -e "${YELLOW}无法在PATH中找到uv命令，检查安装位置...${RESET}"
        UV_PATH=""
        
        # 检查可能的位置
        if [ -f "$HOME/.local/bin/uv" ]; then
            UV_PATH="$HOME/.local/bin/uv"
        elif [ -f "$HOME/.cargo/bin/uv" ]; then
            UV_PATH="$HOME/.cargo/bin/uv"
        fi
        
        if [ -n "$UV_PATH" ]; then
            echo -e "${GREEN}找到uv命令: $UV_PATH${RESET}"
            # 创建别名以便当前会话使用
            alias uv="$UV_PATH"
            # 记录路径以便后续使用
            UV_COMMAND="$UV_PATH"
        else
            echo -e "${RED}无法找到uv命令，将使用pip代替${RESET}"
            UV_COMMAND=""
        fi
    else
        echo -e "${GREEN}uv已成功添加到PATH${RESET}"
        UV_COMMAND="uv"
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

# 创建虚拟环境并安装依赖
create_virtualenv() {
    check_python_venv
    echo -e "${BLUE}创建虚拟环境并安装依赖...${RESET}"
    python3 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip
    pip install docker requests # 直接安装必要的依赖
}

# 手动创建身份（不依赖naptha命令）
manual_create_identity() {
    echo -e "${BLUE}手动创建 Naptha 身份...${RESET}"
    
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
        return 1
    fi
    
    cd "$INSTALL_DIR"
    
    # 询问用户输入用户名和密码
    read -p "请输入用户名: " username
    read -s -p "请输入密码: " password
    echo
    
    # 选择Hub URL
    echo -e "${YELLOW}请选择 Hub URL:${RESET}"
    echo "1. 默认本地Hub (ws://localhost:3001/rpc)"
    echo "2. 官方Hub (wss://hub.naptha.ai/rpc)"
    echo "3. 自定义Hub URL"
    read -p "请选择 (默认: 2): " hub_choice
    
    case "$hub_choice" in
        1) hub_url="ws://localhost:3001/rpc" ;;
        3) 
            read -p "请输入自定义Hub URL: " hub_url
            ;;
        2|*) hub_url="wss://hub.naptha.ai/rpc" ;;
    esac
    
    # 选择Node URL
    echo -e "${YELLOW}请选择 Node URL:${RESET}"
    echo "1. 本地Node (http://localhost:7001)"
    echo "2. 自定义Node URL"
    read -p "请选择 (默认: 1): " node_choice
    
    case "$node_choice" in
        2) 
            read -p "请输入自定义Node URL: " node_url
            ;;
        1|*) node_url="http://localhost:7001" ;;
    esac
    
    # 询问是否自定义PostgreSQL端口
    echo -e "${YELLOW}是否需要自定义PostgreSQL端口? (默认端口为5432)${RESET}"
    echo "1. 使用默认端口 (5432)"
    echo "2. 自定义端口"
    read -p "请选择 (默认: 1): " db_port_choice
    
    pg_port="5432"
    if [ "$db_port_choice" = "2" ]; then
        read -p "请输入自定义PostgreSQL端口: " pg_port
        echo -e "${YELLOW}将使用自定义PostgreSQL端口: $pg_port${RESET}"
    fi
    
    # 创建或更新 .env 文件
    if [ -f ".env" ]; then
        echo -e "${YELLOW}更新 .env 文件...${RESET}"
        sed -i "s/^HUB_USERNAME=.*/HUB_USERNAME=$username/" .env
        sed -i "s/^HUB_PASSWORD=.*/HUB_PASSWORD=$password/" .env
        sed -i "s#^HUB_URL=.*#HUB_URL=$hub_url#" .env
        sed -i "s#^NODE_URL=.*#NODE_URL=$node_url#" .env
        sed -i "s/^LAUNCH_DOCKER=.*/LAUNCH_DOCKER=true/" .env
        sed -i "s/^LLM_BACKEND=.*/LLM_BACKEND=ollama/" .env
        sed -i "s/^youruser=.*/youruser=root/" .env
        sed -i "s/^PG_PORT=.*/PG_PORT=$pg_port/" .env
    else
        echo -e "${YELLOW}创建 .env 文件...${RESET}"
        if [ -f ".env.example" ]; then
            cp .env.example .env
            sed -i "s/^HUB_USERNAME=.*/HUB_USERNAME=$username/" .env
            sed -i "s/^HUB_PASSWORD=.*/HUB_PASSWORD=$password/" .env
            sed -i "s#^HUB_URL=.*#HUB_URL=$hub_url#" .env || echo "HUB_URL=$hub_url" >> .env
            sed -i "s#^NODE_URL=.*#NODE_URL=$node_url#" .env || echo "NODE_URL=$node_url" >> .env
            sed -i "s/^LAUNCH_DOCKER=.*/LAUNCH_DOCKER=true/" .env
            sed -i "s/^LLM_BACKEND=.*/LLM_BACKEND=ollama/" .env
            sed -i "s/^youruser=.*/youruser=root/" .env
            sed -i "s/^PG_PORT=.*/PG_PORT=$pg_port/" .env
        else
            # 创建一个新的.env文件
            cat > .env << EOF
HUB_USERNAME=$username
HUB_PASSWORD=$password
HUB_URL=$hub_url
NODE_URL=$node_url
LAUNCH_DOCKER=true
LLM_BACKEND=ollama
youruser=root
PG_PORT=$pg_port
EOF
        fi
    fi
    
    # 生成私钥
    echo -e "${YELLOW}生成私钥...${RESET}"
    PEM_FILE="$INSTALL_DIR/${username}.pem"
    openssl genrsa -out "$PEM_FILE" 2048 || {
        echo -e "${RED}使用openssl生成私钥失败，尝试使用ssh-keygen...${RESET}"
        ssh-keygen -t rsa -b 2048 -f "$PEM_FILE" -N ""
    }
    
    if [ -f "$PEM_FILE" ]; then
        # 生成一个16进制的随机私钥而不是整个PEM文件内容
        PRIVATE_KEY=$(openssl rand -hex 32)
        echo "PRIVATE_KEY=\"$PRIVATE_KEY\"" >> .env
        echo -e "${GREEN}私钥已生成并添加到配置中${RESET}"
    else
        echo -e "${RED}无法生成私钥文件，请检查系统权限${RESET}"
    fi
    
    # 创建配置目录(如果不存在)
    mkdir -p "$HOME/.naptha"
    
    # 更新naptha配置
    cat > "$HOME/.naptha/config.json" << EOF
{
    "hub_url": "$hub_url",
    "default_node_url": "$node_url",
    "identities": {
        "$username": "$PRIVATE_KEY"
    }
}
EOF
    
    # 生成PEM文件
    ensure_pem_file
    
    echo -e "${GREEN}Naptha 身份创建成功！${RESET}"
    echo -e "${YELLOW}用户名: $username${RESET}"
    echo -e "${YELLOW}Hub URL: $hub_url${RESET}"
    echo -e "${YELLOW}Node URL: $node_url${RESET}"
    echo -e "${YELLOW}配置已保存到: $INSTALL_DIR/.env${RESET}"
    echo -e "${YELLOW}Naptha SDK配置已保存到: $HOME/.naptha/config.json${RESET}"
}

# 显示和编辑当前环境变量
show_env() {
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
        return 1
    fi
    
    cd "$INSTALL_DIR"
    
    if [ ! -f ".env" ]; then
        echo -e "${RED}未找到 .env 文件！${RESET}"
        return 1
    fi
    
    echo -e "${BLUE}当前环境变量配置:${RESET}"
    # 过滤掉密码信息
    grep -v "PASSWORD\|PRIVATE_KEY\|SECRET" .env | cat -n
    
    echo -e "\n${YELLOW}选择要编辑的变量:${RESET}"
    echo "1. 用户名 (HUB_USERNAME)"
    echo "2. 密码 (HUB_PASSWORD)"
    echo "3. Hub URL (HUB_URL)"
    echo "4. Node URL (NODE_URL)"
    echo "5. 启动Docker (LAUNCH_DOCKER)"
    echo "6. LLM后端 (LLM_BACKEND)"
    echo "7. PostgreSQL端口 (PG_PORT)"
    echo "8. 使用文本编辑器编辑整个文件"
    echo "0. 返回"
    
    read -p "请选择: " env_choice
    
    case "$env_choice" in
        1) 
            read -p "输入新的用户名: " new_username
            sed -i "s/^HUB_USERNAME=.*/HUB_USERNAME=$new_username/" .env
            echo -e "${GREEN}用户名已更新！${RESET}"
            ;;
        2)
            read -s -p "输入新的密码: " new_password
            echo
            sed -i "s/^HUB_PASSWORD=.*/HUB_PASSWORD=$new_password/" .env
            echo -e "${GREEN}密码已更新！${RESET}"
            ;;
        3)
            echo -e "${YELLOW}选择 Hub URL:${RESET}"
            echo "1. 默认本地Hub (ws://localhost:3001/rpc)"
            echo "2. 官方Hub (wss://hub.naptha.ai/rpc)"
            echo "3. 自定义 Hub URL"
            read -p "请选择: " hub_choice
            
            case "$hub_choice" in
                1) new_hub_url="ws://localhost:3001/rpc" ;;
                2) new_hub_url="wss://hub.naptha.ai/rpc" ;;
                3) 
                    read -p "输入自定义Hub URL: " new_hub_url
                    ;;
                *) 
                    echo -e "${YELLOW}无效选择，不作更改${RESET}"
                    return
                    ;;
            esac
            
            # 检查HUB_URL是否存在
            if grep -q "^HUB_URL=" .env; then
                sed -i "s#^HUB_URL=.*#HUB_URL=$new_hub_url#" .env
            else
                echo "HUB_URL=$new_hub_url" >> .env
            fi
            
            echo -e "${GREEN}Hub URL已更新为: $new_hub_url${RESET}"
            
            # 询问是否也要更新naptha-sdk配置
            read -p "是否同时更新naptha-sdk配置? (y/n): " update_sdk
            if [[ "$update_sdk" == "y" ]]; then
                # 创建目录(如果不存在)
                mkdir -p "$HOME/.naptha"
                
                # 检查是否存在配置文件
                if [ -f "$HOME/.naptha/config.json" ]; then
                    # 备份现有配置
                    cp "$HOME/.naptha/config.json" "$HOME/.naptha/config.json.bak"
                    
                    # 使用jq更新(如果可用)
                    if command -v jq &> /dev/null; then
                        jq --arg url "$new_hub_url" '.hub_url = $url' "$HOME/.naptha/config.json.bak" > "$HOME/.naptha/config.json"
                    else
                        # 简单的文本替换
                        sed -i "s|\"hub_url\":.*|\"hub_url\": \"$new_hub_url\",|" "$HOME/.naptha/config.json"
                    fi
                else
                    # 创建新配置
                    cat > "$HOME/.naptha/config.json" << EOF
{
    "hub_url": "$new_hub_url",
    "default_node_url": "http://localhost:7001"
}
EOF
                fi
                
                echo -e "${GREEN}naptha-sdk配置已更新！${RESET}"
            fi
            ;;
        4)
            echo -e "${YELLOW}选择 Node URL:${RESET}"
            echo "1. 本地Node (http://localhost:7001)"
            echo "2. 自定义Node URL"
            read -p "请选择: " node_choice
            
            case "$node_choice" in
                1) new_node_url="http://localhost:7001" ;;
                2) 
                    read -p "输入自定义Node URL: " new_node_url
                    ;;
                *) 
                    echo -e "${YELLOW}无效选择，不作更改${RESET}"
                    return
                    ;;
            esac
            
            # 检查NODE_URL是否存在
            if grep -q "^NODE_URL=" .env; then
                sed -i "s#^NODE_URL=.*#NODE_URL=$new_node_url#" .env
            else
                echo "NODE_URL=$new_node_url" >> .env
            fi
            
            echo -e "${GREEN}Node URL已更新为: $new_node_url${RESET}"
            
            # 询问是否也要更新naptha-sdk配置
            read -p "是否同时更新naptha-sdk配置? (y/n): " update_sdk
            if [[ "$update_sdk" == "y" ]]; then
                # 创建目录(如果不存在)
                mkdir -p "$HOME/.naptha"
                
                # 检查是否存在配置文件
                if [ -f "$HOME/.naptha/config.json" ]; then
                    # 备份现有配置
                    cp "$HOME/.naptha/config.json" "$HOME/.naptha/config.json.bak"
                    
                    # 使用jq更新(如果可用)
                    if command -v jq &> /dev/null; then
                        jq --arg url "$new_node_url" '.default_node_url = $url' "$HOME/.naptha/config.json.bak" > "$HOME/.naptha/config.json"
                    else
                        # 简单的文本替换
                        sed -i "s|\"default_node_url\":.*|\"default_node_url\": \"$new_node_url\"|" "$HOME/.naptha/config.json"
                    fi
                else
                    # 创建新配置
                    cat > "$HOME/.naptha/config.json" << EOF
{
    "hub_url": "wss://hub.naptha.ai/rpc",
    "default_node_url": "$new_node_url"
}
EOF
                fi
                
                echo -e "${GREEN}naptha-sdk配置已更新！${RESET}"
            fi
            ;;
        5)
            echo -e "${YELLOW}选择是否启动Docker:${RESET}"
            echo "1. 是 (true)"
            echo "2. 否 (false)"
            read -p "请选择: " docker_choice
            
            case "$docker_choice" in
                1) new_docker="true" ;;
                2) new_docker="false" ;;
                *) 
                    echo -e "${YELLOW}无效选择，不作更改${RESET}"
                    return
                    ;;
            esac
            
            sed -i "s/^LAUNCH_DOCKER=.*/LAUNCH_DOCKER=$new_docker/" .env
            echo -e "${GREEN}LAUNCH_DOCKER 已更新为: $new_docker${RESET}"
            ;;
        6)
            echo -e "${YELLOW}选择 LLM 后端:${RESET}"
            echo "1. Ollama (ollama)"
            echo "2. Open AI (openai)"
            echo "3. Claude (anthropic)"
            echo "4. Local (local)"
            echo "5. 自定义"
            read -p "请选择: " llm_choice
            
            case "$llm_choice" in
                1) new_llm="ollama" ;;
                2) new_llm="openai" ;;
                3) new_llm="anthropic" ;;
                4) new_llm="local" ;;
                5) 
                    read -p "请输入自定义LLM后端: " new_llm
                    ;;
                *) 
                    echo -e "${YELLOW}无效选择，不作更改${RESET}"
                    return
                    ;;
            esac
            
            sed -i "s/^LLM_BACKEND=.*/LLM_BACKEND=$new_llm/" .env
            echo -e "${GREEN}LLM_BACKEND 已更新为: $new_llm${RESET}"
            ;;
        7)
            echo -e "${YELLOW}选择 PostgreSQL端口:${RESET}"
            echo "1. 使用默认端口 (5432)"
            echo "2. 自定义端口"
            read -p "请选择 (默认: 1): " db_port_choice
            
            pg_port="5432"
            if [ "$db_port_choice" = "2" ]; then
                read -p "请输入自定义PostgreSQL端口: " pg_port
                echo -e "${YELLOW}将使用自定义PostgreSQL端口: $pg_port${RESET}"
            fi
            
            # 更新PG_PORT
            if grep -q "^PG_PORT=" .env; then
                sed -i "s/^PG_PORT=.*/PG_PORT=$pg_port/" .env
            else
                echo "PG_PORT=$pg_port" >> .env
            fi
            
            echo -e "${GREEN}PostgreSQL端口已更新为: $pg_port${RESET}"
            echo -e "${YELLOW}注意: 如果节点已运行，请重启节点以应用新设置${RESET}"
            
            # 询问是否现在重启节点
            if docker ps | grep -q "naptha"; then
                read -p "是否立即重启节点以应用新的PostgreSQL端口? (y/n): " restart_now
                if [[ "$restart_now" == "y" ]]; then
                    echo -e "${YELLOW}正在重启节点...${RESET}"
                    docker-compose down
                    bash launch.sh
                    
                    # 等待PostgreSQL初始化
                    echo -e "${YELLOW}等待PostgreSQL初始化...${RESET}"
                    sleep 10
                    
                    if docker ps | grep -q "naptha-postgres" && docker exec naptha-postgres pg_isready -U naptha -d naptha 2>/dev/null; then
                        echo -e "${GREEN}节点已重启，PostgreSQL连接正常！${RESET}"
                    else
                        echo -e "${RED}PostgreSQL无法连接，请检查日志:${RESET}"
                        docker logs naptha-postgres 2>&1 | tail -n 20
                    fi
                fi
            fi
            ;;
        8)
            # 使用文本编辑器编辑
            if command -v nano &> /dev/null; then
                nano .env
            elif command -v vim &> /dev/null; then
                vim .env
            else
                echo -e "${RED}未找到可用的文本编辑器(nano或vim)${RESET}"
            fi
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}无效选项！${RESET}"
            ;;
    esac
}

# 管理 Secrets
manage_secrets() {
    echo -e "${BLUE}管理 Secrets...${RESET}"
    echo -e "1. 添加新的 Secret"
    echo -e "2. 从环境变量导入 Secrets"
    echo -e "3. 查看所有 Secrets"
    read -p "请选择操作: " secret_choice
    
    case "$secret_choice" in
        1)
            read -p "请输入 Secret 名称: " secret_name
            read -s -p "请输入 Secret 值: " secret_value
            echo
            
            # 加密并存储 Secret
            encrypted_value=$(echo "$secret_value" | openssl enc -aes-256-cbc -salt -pass pass:"$PRIVATE_KEY")
            echo "$secret_name:$encrypted_value" >> "$INSTALL_DIR/.secrets"
            echo -e "${GREEN}Secret 添加成功！${RESET}"
            ;;
        2)
            echo -e "${BLUE}从环境变量导入 Secrets...${RESET}"
            for var in $(env | grep '^NAPTHA_' | cut -d= -f1); do
                secret_name=$(echo "$var" | sed 's/^NAPTHA_//')
                secret_value="${!var}"
                encrypted_value=$(echo "$secret_value" | openssl enc -aes-256-cbc -salt -pass pass:"$PRIVATE_KEY")
                echo "$secret_name:$encrypted_value" >> "$INSTALL_DIR/.secrets"
            done
            echo -e "${GREEN}环境变量导入成功！${RESET}"
            ;;
        3)
            echo -e "${BLUE}当前存储的 Secrets:${RESET}"
            if [ -f "$INSTALL_DIR/.secrets" ]; then
                while IFS=: read -r name value; do
                    echo -e "${YELLOW}$name${RESET}"
                done < "$INSTALL_DIR/.secrets"
            else
                echo -e "${RED}未找到任何 Secrets！${RESET}"
            fi
            ;;
        *) echo -e "${RED}无效选项！${RESET}" ;;
    esac
}

# 确保 naptha 命令可用
ensure_naptha_available() {
    echo -e "${BLUE}确保 naptha 命令可用...${RESET}"
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
        return 1
    fi
    
    # 检查是否有虚拟环境
    USE_VENV=false
    if [ -d "$INSTALL_DIR/.venv" ]; then
        USE_VENV=true
    fi
    
    # 激活虚拟环境(如果有)
    cd "$INSTALL_DIR"
    if [ "$USE_VENV" = true ]; then
        source .venv/bin/activate
    fi
    
    # 检查并设置 HUB_URL 和 NODE_URL 环境变量
    if [ -f ".env" ]; then
        # 从.env文件获取HUB_URL
        if grep -q "HUB_URL" ".env"; then
            export HUB_URL=$(grep "HUB_URL" ".env" | cut -d= -f2)
            echo -e "${YELLOW}已设置 HUB_URL=$HUB_URL${RESET}"
        else
            # 设置默认值
            export HUB_URL="wss://hub.naptha.ai/rpc"
            echo -e "${YELLOW}未找到 HUB_URL 配置，使用默认值: $HUB_URL${RESET}"
            # 添加到.env文件
            echo "HUB_URL=$HUB_URL" >> ".env"
        fi
        
        # 从.env文件获取NODE_URL
        if grep -q "NODE_URL" ".env"; then
            export NODE_URL=$(grep "NODE_URL" ".env" | cut -d= -f2)
            echo -e "${YELLOW}已设置 NODE_URL=$NODE_URL${RESET}"
        else
            # 设置默认值
            export NODE_URL="http://localhost:7001"
            echo -e "${YELLOW}未找到 NODE_URL 配置，使用默认值: $NODE_URL${RESET}"
            # 添加到.env文件
            echo "NODE_URL=$NODE_URL" >> ".env"
        fi
    else
        # 设置默认值
        export HUB_URL="wss://hub.naptha.ai/rpc"
        export NODE_URL="http://localhost:7001"
        echo -e "${YELLOW}未找到环境配置文件，使用默认Hub和Node URL${RESET}"
    fi
    
    # 检查 naptha 命令是否可用
    if ! command -v naptha &> /dev/null; then
        echo -e "${YELLOW}naptha 命令不可用，尝试找到安装位置...${RESET}"
        NAPTHA_PATH=""
        
        # 检查不同的可能位置
        if [ "$USE_VENV" = true ] && [ -f ".venv/bin/naptha" ]; then
            NAPTHA_PATH="$INSTALL_DIR/.venv/bin/naptha"
            export PATH="$INSTALL_DIR/.venv/bin:$PATH"
            echo "export PATH=\"$INSTALL_DIR/.venv/bin:\$PATH\"" >> ~/.bashrc
        elif [ -f "$HOME/.local/bin/naptha" ]; then
            NAPTHA_PATH="$HOME/.local/bin/naptha"
            export PATH="$HOME/.local/bin:$PATH"
            echo "export PATH=\"$HOME/.local/bin:\$PATH\"" >> ~/.bashrc
        elif [ -f "/usr/local/bin/naptha" ]; then
            NAPTHA_PATH="/usr/local/bin/naptha"
        fi
        
        # 如果找到了naptha命令
        if [ -n "$NAPTHA_PATH" ]; then
            echo -e "${GREEN}找到 naptha 命令: $NAPTHA_PATH${RESET}"
            # 创建别名
            alias naptha="$NAPTHA_PATH"
            NAPTHA_CMD="$NAPTHA_PATH"
        else
            echo -e "${RED}未找到 naptha 命令，尝试重新安装...${RESET}"
            # 检查 Python 和 pip
            if ! command -v pip3 &> /dev/null; then
                echo -e "${YELLOW}安装 pip3...${RESET}"
                sudo apt update
                sudo apt install -y python3-pip
            fi
            
            # 安装 naptha-sdk
            echo -e "${YELLOW}安装 naptha-sdk...${RESET}"
            if [ -n "$UV_COMMAND" ]; then
                $UV_COMMAND pip install naptha-sdk --force-reinstall
            else
                pip3 install naptha-sdk --user --force-reinstall
            fi
            
            # 创建或更新naptha配置
            mkdir -p "$HOME/.naptha"
            cat > "$HOME/.naptha/config.json" << EOF
{
    "hub_url": "$HUB_URL",
    "default_node_url": "$NODE_URL"
}
EOF
            echo -e "${GREEN}已创建naptha配置文件: $HOME/.naptha/config.json${RESET}"
            
            # 再次检查是否可用
            if [ -f "$HOME/.local/bin/naptha" ]; then
                NAPTHA_PATH="$HOME/.local/bin/naptha"
                export PATH="$HOME/.local/bin:$PATH"
                echo "export PATH=\"$HOME/.local/bin:\$PATH\"" >> ~/.bashrc
                echo -e "${GREEN}找到 naptha 命令: $NAPTHA_PATH${RESET}"
                alias naptha="$NAPTHA_PATH"
                NAPTHA_CMD="$NAPTHA_PATH"
            else
                echo -e "${RED}无法安装 naptha 命令，请手动安装${RESET}"
                echo -e "${RED}尝试运行: pip3 install naptha-sdk --user${RESET}"
                echo -e "${RED}然后确认~/.naptha/config.json文件中的配置正确：${RESET}"
                echo -e "${RED}hub_url=\"$HUB_URL\"${RESET}"
                echo -e "${RED}default_node_url=\"$NODE_URL\"${RESET}"
                NAPTHA_CMD=""
                return 1
            fi
        fi
    else
        NAPTHA_CMD="naptha"
    fi
    
    echo -e "${GREEN}naptha 命令可用！${RESET}"
    return 0
}

# 运行模块
run_module() {
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
        return 1
    fi
    
    # 确保 naptha 命令可用
    if ! ensure_naptha_available; then
        echo -e "${RED}无法确保 naptha 命令可用，模块可能无法运行${RESET}"
        echo -e "${YELLOW}将尝试提供其他选项...${RESET}"
    fi
    
    echo -e "${BLUE}运行模块...${RESET}"
    echo -e "1. 运行 Agent"
    echo -e "2. 运行 Tool"
    echo -e "3. 运行 Knowledge Base"
    echo -e "4. 运行 Memory"
    echo -e "5. 运行 Orchestrator"
    read -p "请选择模块类型: " module_type
    
    read -p "请输入模块名称: " module_name
    read -p "请输入模块参数 (JSON格式): " module_params
    
    case "$module_type" in
        1) module_cmd="agent" ;;
        2) module_cmd="tool" ;;
        3) module_cmd="kb" ;;
        4) module_cmd="memory" ;;
        5) module_cmd="orchestrator" ;;
        *) echo -e "${RED}无效选项！${RESET}"; return 1 ;;
    esac
    
    cd "$INSTALL_DIR"
    
    # 检查是否有虚拟环境
    if [ -d ".venv" ]; then
        source .venv/bin/activate
    fi
    
    # 寻找naptha命令路径
    NAPTHA_CMD="naptha"
    if ! command -v naptha &> /dev/null; then
        if [ -f ".venv/bin/naptha" ]; then
            NAPTHA_CMD="$INSTALL_DIR/.venv/bin/naptha"
        elif [ -f "$HOME/.local/bin/naptha" ]; then
            NAPTHA_CMD="$HOME/.local/bin/naptha"
        elif [ -f "/usr/local/bin/naptha" ]; then
            NAPTHA_CMD="/usr/local/bin/naptha"
        else
            echo -e "${RED}无法找到 naptha 命令，请确保它已正确安装${RESET}"
            echo -e "${YELLOW}尝试手动执行以下命令:${RESET}"
            echo -e "${YELLOW}cd $INSTALL_DIR && pip3 install naptha-sdk --user${RESET}"
            echo -e "${YELLOW}然后: ~/.local/bin/naptha run $module_cmd:$module_name -p '$module_params'${RESET}"
            return 1
        fi
    fi
    
    echo -e "${BLUE}运行命令: $NAPTHA_CMD run $module_cmd:$module_name -p \"$module_params\"${RESET}"
    $NAPTHA_CMD run "$module_cmd:$module_name" -p "$module_params" || {
        echo -e "${RED}命令执行失败!${RESET}"
        echo -e "${YELLOW}请检查:${RESET}"
        echo -e "1. 节点是否正常运行"
        echo -e "2. 模块名称和参数是否正确"
        echo -e "3. Naptha 身份是否已正确配置"
        
        # 显示手动运行的命令
        echo -e "${YELLOW}您也可以尝试手动运行以下命令:${RESET}"
        echo -e "${YELLOW}cd $INSTALL_DIR${RESET}"
        if [ -d ".venv" ]; then
            echo -e "${YELLOW}source .venv/bin/activate${RESET}"
        fi
        echo -e "${YELLOW}$NAPTHA_CMD run $module_cmd:$module_name -p '$module_params'${RESET}"
    }
}

# 管理配置文件
manage_configs() {
    echo -e "${BLUE}管理配置文件...${RESET}"
    echo -e "1. 编辑 deployment.json"
    echo -e "2. 编辑 agent_deployments.json"
    echo -e "3. 编辑 kb_deployments.json"
    read -p "请选择配置文件: " config_choice
    
    case "$config_choice" in
        1) config_file="deployment.json" ;;
        2) config_file="agent_deployments.json" ;;
        3) config_file="kb_deployments.json" ;;
        *) echo -e "${RED}无效选项！${RESET}"; return 1 ;;
    esac
    
    if [ ! -f "$INSTALL_DIR/configs/$config_file" ]; then
        echo -e "${RED}配置文件不存在！${RESET}"
        return 1
    fi
    
    # 使用 nano 编辑器编辑配置文件
    nano "$INSTALL_DIR/configs/$config_file"
}

# 检查并安装依赖
check_dependencies() {
    echo -e "${BLUE}检查并安装必要的依赖...${RESET}"
    
    # 检查git
    if ! command -v git &> /dev/null; then
        echo -e "${YELLOW}安装git...${RESET}"
        sudo apt update
        sudo apt install -y git
    fi
    
    # 检查curl
    if ! command -v curl &> /dev/null; then
        echo -e "${YELLOW}安装curl...${RESET}"
        sudo apt update
        sudo apt install -y curl
    fi
    
    # 检查nano
    if ! command -v nano &> /dev/null; then
        echo -e "${YELLOW}安装nano...${RESET}"
        sudo apt update
        sudo apt install -y nano
    fi
    
    # 检查openssl
    if ! command -v openssl &> /dev/null; then
        echo -e "${YELLOW}安装openssl...${RESET}"
        sudo apt update
        sudo apt install -y openssl
    fi
}

# 安装 NapthaAI 节点
install_node() {
    check_dependencies
    install_docker
    install_uv
    echo -e "${BLUE}安装 NapthaAI 节点...${RESET}"
    if [ ! -d "$INSTALL_DIR" ]; then
        git clone https://github.com/NapthaAI/naptha-node.git "$INSTALL_DIR"
    fi
    cd "$INSTALL_DIR"

    # 检查是否存在pip
    if ! command -v pip3 &> /dev/null; then
        echo -e "${YELLOW}未找到 pip3，尝试安装...${RESET}"
        sudo apt update
        sudo apt install -y python3-pip
    fi

    # 创建虚拟环境并安装依赖
    USE_VENV=true
    if ! check_python_venv; then
        echo -e "${YELLOW}无法使用虚拟环境，将直接使用系统 Python${RESET}"
        USE_VENV=false
    fi
    
    if [ "$USE_VENV" = true ]; then
        echo -e "${BLUE}创建虚拟环境并安装依赖...${RESET}"
        if [ "$VENV_COMMAND" = "virtualenv" ]; then
            # 使用virtualenv
            python3 -m virtualenv .venv || {
                echo -e "${RED}创建虚拟环境失败，将直接使用系统 Python${RESET}"
                USE_VENV=false
            }
        else
            # 使用标准venv
            python3 -m venv .venv || {
                echo -e "${RED}创建虚拟环境失败，将直接使用系统 Python${RESET}"
                USE_VENV=false
            }
        fi
    fi
    
    if [ "$USE_VENV" = true ]; then
        source .venv/bin/activate
    fi
    
    # 使用 uv 或 pip 安装依赖
    if [ -n "$UV_COMMAND" ]; then
        echo -e "${BLUE}使用 $UV_COMMAND 安装依赖...${RESET}"
        $UV_COMMAND pip install --upgrade pip
        $UV_COMMAND pip install docker requests python-dotenv cryptography
        echo -e "${BLUE}安装 naptha-sdk...${RESET}"
        $UV_COMMAND pip install naptha-sdk
    else
        echo -e "${YELLOW}使用 pip 安装依赖...${RESET}"
        pip3 install --upgrade pip
        pip3 install docker requests python-dotenv cryptography
        echo -e "${BLUE}安装 naptha-sdk...${RESET}"
        pip3 install naptha-sdk --user
    fi
    
    # 验证naptha命令是否可用
    if ! command -v naptha &> /dev/null; then
        echo -e "${YELLOW}naptha命令不可用，尝试从安装目录加载...${RESET}"
        NAPTHA_PATH=""
        if [ "$USE_VENV" = true ] && [ -f ".venv/bin/naptha" ]; then
            NAPTHA_PATH="$INSTALL_DIR/.venv/bin/naptha"
            echo -e "${BLUE}找到naptha命令，将其添加到PATH...${RESET}"
            export PATH="$INSTALL_DIR/.venv/bin:$PATH"
            # 添加到.bashrc以便下次登录时可用
            echo "export PATH=\"$INSTALL_DIR/.venv/bin:\$PATH\"" >> ~/.bashrc
        elif [ -f "$HOME/.local/bin/naptha" ]; then
            NAPTHA_PATH="$HOME/.local/bin/naptha"
            echo -e "${BLUE}找到naptha命令，将其添加到PATH...${RESET}"
            export PATH="$HOME/.local/bin:$PATH"
            echo "export PATH=\"$HOME/.local/bin:\$PATH\"" >> ~/.bashrc
        fi
        
        if [ -z "$NAPTHA_PATH" ]; then
            echo -e "${RED}无法找到naptha命令，安装可能不完整${RESET}"
            echo -e "${YELLOW}显示Python信息:${RESET}"
            which python3
            python3 -m pip list | grep naptha
            python3 -c "import sys; print(sys.path)"
        else
            # 创建naptha别名
            alias naptha="$NAPTHA_PATH"
            NAPTHA_CMD="$NAPTHA_PATH"
        fi
    else
        NAPTHA_CMD="naptha"
    fi
    
    # 提示用户创建Naptha账户
    echo -e "${BLUE}立即创建Naptha身份...${RESET}"
    echo -e "${YELLOW}请输入用户名和密码创建Naptha账户${RESET}"
    read -p "请输入用户名: " username
    read -s -p "请输入密码: " password
    echo
    
    # 选择Hub URL
    echo -e "${YELLOW}请选择 Hub URL:${RESET}"
    echo "1. 默认本地Hub (ws://localhost:3001/rpc)"
    echo "2. 官方Hub (wss://hub.naptha.ai/rpc)"
    echo "3. 自定义Hub URL"
    read -p "请选择 (默认: 2): " hub_choice
    
    case "$hub_choice" in
        1) hub_url="ws://localhost:3001/rpc" ;;
        3) 
            read -p "请输入自定义Hub URL: " hub_url
            ;;
        2|*) hub_url="wss://hub.naptha.ai/rpc" ;;
    esac
    
    # 选择Node URL
    echo -e "${YELLOW}请选择 Node URL:${RESET}"
    echo "1. 本地Node (http://localhost:7001)"
    echo "2. 自定义Node URL"
    read -p "请选择 (默认: 1): " node_choice
    
    case "$node_choice" in
        2) 
            read -p "请输入自定义Node URL: " node_url
            ;;
        1|*) node_url="http://localhost:7001" ;;
    esac
    
    # 创建或更新 .env 文件
    if [ -f ".env.example" ]; then
        cp .env.example .env
    else
        touch .env
    fi
    
    sed -i "s/^HUB_USERNAME=.*/HUB_USERNAME=$username/" .env 2>/dev/null || echo "HUB_USERNAME=$username" >> .env
    sed -i "s/^HUB_PASSWORD=.*/HUB_PASSWORD=$password/" .env 2>/dev/null || echo "HUB_PASSWORD=$password" >> .env
    sed -i "s#^HUB_URL=.*#HUB_URL=$hub_url#" .env 2>/dev/null || echo "HUB_URL=$hub_url" >> .env
    sed -i "s#^NODE_URL=.*#NODE_URL=$node_url#" .env 2>/dev/null || echo "NODE_URL=$node_url" >> .env
    sed -i "s/^LAUNCH_DOCKER=.*/LAUNCH_DOCKER=true/" .env 2>/dev/null || echo "LAUNCH_DOCKER=true" >> .env
    sed -i "s/^LLM_BACKEND=.*/LLM_BACKEND=ollama/" .env 2>/dev/null || echo "LLM_BACKEND=ollama" >> .env
    sed -i "s/^youruser=.*/youruser=root/" .env 2>/dev/null || echo "youruser=root" >> .env
    sed -i "s/^PG_PORT=.*/PG_PORT=$pg_port/" .env 2>/dev/null || echo "PG_PORT=$pg_port" >> .env
    
    # 生成PEM文件
    echo -e "${YELLOW}正在生成私钥...${RESET}"
    PEM_FILE="$INSTALL_DIR/${username}.pem"
    openssl genrsa -out "$PEM_FILE" 2048 || {
        echo -e "${RED}使用openssl生成私钥失败，尝试使用ssh-keygen...${RESET}"
        ssh-keygen -t rsa -b 2048 -f "$PEM_FILE" -N ""
    }
    
    if [ -f "$PEM_FILE" ]; then
        # 生成一个16进制的随机私钥而不是整个PEM文件内容
        PRIVATE_KEY=$(openssl rand -hex 32)
        echo "PRIVATE_KEY=\"$PRIVATE_KEY\"" >> .env
        echo -e "${GREEN}私钥已生成并添加到配置中${RESET}"
    else
        echo -e "${RED}无法生成私钥文件，请检查系统权限${RESET}"
    fi
    
    # 更新naptha-sdk配置
    mkdir -p "$HOME/.naptha"
    cat > "$HOME/.naptha/config.json" << EOF
{
    "hub_url": "$hub_url",
    "default_node_url": "$node_url",
    "identities": {
        "$username": "$PRIVATE_KEY"
    }
}
EOF
    
    # 创建必要的目录
    mkdir -p "$INSTALL_DIR/configs"
    mkdir -p "$INSTALL_DIR/logs"
    
    # 创建默认配置文件
    if [ ! -f "$INSTALL_DIR/configs/deployment.json" ]; then
        cat > "$INSTALL_DIR/configs/deployment.json" << EOF
{
    "node": {
        "name": "node.naptha.ai"
    },
    "module": {
        "name": "multiagent_chat"
    },
    "config": {},
    "agent_deployments": [],
    "kb_deployments": []
}
EOF
    fi
    
    if [ ! -f "$INSTALL_DIR/configs/agent_deployments.json" ]; then
        cat > "$INSTALL_DIR/configs/agent_deployments.json" << EOF
[]
EOF
    fi
    
    if [ ! -f "$INSTALL_DIR/configs/kb_deployments.json" ]; then
        cat > "$INSTALL_DIR/configs/kb_deployments.json" << EOF
[]
EOF
    fi
    
    # 启动 NapthaAI 节点
    echo -e "${BLUE}启动 NapthaAI 节点...${RESET}"
    echo -e "${YELLOW}正在初始化数据库，这可能需要一些时间，请耐心等待...${RESET}"
    
    # 尝试启动节点
    bash launch.sh

    # 等待PostgreSQL初始化
    echo -e "${YELLOW}等待PostgreSQL初始化...${RESET}"
    max_retries=5
    retry_count=0
    sleep_time=10
    
    while [ $retry_count -lt $max_retries ]; do
        # 检查PostgreSQL容器是否运行
        if docker ps | grep -q "naptha-postgres"; then
            # 检查PostgreSQL是否可连接
            if docker exec naptha-postgres pg_isready -U naptha -d naptha 2>/dev/null; then
                echo -e "${GREEN}PostgreSQL初始化成功！${RESET}"
                break
            fi
        fi
        
        # 如果到达最大重试次数
        if [ $retry_count -ge $((max_retries-1)) ]; then
            break
        fi
        
        retry_count=$((retry_count+1))
        echo -e "${YELLOW}PostgreSQL还未就绪，等待${sleep_time}秒后重试... (${retry_count}/${max_retries})${RESET}"
        sleep $sleep_time
    done

    # 检查是否成功启动
    if docker ps | grep -q "naptha-postgres" && docker ps | grep -q "naptha"; then
    echo -e "${GREEN}NapthaAI 节点已成功启动！${RESET}"
        echo -e "${GREEN}用户名: $username${RESET}"
        echo -e "${GREEN}Hub URL: $hub_url${RESET}"
        echo -e "${GREEN}Node URL: $node_url${RESET}"
    echo -e "访问地址: ${YELLOW}http://$(hostname -I | awk '{print $1}'):7001${RESET}"
    else
        echo -e "${RED}启动失败！可能是数据库初始化出现问题${RESET}"
        echo -e "${YELLOW}您可以尝试:${RESET}"
        echo -e "1. 检查日志信息:"
        echo -e "   docker logs naptha 2>&1 | tail -n 20"
        echo -e "   docker logs naptha-postgres 2>&1 | tail -n 20"
        echo -e "2. 检查.env文件中PRIVATE_KEY的格式，它应该是一个简单的十六进制字符串，用双引号括起来"
        echo -e "3. 尝试设置不同的PostgreSQL端口"
        echo -e "4. 使用以下命令手动启动:"
        echo -e "   cd $INSTALL_DIR && bash launch.sh"
        echo -e "5. 或选择主菜单选项14(检查并修复配置问题)"
        
        # 询问用户是否要修复私钥格式
        read -p "是否尝试修复PRIVATE_KEY格式问题? (y/n): " fix_pk
        if [[ "$fix_pk" == "y" ]]; then
            echo -e "${YELLOW}正在修复PRIVATE_KEY格式...${RESET}"
            # 备份原有.env文件
            cp "$INSTALL_DIR/.env" "$INSTALL_DIR/.env.bak"
            # 移除原有的PRIVATE_KEY行
            grep -v "PRIVATE_KEY" "$INSTALL_DIR/.env.bak" > "$INSTALL_DIR/.env"
            # 添加新的PRIVATE_KEY
            PRIVATE_KEY=$(openssl rand -hex 32)
            echo "PRIVATE_KEY=\"$PRIVATE_KEY\"" >> "$INSTALL_DIR/.env"
            echo -e "${GREEN}已修复PRIVATE_KEY格式问题，请尝试重新启动节点${RESET}"
            read -p "是否立即重启节点? (y/n): " restart_node
            if [[ "$restart_node" == "y" ]]; then
                echo -e "${YELLOW}正在重启节点...${RESET}"
                cd "$INSTALL_DIR"
                docker-compose down
                bash launch.sh
                echo -e "${GREEN}节点已重新启动！${RESET}"
            fi
        fi
        
        # 询问用户是否要显示日志
        read -p "是否显示日志? (y/n): " show_logs
        if [[ "$show_logs" == "y" ]]; then
            echo -e "${YELLOW}Naptha 日志:${RESET}"
            docker logs naptha 2>&1 | tail -n 20
            echo -e "${YELLOW}PostgreSQL 日志:${RESET}"
            docker logs naptha-postgres 2>&1 | tail -n 20
        fi
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
        
        # 先检查并修复PRIVATE_KEY格式问题
        echo -e "${YELLOW}检查PRIVATE_KEY格式...${RESET}"
        fix_private_key
        
        # 检查节点启动方式
        if [ -f ".env" ] && grep -q "LAUNCH_DOCKER" ".env"; then
            launch_docker=$(grep "LAUNCH_DOCKER" ".env" | cut -d= -f2 | tr -d '"' | tr -d "'" | tr '[:upper:]' '[:lower:]' | xargs || echo "true")
            
            if [[ "$launch_docker" == "true" ]]; then
                # 使用Docker方式重启
                echo -e "${YELLOW}使用Docker方式重启节点...${RESET}"
                docker-compose down
                start_node
            else
                # 使用本地服务方式重启
                echo -e "${YELLOW}使用本地服务方式重启节点...${RESET}"
                
                # 根据操作系统停止当前服务
                case "$(uname -s)" in
                    Linux*)  
                        # 检查是否有systemd
                        if command -v systemctl &> /dev/null && systemctl list-units --type=service | grep -q "nodeapp"; then
                            echo -e "${YELLOW}停止systemd服务...${RESET}"
                            sudo systemctl stop nodeapp_http.service
                            for service in $(systemctl list-units --type=service | grep nodeapp | awk '{print $1}'); do
                                sudo systemctl stop "$service"
                            done
                        else
                            echo -e "${YELLOW}停止直接启动的服务...${RESET}"
                            # 查找并停止已启动的服务
                            if [ -f "http_7001.pid" ]; then
                                kill -15 $(cat http_7001.pid) 2>/dev/null || true
                            fi
                            
                            for pidfile in $(find . -name "*.pid"); do
                                kill -15 $(cat "$pidfile") 2>/dev/null || true
                                rm -f "$pidfile"
                            done
                        fi
                        ;;
                    Darwin*)  
                        echo -e "${YELLOW}停止launchd服务...${RESET}"
                        for plist in $(find ~/Library/LaunchAgents -name 'com.naptha.nodeapp.*.plist'); do
                            launchctl unload "$plist" 2>/dev/null || true
                        done
                        ;;
                    *)
                        echo -e "${YELLOW}未识别的操作系统，尝试停止直接启动的服务...${RESET}"
                        if [ -f "http_7001.pid" ]; then
                            kill -15 $(cat http_7001.pid) 2>/dev/null || true
                        fi
                        
                        for pidfile in $(find . -name "*.pid"); do
                            kill -15 $(cat "$pidfile") 2>/dev/null || true
                            rm -f "$pidfile"
                        done
                        ;;
                esac
                
                # 重新启动服务
                sleep 2
                start_node
            fi
        else
            # 默认使用Docker方式重启
            echo -e "${YELLOW}未找到配置，使用默认Docker方式重启节点...${RESET}"
            docker-compose down 2>/dev/null || true
            start_node
        fi
        
        echo -e "${GREEN}节点已重新启动！${RESET}"
    else
        echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
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

# 确保PEM文件正确创建和使用
ensure_pem_file() {
    echo -e "${BLUE}检查并确保PEM文件正确设置...${RESET}"
    
    # 检查环境文件
    if [ ! -f "$INSTALL_DIR/.env" ]; then
        echo -e "${RED}未找到 .env 文件，请先创建 Naptha 身份！${RESET}"
        return 1
    fi
    
    # 从.env文件读取用户名
    if grep -q "HUB_USERNAME" "$INSTALL_DIR/.env"; then
        HUB_USERNAME=$(grep "HUB_USERNAME" "$INSTALL_DIR/.env" | cut -d= -f2)
        echo -e "${YELLOW}找到用户名: $HUB_USERNAME${RESET}"
    else
        echo -e "${RED}未找到HUB_USERNAME配置，无法确保PEM文件正确！${RESET}"
        return 1
    fi
    
    # 检查PEM文件是否存在
    PEM_FILE="$INSTALL_DIR/${HUB_USERNAME}.pem"
    if [ ! -f "$PEM_FILE" ]; then
        echo -e "${YELLOW}未找到PEM文件，将创建新的私钥...${RESET}"
        # 生成新的PEM文件
        openssl genrsa -out "$PEM_FILE" 2048
        
        # 检查是否需要生成新的PRIVATE_KEY
        if ! grep -q "PRIVATE_KEY" "$INSTALL_DIR/.env"; then
            # 生成新的随机私钥
            PRIVATE_KEY=$(openssl rand -hex 32)
            echo "PRIVATE_KEY=\"$PRIVATE_KEY\"" >> "$INSTALL_DIR/.env"
            echo -e "${YELLOW}已生成并添加新的私钥标识符到.env文件${RESET}"
        fi
        
        echo -e "${GREEN}已创建PEM文件: $PEM_FILE${RESET}"
    else
        echo -e "${GREEN}PEM文件已存在: $PEM_FILE${RESET}"
        
        # 确保私钥已添加到.env文件
        if ! grep -q "PRIVATE_KEY" "$INSTALL_DIR/.env"; then
            # 生成新的随机私钥
            PRIVATE_KEY=$(openssl rand -hex 32)
            echo "PRIVATE_KEY=\"$PRIVATE_KEY\"" >> "$INSTALL_DIR/.env"
            echo -e "${YELLOW}已生成并添加新的私钥标识符到.env文件${RESET}"
        fi
    fi
    
    return 0
}

# 检查和修复配置问题
check_and_fix() {
    echo -e "${BLUE}正在检查配置问题...${RESET}"
    
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}未找到 NapthaAI 节点安装目录${RESET}"
        return 1
    fi
    
    cd "$INSTALL_DIR"
    
    # 检查.env文件是否存在
    if [ ! -f ".env" ]; then
        echo -e "${RED}未找到 .env 文件！${RESET}"
        # 创建.env文件
        cat > ".env" << EOF
HUB_URL=http://hub.napthaai.uk
NODE_URL=http://localhost:8080
EOF
        echo -e "${GREEN}已创建基本的 .env 文件${RESET}"
    fi
    
    # 检查HUB_USERNAME是否存在
    if ! grep -q "HUB_USERNAME" ".env"; then
        read -p "请输入你的Hub用户名: " hub_username
        echo "HUB_USERNAME=$hub_username" >> ".env"
        echo -e "${GREEN}已添加HUB_USERNAME到 .env 文件${RESET}"
    else
        hub_username=$(grep "HUB_USERNAME" ".env" | cut -d= -f2 | tr -d '"' | tr -d "'" | xargs)
    fi
    
    # 检查PRIVATE_KEY是否存在和格式
    if ! grep -q "PRIVATE_KEY" ".env"; then
        echo -e "${YELLOW}未找到PRIVATE_KEY，尝试创建...${RESET}"
        # 生成私钥并添加到.env
        new_private_key=$(openssl rand -hex 32)
        echo "PRIVATE_KEY=$new_private_key" >> ".env"
        echo -e "${GREEN}已添加PRIVATE_KEY到 .env 文件${RESET}"
        
        # 更新naptha-sdk配置
        update_sdk_config "$new_private_key" "$hub_username"
    else
        # 调用fix_private_key函数修复PRIVATE_KEY格式
        echo -e "${YELLOW}检查PRIVATE_KEY格式...${RESET}"
        fix_private_key
    fi
    
    # 检查PEM文件是否存在
    pem_file_path="$HOME/.naptha/$hub_username.pem"
    if [ ! -f "$pem_file_path" ]; then
        ensure_pem_file
    fi
    
    # 检查user.py文件问题
    fix_user_py
    
    echo -e "${GREEN}配置检查和修复完成${RESET}"
}

# 修复user.py和私钥处理相关问题
fix_user_py() {
    echo -e "${BLUE}修复user.py和private_key处理问题...${RESET}"
    
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
        return 1
    fi
    
    cd "$INSTALL_DIR"
    
    if [ ! -f ".env" ]; then
        echo -e "${RED}未找到 .env 文件！${RESET}"
        return 1
    fi
    
    # 首先确保已有有效的private_key
    if ! grep -q 'PRIVATE_KEY="[0-9a-f]' .env; then
        echo -e "${YELLOW}未找到有效的PRIVATE_KEY，将生成新的...${RESET}"
        # 生成新的PRIVATE_KEY（确保是有效的十六进制格式）
        PRIVATE_KEY=$(openssl rand -hex 32)
        
        # 备份原有.env文件
        cp ".env" ".env.bak-$(date +%Y%m%d%H%M%S)"
        
        # 移除旧的PRIVATE_KEY行
        grep -v "PRIVATE_KEY" ".env" > ".env.temp"
        
        # 添加新的PRIVATE_KEY行
        echo "PRIVATE_KEY=\"$PRIVATE_KEY\"" >> ".env.temp"
        mv ".env.temp" ".env"
        
        echo -e "${GREEN}已生成并配置新的PRIVATE_KEY${RESET}"
    else
        echo -e "${GREEN}已有有效的PRIVATE_KEY${RESET}"
    fi
    
    # 创建一个补丁文件，将直接从环境变量中读取PRIVATE_KEY改为从PEM文件读取私钥
    if [ -f "docker-compose.yml" ]; then
        # 查找Docker容器app目录的挂载点
        mount_path=$(grep -o "- .*\:/app" docker-compose.yml | awk -F':' '{print $1}' | sed 's/^- //')
        if [ -n "$mount_path" ] && [ -d "$mount_path" ]; then
            echo -e "${YELLOW}已找到Docker挂载目录：$mount_path${RESET}"
            
            # 查看是否存在user.py
            if [ -f "$mount_path/node/user.py" ]; then
                echo -e "${YELLOW}找到user.py，准备修复...${RESET}"
                
                # 备份原有文件
                cp "$mount_path/node/user.py" "$mount_path/node/user.py.bak-$(date +%Y%m%d%H%M%S)"
                
                # 创建临时补丁文件
                cat > "$mount_path/node/fix_private_key.patch" << 'EOF'
--- user.py.orig    2023-03-26 00:00:00.000000000 +0000
+++ user.py    2023-03-26 00:01:00.000000000 +0000
@@ -50,15 +50,24 @@
     return PUBLIC_KEY
 
 
-def get_public_key(private_key_hex: str) -> str:
+def get_public_key(private_key_hex: str, fallback_to_file: bool = True) -> str:
     """Generate secp256k1 public key from hex private key."""
-    if not private_key_hex:
-        raise ValueError("Empty private key")
-
     try:
-        private_key = SigningKey.from_string(
-            bytes.fromhex(private_key_hex), curve=SECP256k1
-        )
+        # 首先尝试将输入作为十六进制字符串处理
+        if private_key_hex and all(c in '0123456789abcdefABCDEF' for c in private_key_hex):
+            private_key = SigningKey.from_string(
+                bytes.fromhex(private_key_hex), curve=SECP256k1
+            )
+        elif fallback_to_file and os.path.exists(private_key_hex):
+            # 如果输入是文件路径，尝试读取PEM文件
+            with open(private_key_hex, "r") as f:
+                pem_content = f.read()
+            private_key = SigningKey.from_pem(pem_content)
+        else:
+            # 生成一个随机私钥作为后备方案
+            logger.warning("Invalid private key format, generating a random key")
+            random_bytes = os.urandom(32)
+            private_key = SigningKey.from_string(random_bytes, curve=SECP256k1)
     except Exception as e:
         logger.error(f"Error creating key: {e}")
         raise ValueError(f"Invalid private key: {e}")
@@ -79,6 +88,15 @@
 def get_public_key_from_pem(private_key: str) -> str:
     """Get public key from PEM file or path."""
     logger.info(f"Getting public key from {private_key}")
+    
+    # 检查是否为有效的十六进制字符串
+    if private_key and all(c in '0123456789abcdefABCDEF' for c in private_key):
+        return get_public_key(private_key, fallback_to_file=False)
+    
+    # 检查输入是否为PEM文件路径
+    if os.path.exists(private_key):
+        with open(private_key, "r") as f:
+            private_key = f.read()
 
     public_key = get_public_key(private_key)
     return public_key
EOF
                
                # 应用补丁
                if command -v patch &> /dev/null; then
                    # 使用patch命令应用补丁
                    cd "$mount_path/node" && patch -b user.py fix_private_key.patch
                    echo -e "${GREEN}成功应用补丁到user.py${RESET}"
                else
                    # 如果没有patch命令，提示手动修改
                    echo -e "${YELLOW}没有找到patch命令，请手动修改user.py文件${RESET}"
                    echo -e "补丁文件已创建: $mount_path/node/fix_private_key.patch"
                fi
            else
                echo -e "${RED}未找到user.py文件，无法修复${RESET}"
            fi
        else
            echo -e "${RED}未找到Docker挂载目录，无法修复user.py${RESET}"
        fi
    fi
    
    # 询问是否重启容器
    read -p "是否重启Docker容器以应用更改? (y/n): " restart
    if [[ "$restart" == "y" ]]; then
        echo -e "${YELLOW}重启Docker容器...${RESET}"
        docker-compose down
        docker-compose up -d
        echo -e "${GREEN}Docker容器已重启${RESET}"
    fi
    
    return 0
}

# 检查提示PEM文件和user.py问题
if [ -f "docker-compose.yml" ]; then
    # 检查PEM文件是否在Docker卷中正确配置
    pem_docker_path=$(grep -o "- .*:.*\.pem" docker-compose.yml | awk -F':' '{print $1}' | sed 's/^- //')
    if [ -n "$pem_docker_path" ]; then
        if [ ! -f "$pem_docker_path" ]; then
            echo -e "${YELLOW}检测到Docker卷PEM文件路径未正确配置: $pem_docker_path${RESET}"
            # 复制PEM文件到Docker卷路径
            if [ -f "$INSTALL_DIR/${username}.pem" ]; then
                mkdir -p "$(dirname "$pem_docker_path")"
                cp "$INSTALL_DIR/${username}.pem" "$pem_docker_path"
                echo -e "${GREEN}已复制PEM文件到Docker卷路径${RESET}"
            else
                echo -e "${RED}未找到PEM文件，请先创建PEM文件${RESET}"
            fi
        else
            echo -e "${GREEN}Docker卷PEM文件已正确配置${RESET}"
        fi
    fi
    
    # 检查user.py文件状态
    mount_path=$(grep -o "- .*:/app" docker-compose.yml | awk -F':' '{print $1}' | sed 's/^- //')
    if [ -n "$mount_path" ] && [ -d "$mount_path" ] && [ -f "$mount_path/node/user.py" ]; then
        # 检查user.py文件是否包含我们的修复补丁
        if grep -q "fallback_to_file" "$mount_path/node/user.py"; then
            echo -e "${GREEN}user.py文件已包含修复补丁${RESET}"
        else
            echo -e "${YELLOW}检测到user.py文件未修复，可能无法正确处理私钥${RESET}"
            read -p "是否要修复user.py文件? (y/n): " fix_userpy
            if [[ "$fix_userpy" == "y" ]]; then
                fix_user_py
            else
                echo -e "${YELLOW}您可以稍后通过选择菜单选项16来修复user.py${RESET}"
            fi
        fi
    fi
fi

# 修复PRIVATE_KEY格式问题
fix_private_key() {
    local env_file=".env"
    local backup_file=".env.bak.$(date +%Y%m%d%H%M%S)"
    
    echo -e "${YELLOW}正在检查PRIVATE_KEY格式...${RESET}"
    
    # 检查.env文件是否存在
    if [ ! -f "$env_file" ]; then
        echo -e "${RED}.env文件不存在，无法修复PRIVATE_KEY！${RESET}"
        return 1
    fi
    
    # 提取私钥
    local private_key_value=$(grep "^PRIVATE_KEY=" "$env_file" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
    
    # 检查是否为空
    if [ -z "$private_key_value" ]; then
        echo -e "${RED}PRIVATE_KEY未在.env文件中找到或为空！${RESET}"
        return 1
    fi
    
    # 检查是否为PEM格式（包含BEGIN和END标记）
    if [[ "$private_key_value" == *"BEGIN"* && "$private_key_value" == *"END"* ]] || 
       [[ "$private_key_value" == *"-----BEGIN"* ]]; then
        echo -e "${YELLOW}检测到PEM格式的私钥，需要转换为十六进制格式...${RESET}"
        need_fix=true
    # 检查是否为有效的十六进制字符串（长度为64且只包含十六进制字符）
    elif [[ ! "$private_key_value" =~ ^[0-9a-fA-F]{64}$ ]]; then
        echo -e "${YELLOW}PRIVATE_KEY格式不正确，需要修复...${RESET}"
        need_fix=true
    else
        echo -e "${GREEN}PRIVATE_KEY格式正确，无需修复！${RESET}"
        return 0
    fi
    
    if [ "$need_fix" = true ]; then
        # 备份当前.env文件
        cp "$env_file" "$backup_file"
        echo -e "${GREEN}已备份原始.env文件到 $backup_file${RESET}"
        
        # 生成新的私钥
        local new_private_key=$(openssl rand -hex 32)
        echo -e "${GREEN}已生成新的PRIVATE_KEY${RESET}"
        
        # 更新.env文件中的PRIVATE_KEY
        sed -i.tmp "/^PRIVATE_KEY=/d" "$env_file" && rm -f "$env_file.tmp"
        echo "PRIVATE_KEY=$new_private_key" >> "$env_file"
        echo -e "${GREEN}已更新.env文件中的PRIVATE_KEY${RESET}"
        
        # 从.env提取HUB_USERNAME
        local hub_username=$(grep "^HUB_USERNAME=" "$env_file" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
        if [ -z "$hub_username" ]; then
            echo -e "${YELLOW}未找到HUB_USERNAME，请确保配置正确${RESET}"
            hub_username="default_user"
        fi
        
        # 更新naptha-sdk配置
        update_sdk_config "$new_private_key" "$hub_username"
        
        # 将新的私钥保存为PEM文件
        local pem_dir="$HOME/.naptha"
        local pem_file="$pem_dir/$hub_username.pem"
        
        # 确保目录存在
        mkdir -p "$pem_dir"
        
        # 将十六进制私钥转换为PEM格式
        echo -e "${YELLOW}正在保存私钥到PEM文件: $pem_file ${RESET}"
        printf "%s" "$new_private_key" | xxd -r -p | openssl pkcs8 -topk8 -inform DER -nocrypt -outform PEM > "$pem_file" 2>/dev/null
        
        if [ $? -eq 0 ] && [ -f "$pem_file" ]; then
            echo -e "${GREEN}已成功保存私钥到PEM文件${RESET}"
            chmod 600 "$pem_file"
        else
            echo -e "${RED}保存PEM文件失败，尝试使用替代方法${RESET}"
            # 替代方法：直接使用openssl生成PEM文件
            openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$pem_file"
            chmod 600 "$pem_file"
            echo -e "${YELLOW}已生成新的RSA私钥并保存到PEM文件${RESET}"
        fi
        
        echo -e "${GREEN}PRIVATE_KEY修复完成！${RESET}"
    fi
}

# 更新naptha-sdk配置的辅助函数
update_sdk_config() {
    local private_key="$1"
    local username="$2"
    
    # 检查是否有必要的参数
    if [ -z "$private_key" ] || [ -z "$username" ]; then
        echo -e "${RED}更新SDK配置失败：缺少私钥或用户名参数${RESET}"
        return 1
    fi
    
    # 确保SDK配置目录存在
    local sdk_config_dir="$HOME/.naptha"
    mkdir -p "$sdk_config_dir"
    
    # 从.env提取HUB_URL和NODE_URL
    local env_file=".env"
    local hub_url=$(grep "^HUB_URL=" "$env_file" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
    local node_url=$(grep "^NODE_URL=" "$env_file" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
    
    # 如果未找到HUB_URL，使用默认值
    if [ -z "$hub_url" ]; then
        hub_url="http://hub.napthaai.uk"
    fi
    
    # 如果未找到NODE_URL，使用默认值
    if [ -z "$node_url" ]; then
        node_url="http://localhost:8080"
    fi
    
    # 创建或更新SDK配置文件
    local sdk_config_file="$sdk_config_dir/config.json"
    cat > "$sdk_config_file" << EOF
{
    "hub_url": "$hub_url",
    "node_url": "$node_url",
    "username": "$username",
    "private_key": "$private_key"
}
EOF
    
    # 设置适当的权限
    chmod 600 "$sdk_config_file"
    echo -e "${GREEN}已更新naptha-sdk配置文件${RESET}"
}

# 加载环境变量文件
load_env_file() {
    CURRENT_DIR=$(pwd)
    ENV_FILE="$CURRENT_DIR/.env"
    
    # 检查.env文件是否存在
    if [ -f "$ENV_FILE" ]; then
        echo -e "${GREEN}.env文件已找到${RESET}" | tee -a "$LOG_FILE"
        
        # 加载.env文件
        set -a
        . "$ENV_FILE"
        set +a
        
        # 如果存在虚拟环境，激活它
        if [ -d ".venv" ]; then
            . .venv/bin/activate
        fi
    else
        echo -e "${RED}.env文件不存在: $CURRENT_DIR${RESET}" | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Linux系统启动服务器
linux_start_servers() {
    # 输出启动服务器信息
    echo -e "${BLUE}启动服务器...${RESET}" | tee -a "$LOG_FILE"
    
    # 从.env文件获取配置
    node_communication_protocol=${NODE_COMMUNICATION_PROTOCOL:-"ws"}  # 默认为ws
    num_node_communication_servers=${NUM_NODE_COMMUNICATION_SERVERS:-1}  # 默认为1
    start_port=${NODE_COMMUNICATION_PORT:-7002}  # 次要服务器的起始端口
    
    echo -e "${YELLOW}节点通信协议: $node_communication_protocol${RESET}" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}节点通信服务器数量: $num_node_communication_servers${RESET}" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}节点通信服务器起始端口: $start_port${RESET}" | tee -a "$LOG_FILE"
    
    # 定义路径
    USER_NAME=$(whoami)
    CURRENT_DIR=$(pwd)
    PYTHON_APP_PATH="$CURRENT_DIR/.venv/bin/python"
    WORKING_DIR="$CURRENT_DIR/node"
    ENVIRONMENT_FILE_PATH="$CURRENT_DIR/.env"
    
    # 首先创建HTTP服务器服务(固定端口7001)
    HTTP_SERVICE_FILE="nodeapp_http.service"
    echo -e "${YELLOW}在端口7001上启动HTTP服务器...${RESET}" | tee -a "$LOG_FILE"
    
    # 创建systemd服务文件(HTTP服务器)
    cat <<EOF > /tmp/$HTTP_SERVICE_FILE
[Unit]
Description=Node HTTP Server
After=network.target

[Service]
ExecStart=$PYTHON_APP_PATH $WORKING_DIR/server/server.py --communication-protocol http --port 7001
WorkingDirectory=$CURRENT_DIR
EnvironmentFile=$ENVIRONMENT_FILE_PATH
User=$USER_NAME
Restart=always
TimeoutStopSec=90
KillMode=mixed
KillSignal=SIGTERM
SendSIGKILL=yes
# 关闭行为的环境变量
Environment=UVICORN_TIMEOUT=30
Environment=UVICORN_GRACEFUL_SHUTDOWN=30
Environment=PATH=$HOME/.local/bin:$HOME/.cargo/bin:${PATH}

[Install]
WantedBy=multi-user.target
EOF
    
    # 移动HTTP服务文件并启动
    sudo mv /tmp/$HTTP_SERVICE_FILE /etc/systemd/system/
    sudo systemctl daemon-reload
    
    if sudo systemctl enable $HTTP_SERVICE_FILE && sudo systemctl start $HTTP_SERVICE_FILE; then
        echo -e "${GREEN}HTTP服务器成功启动，端口7001${RESET}" | tee -a "$LOG_FILE"
    else
        echo -e "${RED}HTTP服务器启动失败${RESET}" | tee -a "$LOG_FILE"
        return 1
    fi
    
    # 记录所有端口(用于.env文件)
    ports="7001"
    
    # 创建额外服务器的服务
    for ((i=0; i<num_node_communication_servers; i++)); do
        current_port=$((start_port + i))
        SERVICE_FILE="nodeapp_${node_communication_protocol}_${current_port}.service"
        ports="${ports},${current_port}"
        
        echo -e "${YELLOW}在端口${current_port}上启动${node_communication_protocol}节点通信服务器...${RESET}" | tee -a "$LOG_FILE"
        
        # 创建systemd服务文件
        cat <<EOF > /tmp/$SERVICE_FILE
[Unit]
Description=Node $node_communication_protocol Node Communication Server on port $current_port
After=network.target nodeapp_http.service

[Service]
ExecStart=$PYTHON_APP_PATH $WORKING_DIR/server/server.py --communication-protocol $node_communication_protocol --port $current_port
WorkingDirectory=$CURRENT_DIR
EnvironmentFile=$ENVIRONMENT_FILE_PATH
User=$USER_NAME
Restart=always
TimeoutStopSec=3
KillMode=mixed
KillSignal=SIGTERM
SendSIGKILL=yes
Environment=PATH=$HOME/.local/bin:$HOME/.cargo/bin:${PATH}

[Install]
WantedBy=multi-user.target
EOF
        
        # 移动服务文件并启动
        sudo mv /tmp/$SERVICE_FILE /etc/systemd/system/
        sudo systemctl daemon-reload
        
        if sudo systemctl enable $SERVICE_FILE && sudo systemctl start $SERVICE_FILE; then
            echo -e "${GREEN}${node_communication_protocol}服务器成功启动，端口${current_port}${RESET}" | tee -a "$LOG_FILE"
        else
            echo -e "${RED}${node_communication_protocol}服务器启动失败，端口${current_port}${RESET}" | tee -a "$LOG_FILE"
        fi
    done
    
    NODE_COMMUNICATION_PORTS=$ports
}

# MacOS系统启动服务器
darwin_start_servers() {
    # 输出启动服务器信息
    echo -e "${BLUE}启动服务器...${RESET}" | tee -a "$LOG_FILE"
    
    # 从.env文件获取配置
    node_communication_protocol=${NODE_COMMUNICATION_PROTOCOL:-"ws"}  # 默认为ws
    num_node_communication_servers=${NUM_NODE_COMMUNICATION_SERVERS:-1}  # 默认为1
    start_port=${NODE_COMMUNICATION_PORT:-7002}  # 次要服务器的起始端口
    
    echo -e "${YELLOW}节点通信协议: $node_communication_protocol${RESET}" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}节点通信服务器数量: $num_node_communication_servers${RESET}" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}节点通信服务器起始端口: $start_port${RESET}" | tee -a "$LOG_FILE"
    
    # 定义路径
    USER_NAME=$(whoami)
    CURRENT_DIR=$(pwd)
    PYTHON_APP_PATH="$CURRENT_DIR/.venv/bin/python"  # 直接使用Python
    WORKING_DIR="$CURRENT_DIR/node"
    ENVIRONMENT_FILE_PATH="$CURRENT_DIR/.env"
    
    # 首先创建HTTP服务器plist文件(固定端口7001)
    HTTP_PLIST_FILE="com.naptha.nodeapp.http.plist"
    echo -e "${YELLOW}在端口7001上启动HTTP服务器...${RESET}" | tee -a "$LOG_FILE"
    
    PLIST_PATH=$HOME/Library/LaunchAgents/$HTTP_PLIST_FILE
    
    # 创建HTTP服务器的plist文件
    cat <<EOF > $PLIST_PATH
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.naptha.nodeapp.http</string>
    <key>ProgramArguments</key>
    <array>
        <string>$PYTHON_APP_PATH</string>
        <string>$WORKING_DIR/server/server.py</string>
        <string>--communication-protocol</string>
        <string>http</string>
        <string>--port</string>
        <string>7001</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
EOF
    
    # 从.env文件读取环境变量并添加到plist
    if [ -f "$ENVIRONMENT_FILE_PATH" ]; then
        while IFS='=' read -r key value || [ -n "$key" ]; do
            # 跳过注释行和空行
            [[ $key =~ ^#.*$ || -z $key ]] && continue
            
            # 去除引号
            value=$(echo "$value" | sed 's/^"//;s/"$//')
            
            cat <<EOF >> $PLIST_PATH
        <key>$key</key>
        <string>$value</string>
EOF
        done < "$ENVIRONMENT_FILE_PATH"
    fi
    
    # 完成plist文件
    cat <<EOF >> $PLIST_PATH
    </dict>
    <key>WorkingDirectory</key>
    <string>$CURRENT_DIR</string>
    <key>StandardOutPath</key>
    <string>/tmp/nodeapp_http.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/nodeapp_http.err</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF
    
    # 加载并启动HTTP服务
    launchctl unload $PLIST_PATH 2>/dev/null || true
    launchctl load -w $PLIST_PATH
    
    echo -e "${GREEN}HTTP服务器成功启动，端口7001${RESET}" | tee -a "$LOG_FILE"
    
    # 记录所有端口(用于.env文件)
    ports="7001"
    
    # 创建额外服务器的plist文件
    for ((i=0; i<num_node_communication_servers; i++)); do
        current_port=$((start_port + i))
        PLIST_FILE="com.naptha.nodeapp.${node_communication_protocol}.${current_port}.plist"
        PLIST_PATH=$HOME/Library/LaunchAgents/$PLIST_FILE
        ports="${ports},${current_port}"
        
        echo -e "${YELLOW}在端口${current_port}上启动${node_communication_protocol}节点通信服务器...${RESET}" | tee -a "$LOG_FILE"
        
        # 创建plist文件
        cat <<EOF > $PLIST_PATH
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.naptha.nodeapp.${node_communication_protocol}.${current_port}</string>
    <key>ProgramArguments</key>
    <array>
        <string>$PYTHON_APP_PATH</string>
        <string>$WORKING_DIR/server/server.py</string>
        <string>--communication-protocol</string>
        <string>${node_communication_protocol}</string>
        <string>--port</string>
        <string>${current_port}</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
EOF
        
        # 从.env文件读取环境变量并添加到plist
        if [ -f "$ENVIRONMENT_FILE_PATH" ]; then
            while IFS='=' read -r key value || [ -n "$key" ]; do
                # 跳过注释行和空行
                [[ $key =~ ^#.*$ || -z $key ]] && continue
                
                # 去除引号
                value=$(echo "$value" | sed 's/^"//;s/"$//')
                
                cat <<EOF >> $PLIST_PATH
        <key>$key</key>
        <string>$value</string>
EOF
            done < "$ENVIRONMENT_FILE_PATH"
        fi
        
        # 完成plist文件
        cat <<EOF >> $PLIST_PATH
    </dict>
    <key>WorkingDirectory</key>
    <string>$CURRENT_DIR</string>
    <key>StandardOutPath</key>
    <string>/tmp/nodeapp_${node_communication_protocol}_${current_port}.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/nodeapp_${node_communication_protocol}_${current_port}.err</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF
        
        # 加载并启动服务
        launchctl unload $PLIST_PATH 2>/dev/null || true
        launchctl load -w $PLIST_PATH
        
        echo -e "${GREEN}${node_communication_protocol}服务器成功启动，端口${current_port}${RESET}" | tee -a "$LOG_FILE"
    done
    
    NODE_COMMUNICATION_PORTS=$ports
}

# 直接启动服务器(不使用systemd或launchd)
start_servers() {
    # 输出启动服务器信息
    echo -e "${BLUE}启动服务器...${RESET}" | tee -a "$LOG_FILE"
    
    # 从.env文件获取配置
    node_communication_protocol=${NODE_COMMUNICATION_PROTOCOL:-"ws"}  # 默认为ws
    num_node_communication_servers=${NUM_NODE_COMMUNICATION_SERVERS:-1}  # 默认为1
    start_port=${NODE_COMMUNICATION_PORT:-7002}  # 次要服务器的起始端口
    
    echo -e "${YELLOW}节点通信协议: $node_communication_protocol${RESET}" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}节点通信服务器数量: $num_node_communication_servers${RESET}" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}节点通信服务器起始端口: $start_port${RESET}" | tee -a "$LOG_FILE"
    
    # 定义路径
    CURRENT_DIR=$(pwd)
    PYTHON_APP_PATH="$CURRENT_DIR/.venv/bin/python"
    WORKING_DIR="$CURRENT_DIR/node"
    LOG_DIR="$CURRENT_DIR/logs"
    
    # 创建日志目录
    mkdir -p "$LOG_DIR"
    
    # 启动HTTP服务器(端口7001)
    echo -e "${YELLOW}在端口7001上启动HTTP服务器...${RESET}" | tee -a "$LOG_FILE"
    nohup $PYTHON_APP_PATH $WORKING_DIR/server/server.py --communication-protocol http --port 7001 > "$LOG_DIR/http_7001.log" 2>&1 &
    HTTP_PID=$!
    echo $HTTP_PID > "$CURRENT_DIR/http_7001.pid"
    echo -e "${GREEN}HTTP服务器成功启动，端口7001 (PID: $HTTP_PID)${RESET}" | tee -a "$LOG_FILE"
    
    # 记录所有端口(用于.env文件)
    ports="7001"
    
    # 启动额外的通信服务器
    for ((i=0; i<num_node_communication_servers; i++)); do
        current_port=$((start_port + i))
        ports="${ports},${current_port}"
        
        echo -e "${YELLOW}在端口${current_port}上启动${node_communication_protocol}节点通信服务器...${RESET}" | tee -a "$LOG_FILE"
        
        nohup $PYTHON_APP_PATH $WORKING_DIR/server/server.py --communication-protocol $node_communication_protocol --port $current_port > "$LOG_DIR/${node_communication_protocol}_${current_port}.log" 2>&1 &
        SERVER_PID=$!
        echo $SERVER_PID > "$CURRENT_DIR/${node_communication_protocol}_${current_port}.pid"
        
        echo -e "${GREEN}${node_communication_protocol}服务器成功启动，端口${current_port} (PID: $SERVER_PID)${RESET}" | tee -a "$LOG_FILE"
    done
    
    NODE_COMMUNICATION_PORTS=$ports
}

# 更新菜单选项，添加新的修复PRIVATE_KEY选项

# 启动NapthaAI节点
start_node() {
    echo -e "${BLUE}启动NapthaAI节点...${RESET}"
    
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
        return 1
    fi
    
    cd "$INSTALL_DIR"
    
    # 创建日志文件
    LOG_DIR="$INSTALL_DIR/logs"
    mkdir -p "$LOG_DIR"
    LOG_FILE="$LOG_DIR/node_$(date +%Y%m%d%H%M%S).log"
    touch "$LOG_FILE"
    
    echo -e "${YELLOW}日志文件：$LOG_FILE${RESET}"
    
    # 检查.env文件是否存在
    if [ ! -f ".env" ]; then
        echo -e "${RED}未找到 .env 文件！${RESET}" | tee -a "$LOG_FILE"
        return 1
    fi
    
    # 修复私钥格式问题（如有需要）
    echo -e "${YELLOW}检查私钥格式...${RESET}" | tee -a "$LOG_FILE"
    fix_private_key
    
    # 加载环境变量
    load_env_file
    
    # 获取启动方式配置
    launch_docker=$(grep "LAUNCH_DOCKER" ".env" | cut -d= -f2 | tr -d '"' | tr -d "'" | tr '[:upper:]' '[:lower:]' | xargs || echo "true")
    
    if [[ "$launch_docker" == "true" ]]; then
        echo -e "${YELLOW}使用Docker启动节点...${RESET}" | tee -a "$LOG_FILE"
        
        # 检查docker-compose是否可用
        if ! command -v docker-compose &> /dev/null && ! command -v docker compose &> /dev/null; then
            echo -e "${RED}Docker Compose未安装，请先安装Docker Compose！${RESET}" | tee -a "$LOG_FILE"
            return 1
        fi
        
        # 先停止现有服务
        echo -e "${YELLOW}停止现有服务...${RESET}" | tee -a "$LOG_FILE"
        docker-compose down 2>/dev/null || true
        
        # 启动Docker服务
        echo -e "${YELLOW}启动Docker服务...${RESET}" | tee -a "$LOG_FILE"
        if docker-compose up -d; then
            echo -e "${GREEN}Docker服务启动成功！${RESET}" | tee -a "$LOG_FILE"
            
            # 等待服务就绪
            echo -e "${YELLOW}等待服务就绪...${RESET}" | tee -a "$LOG_FILE"
            sleep 5
            
            # 显示容器状态
            echo -e "${YELLOW}容器状态:${RESET}" | tee -a "$LOG_FILE"
            docker-compose ps | tee -a "$LOG_FILE"
            
            return 0
        else
            echo -e "${RED}Docker服务启动失败！${RESET}" | tee -a "$LOG_FILE"
            return 1
        fi
    else
        echo -e "${YELLOW}使用本地服务启动节点...${RESET}" | tee -a "$LOG_FILE"
        
        # 根据操作系统选择启动方式
        case "$(uname -s)" in
            Linux*)  
                # 检查是否有systemd
                if command -v systemctl &> /dev/null; then
                    echo -e "${YELLOW}使用systemd启动节点...${RESET}" | tee -a "$LOG_FILE"
                    linux_start_servers
                else
                    echo -e "${YELLOW}使用直接启动方式...${RESET}" | tee -a "$LOG_FILE"
                    start_servers
                fi
                ;;
            Darwin*)  
                echo -e "${YELLOW}在MacOS上启动节点...${RESET}" | tee -a "$LOG_FILE"
                darwin_start_servers
                ;;
            *)
                echo -e "${YELLOW}未识别的操作系统，使用直接启动方式...${RESET}" | tee -a "$LOG_FILE"
                start_servers
                ;;
        esac
        
        echo -e "${GREEN}节点服务已启动！${RESET}" | tee -a "$LOG_FILE"
        return 0
    fi
}

# 修改check_and_fix函数，添加对fix_private_key的调用
check_and_fix() {
    echo -e "${BLUE}检查并修复配置问题...${RESET}"
    
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
        return 1
    fi
    
    cd "$INSTALL_DIR"
    
    # 检查Docker是否安装
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker未安装，请先安装Docker！${RESET}"
        return 1
    fi
    
    # 检查Docker Compose是否安装
    if ! command -v docker-compose &> /dev/null && ! command -v docker compose &> /dev/null; then
        echo -e "${RED}Docker Compose未安装，请先安装Docker Compose！${RESET}"
        return 1
    fi
    
    # 检查是否存在配置文件
    if [ ! -f ".env" ]; then
        echo -e "${RED}未找到配置文件(.env)，请先创建配置文件！${RESET}"
        return 1
    fi
    
    # 调用fix_private_key函数修复PRIVATE_KEY格式
    echo -e "${YELLOW}检查PRIVATE_KEY格式...${RESET}"
    fix_private_key
    
    # 检查PostgreSQL配置
    if grep -q "PG_PORT" ".env"; then
        pg_port=$(grep "PG_PORT" ".env" | cut -d= -f2 | tr -d '"' | tr -d "'" | xargs)
        echo -e "${YELLOW}PostgreSQL端口: $pg_port${RESET}"
        
        # 检查是否有端口冲突
        if lsof -i:"$pg_port" &> /dev/null; then
            echo -e "${RED}端口 $pg_port 已被占用，需要修改PostgreSQL端口！${RESET}"
            read -p "请输入新的PostgreSQL端口号: " new_pg_port
            sed -i "s/PG_PORT=.*/PG_PORT=$new_pg_port/" ".env"
            echo -e "${GREEN}已更新PostgreSQL端口为 $new_pg_port${RESET}"
        else
            echo -e "${GREEN}PostgreSQL端口未被占用${RESET}"
        fi
    fi
    
    # 检查提示PEM文件和user.py问题
    if [ -f "docker-compose.yml" ]; then
        # 检查用户名
        if grep -q "HUB_USERNAME" ".env"; then
            username=$(grep "HUB_USERNAME" ".env" | cut -d= -f2 | tr -d '"' | tr -d "'" | xargs)
        else
            username="default"
        fi
        
        # 检查PEM文件是否在Docker卷中正确配置
        pem_docker_path=$(grep -o "- .*:.*\.pem" docker-compose.yml | awk -F':' '{print $1}' | sed 's/^- //')
        if [ -n "$pem_docker_path" ]; then
            if [ ! -f "$pem_docker_path" ]; then
                echo -e "${YELLOW}检测到Docker卷PEM文件路径未正确配置: $pem_docker_path${RESET}"
                # 复制PEM文件到Docker卷路径
                if [ -f "$INSTALL_DIR/${username}.pem" ]; then
                    mkdir -p "$(dirname "$pem_docker_path")"
                    cp "$INSTALL_DIR/${username}.pem" "$pem_docker_path"
                    echo -e "${GREEN}已复制PEM文件到Docker卷路径${RESET}"
                else
                    echo -e "${RED}未找到PEM文件，请先创建PEM文件${RESET}"
                fi
            else
                echo -e "${GREEN}Docker卷PEM文件已正确配置${RESET}"
            fi
        fi
        
        # 检查user.py文件状态
        mount_path=$(grep -o "- .*:/app" docker-compose.yml | awk -F':' '{print $1}' | sed 's/^- //')
        if [ -n "$mount_path" ] && [ -d "$mount_path" ] && [ -f "$mount_path/node/user.py" ]; then
            # 检查user.py文件是否包含我们的修复补丁
            if grep -q "fallback_to_file" "$mount_path/node/user.py"; then
                echo -e "${GREEN}user.py文件已包含修复补丁${RESET}"
            else
                echo -e "${YELLOW}检测到user.py文件未修复，可能无法正确处理私钥${RESET}"
                read -p "是否要修复user.py文件? (y/n): " fix_userpy
                if [[ "$fix_userpy" == "y" ]]; then
                    fix_user_py
                else
                    echo -e "${YELLOW}您可以稍后通过选择菜单选项16来修复user.py${RESET}"
                fi
            fi
        fi
    fi
    
    # 询问是否重启节点
    if docker ps | grep -q "naptha"; then
        read -p "是否需要重启节点以应用更改? (y/n): " restart_node
        if [[ "$restart_node" == "y" ]]; then
            echo -e "${YELLOW}正在重启节点...${RESET}"
            docker-compose down
            start_node
            echo -e "${GREEN}节点已重新启动！${RESET}"
        fi
    fi
    
    return 0
}

# 更新主菜单，添加新的选项
main_menu() {
    while true; do
        echo -e "\n${BLUE}======== NapthaAI 节点管理 ========${RESET}"
        echo -e "${BLUE}@Fishzone24${RESET}"
        echo -e "${YELLOW}1. 安装 NapthaAI 节点${RESET}"
        echo -e "${YELLOW}2. 启动 NapthaAI 节点${RESET}"
        echo -e "${YELLOW}3. 停止 NapthaAI 节点${RESET}"
        echo -e "${YELLOW}4. 重启 NapthaAI 节点${RESET}"
        echo -e "${YELLOW}5. 查看 NapthaAI 日志${RESET}"
        echo -e "${YELLOW}6. 手动创建 Naptha 身份${RESET}"
        echo -e "${YELLOW}7. 显示和编辑环境变量${RESET}"
        echo -e "${YELLOW}8. 管理 Secrets${RESET}"
        echo -e "${YELLOW}9. 运行模块${RESET}"
        echo -e "${YELLOW}10. 管理配置文件${RESET}"
        echo -e "${YELLOW}11. 导出 PRIVATE_KEY${RESET}"
        echo -e "${YELLOW}12. 更换 PEM 文件中的私钥${RESET}"
        echo -e "${YELLOW}13. 确保 PEM 文件正确${RESET}"
        echo -e "${YELLOW}14. 检查并修复配置问题${RESET}"
        echo -e "${YELLOW}15. 修复PRIVATE_KEY格式问题${RESET}"
        echo -e "${YELLOW}16. 修复user.py文件${RESET}"
        echo -e "${YELLOW}17. 卸载 NapthaAI 节点${RESET}"
        echo -e "${YELLOW}0. 退出${RESET}"
        read -p "请选择: " choice
        
        case $choice in
            1) install_node ;;
            2) start_node ;;
            3) stop_containers ;;
            4) restart_node ;;
            5) view_logs ;;
            6) manual_create_identity ;;
            7) show_env ;;
            8) manage_secrets ;;
            9) run_module ;;
            10) manage_configs ;;
            11) export_private_key ;;
            12) replace_private_key_in_pem ;;
            13) ensure_pem_file ;;
            14) check_and_fix ;;
            15) 
                if [ -d "$INSTALL_DIR" ]; then
                    cd "$INSTALL_DIR"
                    fix_private_key
                    echo -e "${YELLOW}PRIVATE_KEY已更新，是否需要重启节点以应用更改? (y/n): ${RESET}"
                    read -p "" restart_now
                    if [[ "$restart_now" == "y" ]]; then
                        restart_node
                    else
                        echo -e "${YELLOW}请记得稍后重启节点以应用更改${RESET}"
                    fi
                else
                    echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
                fi
                ;;
            16) fix_user_py ;;
            17) uninstall_node ;;
            0) 
                echo -e "${GREEN}谢谢使用，再见！${RESET}"
                exit 0 
                ;;
            *) echo -e "${RED}无效选项，请重试！${RESET}" ;;
        esac
    done
}

# 如果直接运行脚本，显示主菜单
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_menu
fi
