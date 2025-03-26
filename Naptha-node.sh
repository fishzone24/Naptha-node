#!/bin/bash

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PINK='\033[0;35m'
NC='\033[0m'

# 函数用于带前缀的日志记录
log_with_service_name() {
    local service_name=$1
    local color=$2
    while IFS= read -r line; do
        echo -e "${color}[$service_name]${NC} $line"
    done
}

# 检查环境文件存在
check_and_copy_env() {
    if [ ! -f .env ]; then
        cp .env.example .env
        echo ".env文件已从.env.example创建"
    else
        echo ".env文件已存在。"
    fi
}

# 安装Docker和Docker Compose
install_docker() {
    echo "检查并安装Docker和Docker Compose..." | log_with_service_name "Docker" $BLUE
    if ! command -v docker &> /dev/null; then
        echo "安装Docker..." | log_with_service_name "Docker" $BLUE
        curl -fsSL https://get.docker.com | sudo bash
        sudo systemctl enable --now docker
    fi

    if ! command -v docker-compose &> /dev/null; then
        echo "安装Docker Compose..." | log_with_service_name "Docker" $BLUE
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
}

# 检查是否有PRIVATE_KEY并设置
check_and_set_private_key() {
    if [[ -f .env ]]; then
        key_file_value=$(grep -oP '(?<=^PRIVATE_KEY=).*' .env)
        if [[ -n "$key_file_value" && -f "$key_file_value" ]]; then
            echo "PRIVATE_KEY已经设置并且文件存在。"
            return
        fi
    else
        touch .env
    fi

    read -p "未设置有效的PRIVATE_KEY。是否生成一个新的? (yes/no): " response
    if [[ "$response" == "yes" ]]; then
        source .env
        PRIVATE_KEY=$(openssl rand -hex 32)
        sed -i "/^PRIVATE_KEY=/c\PRIVATE_KEY=\"$PRIVATE_KEY\"" .env
        echo "已生成密钥对并保存。PRIVATE_KEY已设置在.env中。"
    else
        echo "密钥对生成已取消。"
    fi
}

# 检查Hub凭据
check_and_set_hub_credentials() {
    # 确保HUB_USERNAME已设置，否则提示并更新.env
    hub_username=$(grep '^HUB_USERNAME=' .env | cut -d'=' -f2)
    if [ -z "$hub_username" ]; then
        read -p "HUB_USERNAME未设置。请输入HUB_USERNAME: " hub_username
        if [ -z "$hub_username" ]; then
            echo "HUB_USERNAME不能为空。" | log_with_service_name "Docker" "$RED"
            exit 1
        fi
        if grep -q '^HUB_USERNAME=' .env; then
            sed -i "s/^HUB_USERNAME=.*/HUB_USERNAME=$hub_username/" .env
        else
            echo "HUB_USERNAME=$hub_username" >> .env
        fi
        echo "HUB_USERNAME已设置为$hub_username。" | log_with_service_name "Docker" "$BLUE"
    else
        echo "HUB_USERNAME已设置为$hub_username。" | log_with_service_name "Docker" "$BLUE"
    fi

    # 确保HUB_PASSWORD已设置，否则提示并更新.env
    hub_password=$(grep '^HUB_PASSWORD=' .env | cut -d'=' -f2)
    if [ -z "$hub_password" ]; then
        read -p "HUB_PASSWORD未设置。请输入HUB_PASSWORD: " hub_password
        if [ -z "$hub_password" ]; then
            echo "HUB_PASSWORD不能为空。" | log_with_service_name "Docker" "$RED"
            exit 1
        fi
        if grep -q '^HUB_PASSWORD=' .env; then
            sed -i "s/^HUB_PASSWORD=.*/HUB_PASSWORD=$hub_password/" .env
        else
            echo "HUB_PASSWORD=$hub_password" >> .env
        fi
        echo "HUB_PASSWORD已设置。" | log_with_service_name "Docker" "$BLUE"
    else
        echo "HUB_PASSWORD已设置。" | log_with_service_name "Docker" "$BLUE"
    fi
}

# 启动Docker
launch_docker() {
    echo "启动Docker..." | log_with_service_name "Docker" "$BLUE"
    check_and_set_hub_credentials
    check_and_set_private_key

    COMPOSE_DIR="node/compose-files"
    COMPOSE_FILES=""

    # 从.env文件读取并导出环境变量
    if [ -f .env ]; then
        echo "从.env文件加载环境变量..." | log_with_service_name "Docker" "$BLUE"
        
        # 使用简化的环境变量加载方法
        set -a
        source .env
        set +a
    fi

    # 检查是否启用开发模式
    if [[ "$DOCKER_DEV_MODE" == "true" ]]; then
        echo "以开发模式运行，使用Dockerfile-node-dev..." | log_with_service_name "Docker" "$BLUE"
        COMPOSE_BASE_FILE="docker-compose.development.yml"
    else
        echo "以生产模式运行，使用napthaai/node:latest镜像..." | log_with_service_name "Docker" "$BLUE"
        COMPOSE_BASE_FILE="docker-compose.yml"
    fi

    if [[ "$LLM_BACKEND" == "ollama" ]]; then
        echo "使用Ollama作为LLM后端..." | log_with_service_name "Docker" "$BLUE"
        python node/inference/litellm/generate_litellm_config.py
        COMPOSE_FILES+=" -f ${COMPOSE_DIR}/ollama.yml"
    else
        echo "未指定有效的LLM后端，请检查.env文件中的LLM_BACKEND设置" | log_with_service_name "Docker" "$RED"
        exit 1
    fi

    if [[ "$LOCAL_HUB" == "true" ]]; then
        echo "启用本地Hub..." | log_with_service_name "Docker" "$BLUE"
        COMPOSE_FILES+=" -f ${COMPOSE_DIR}/hub.yml"
    fi

    docker network inspect naptha-network >/dev/null 2>&1 || docker network create naptha-network

    # 存储compose命令基础供重用
    COMPOSE_CMD="docker compose -f $COMPOSE_BASE_FILE $COMPOSE_FILES"
    # 启动容器
    $COMPOSE_CMD up -d
    
    # 创建docker-ctl.sh脚本用于Ollama模式
    cat > docker-ctl.sh << EOF
#!/bin/bash
case "\$1" in
    "down")
        docker compose -f $COMPOSE_BASE_FILE $COMPOSE_FILES down
        ;;
    "logs")
        docker compose -f $COMPOSE_BASE_FILE $COMPOSE_FILES logs -f
        ;;
    *)
        echo "用法: ./docker-ctl.sh [down|logs]"
        exit 1
        ;;
esac
EOF
    
    chmod +x docker-ctl.sh
    
    # 清理临时文件
    if [[ -f "gpu_assignments.txt" ]]; then
        rm -f gpu_assignments.txt
    fi
}

# 主函数
main() {
    echo "启动Naptha Node..." | log_with_service_name "System" $BLUE
    check_and_copy_env
    install_docker
    check_and_set_private_key
    check_and_set_hub_credentials
    launch_docker
    echo "设置完成！应用已启动。" | log_with_service_name "System" $GREEN
}

# 执行主函数
main
