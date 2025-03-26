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

# 创建 Naptha 身份
create_naptha_identity() {
    echo -e "${BLUE}创建 Naptha 身份...${RESET}"
    read -p "请输入用户名: " username
    read -s -p "请输入密码: " password
    echo
    
    # 创建目录（如果不存在）
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}Naptha Node 目录不存在，将创建...${RESET}"
        mkdir -p "$INSTALL_DIR"
    fi
    
    # 创建 .env 文件
    cat > "$INSTALL_DIR/.env" << EOF
HUB_USERNAME=$username
HUB_PASSWORD=$password
LAUNCH_DOCKER=true
LLM_BACKEND=ollama
youruser=root
EOF
    
    # 生成私钥
    echo -e "${BLUE}生成私钥...${RESET}"
    PEM_FILE="$INSTALL_DIR/${username}.pem"
    openssl genrsa -out "$PEM_FILE" 2048
    
    if [ -f "$PEM_FILE" ]; then
        PRIVATE_KEY=$(cat "$PEM_FILE")
        
        # 更新 .env 文件
        echo "PRIVATE_KEY=$PRIVATE_KEY" >> "$INSTALL_DIR/.env"
        
        echo -e "${GREEN}Naptha 身份创建成功！${RESET}"
        echo -e "${YELLOW}用户名: $username${RESET}"
        echo -e "${YELLOW}私钥已保存到: $PEM_FILE${RESET}"
        echo -e "${YELLOW}环境配置已保存到: $INSTALL_DIR/.env${RESET}"
    else
        echo -e "${RED}私钥生成失败！${RESET}"
        
        # 尝试使用不同的方法生成
        echo -e "${YELLOW}尝试使用 ssh-keygen 生成 RSA 密钥...${RESET}"
        ssh-keygen -t rsa -b 2048 -f "$PEM_FILE" -N ""
        
        if [ -f "$PEM_FILE" ]; then
            PRIVATE_KEY=$(cat "$PEM_FILE")
            
            # 更新 .env 文件
            echo "PRIVATE_KEY=$PRIVATE_KEY" >> "$INSTALL_DIR/.env"
            
            echo -e "${GREEN}Naptha 身份创建成功（使用 ssh-keygen）！${RESET}"
            echo -e "${YELLOW}用户名: $username${RESET}"
            echo -e "${YELLOW}私钥已保存到: $PEM_FILE${RESET}"
            echo -e "${YELLOW}环境配置已保存到: $INSTALL_DIR/.env${RESET}"
        else
            echo -e "${RED}无法创建私钥文件，请检查系统权限和安装！${RESET}"
            return 1
        fi
    fi
    
    return 0
}

# 配置环境变量
configure_env() {
    if [ ! -f "$INSTALL_DIR/.env" ]; then
        echo -e "${RED}未找到 .env 文件，请先创建 Naptha 身份！${RESET}"
        return 1
    fi
    
    echo -e "${BLUE}配置环境变量...${RESET}"
    read -p "请输入 Hub-Username: " hub_username
    read -s -p "请输入 Hub-Password: " hub_password
    echo
    
    # 更新 .env 文件
    sed -i "s/^HUB_USERNAME=.*/HUB_USERNAME=$hub_username/" "$INSTALL_DIR/.env"
    sed -i "s/^HUB_PASSWORD=.*/HUB_PASSWORD=$hub_password/" "$INSTALL_DIR/.env"
    
    echo -e "${GREEN}环境变量配置成功！${RESET}"
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
    
    # 使用 naptha 命令创建身份，如果用户还没有身份
    if [ ! -f ".env" ] || ! grep -q "HUB_USERNAME" ".env"; then
        echo -e "${BLUE}尝试使用 naptha signup 创建身份...${RESET}"
        if [ -n "$NAPTHA_CMD" ]; then
            echo -e "${BLUE}请按照提示创建 Naptha 身份${RESET}"
            $NAPTHA_CMD signup
        else
            echo -e "${YELLOW}naptha 命令不可用，将手动创建身份${RESET}"
            create_naptha_identity
        fi
    else
        # 复制 .env 配置文件
        if [ ! -f ".env" ]; then
            echo -e "${BLUE}创建 .env 配置文件...${RESET}"
            cp .env.example .env
            sed -i 's/^LAUNCH_DOCKER=.*/LAUNCH_DOCKER=true/' .env
            sed -i 's/^LLM_BACKEND=.*/LLM_BACKEND=ollama/' .env
            sed -i 's/^youruser=.*/youruser=root/' .env  # 设置为 root 用户
        fi
    fi
    
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
    bash launch.sh

    echo -e "${GREEN}NapthaAI 节点已成功启动！${RESET}"
    echo -e "访问地址: ${YELLOW}http://$(hostname -I | awk '{print $1}'):7001${RESET}"
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
        bash launch.sh
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
        # 生成新的私钥
        openssl genrsa -out "$PEM_FILE" 2048
        
        # 将私钥添加到.env文件
        PRIVATE_KEY=$(cat "$PEM_FILE")
        if grep -q "PRIVATE_KEY" "$INSTALL_DIR/.env"; then
            # 更新现有私钥
            sed -i "s|^PRIVATE_KEY=.*|PRIVATE_KEY=$PRIVATE_KEY|" "$INSTALL_DIR/.env"
        else
            # 添加新的私钥
            echo "PRIVATE_KEY=$PRIVATE_KEY" >> "$INSTALL_DIR/.env"
        fi
        
        echo -e "${GREEN}已创建并配置私钥！${RESET}"
    else
        echo -e "${GREEN}PEM文件已存在: $PEM_FILE${RESET}"
        
        # 确保私钥已添加到.env文件
        if ! grep -q "PRIVATE_KEY" "$INSTALL_DIR/.env"; then
            PRIVATE_KEY=$(cat "$PEM_FILE")
            echo "PRIVATE_KEY=$PRIVATE_KEY" >> "$INSTALL_DIR/.env"
            echo -e "${YELLOW}已将现有私钥添加到.env文件${RESET}"
        fi
    fi
    
    return 0
}

# 检查并修复配置
check_and_fix() {
    echo -e "${BLUE}检查并修复配置问题...${RESET}"
    
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${RED}未找到 NapthaAI 节点，请先安装！${RESET}"
        return 1
    fi
    
    # 检查 uv 安装
    if ! command -v uv &> /dev/null; then
        echo -e "${YELLOW}未找到 uv 命令，尝试重新安装...${RESET}"
        install_uv
    fi
    
    # 检查 naptha 命令
    ensure_naptha_available
    
    # 确保PEM文件正确
    ensure_pem_file
    
    # 检查配置文件
    cd "$INSTALL_DIR"
    if [ ! -f ".env" ]; then
        echo -e "${RED}未找到 .env 文件，尝试创建...${RESET}"
        if [ -f ".env.example" ]; then
            cp .env.example .env
            sed -i 's/^LAUNCH_DOCKER=.*/LAUNCH_DOCKER=true/' .env
            sed -i 's/^LLM_BACKEND=.*/LLM_BACKEND=ollama/' .env
            sed -i 's/^youruser=.*/youruser=root/' .env
            echo -e "${GREEN}.env 文件已创建，请使用 '配置环境变量' 选项设置您的凭据${RESET}"
        else
            echo -e "${RED}未找到 .env.example 文件，无法创建配置${RESET}"
        fi
    fi
    
    # 检查配置目录
    if [ ! -d "configs" ]; then
        echo -e "${YELLOW}创建 configs 目录...${RESET}"
        mkdir -p configs
    fi
    
    # 检查默认配置文件
    if [ ! -f "configs/deployment.json" ]; then
        echo -e "${YELLOW}创建默认 deployment.json 文件...${RESET}"
        cat > "configs/deployment.json" << EOF
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
    
    if [ ! -f "configs/agent_deployments.json" ]; then
        echo -e "${YELLOW}创建默认 agent_deployments.json 文件...${RESET}"
        cat > "configs/agent_deployments.json" << EOF
[]
EOF
    fi
    
    if [ ! -f "configs/kb_deployments.json" ]; then
        echo -e "${YELLOW}创建默认 kb_deployments.json 文件...${RESET}"
        cat > "configs/kb_deployments.json" << EOF
[]
EOF
    fi
    
    echo -e "${GREEN}配置检查完成！${RESET}"
}

# 菜单
while true; do
    echo -e "\n${BLUE}NapthaAI 一键管理脚本 - ${AUTHOR}${RESET}"
    echo -e "1. 安装 NapthaAI 节点"
    echo -e "2. 创建/管理 Naptha 身份"
    echo -e "3. 配置环境变量"
    echo -e "4. 管理 Secrets"
    echo -e "5. 运行模块"
    echo -e "6. 管理配置文件"
    echo -e "7. 查看日志"
    echo -e "8. 导出 PRIVATE_KEY"
    echo -e "9. 更换 PEM 文件中的私钥"
    echo -e "10. 停止节点"
    echo -e "11. 重新启动节点"
    echo -e "12. 卸载 NapthaAI"
    echo -e "13. 检查并修复配置问题"
    echo -e "0. 退出"
    read -p "请选择操作: " choice

    case "$choice" in
        1) install_node ;;
        2) create_naptha_identity ;;
        3) configure_env ;;
        4) manage_secrets ;;
        5) run_module ;;
        6) manage_configs ;;
        7) view_logs ;;
        8) export_private_key ;;
        9) 
            if replace_private_key_in_pem; then
                stop_containers
                cd "$INSTALL_DIR"
                bash launch.sh
                echo -e "${GREEN}密钥已更换并重新启动节点！${RESET}"
            fi
            ;;
        10) 
            stop_containers
            echo -e "${GREEN}节点已停止运行！${RESET}"
            ;;
        11) restart_node ;;
        12) uninstall_node ;;
        13) check_and_fix ;;
        0) echo -e "${BLUE}退出脚本。${RESET}"; exit 0 ;;
        *) echo -e "${RED}无效选项，请重新输入！${RESET}" ;;
    esac
done
