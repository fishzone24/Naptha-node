#!/bin/bash

# 定义颜色
GREEN='\e[32m'
YELLOW='\e[33m'
RED='\e[31m'
BLUE='\e[34m'
RESET='\e[0m'

echo -e "${BLUE}==================================================================${RESET}"
echo -e "${GREEN}Naptha 节点一键安装脚本${RESET}"
echo -e "${YELLOW}此脚本将下载并安装 Naptha 节点管理工具${RESET}"
echo -e "${BLUE}==================================================================${RESET}"

# 下载脚本
echo -e "${GREEN}正在下载 Naptha 节点管理脚本...${RESET}"
curl -fsSL https://raw.githubusercontent.com/fishzone24/naptha-node-manager/main/naptha-node.sh -o naptha-node.sh

# 检查下载是否成功
if [ $? -ne 0 ]; then
    echo -e "${RED}下载失败，请检查网络连接或脚本地址是否正确${RESET}"
    exit 1
fi

# 设置执行权限
echo -e "${GREEN}设置执行权限...${RESET}"
chmod +x naptha-node.sh

# 运行脚本
echo -e "${GREEN}启动 Naptha 节点管理脚本...${RESET}"
./naptha-node.sh 