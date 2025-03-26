# Naptha-node

这是一个用于安装和管理 NapthaAI 节点的一键脚本，基于官方文档配置。

## 功能特点

- 一键安装 NapthaAI 节点
- 自动配置所有必要的服务（node-app、surreal、rabbitmq、pgvector）
- 支持导出 PRIVATE_KEY
- 支持查看节点日志
- 支持卸载节点
- 支持更换 PEM 文件中的私钥
- 支持节点状态管理（启动/停止/重启）
- 支持查看服务状态

## 系统要求

- Ubuntu 22.04 或更高版本
- 至少 4GB RAM
- 至少 20GB 可用磁盘空间

## 快速开始

### 一键安装命令

```bash
apt update && apt install -y coreutils wget && wget -O Naptha-node.sh https://raw.githubusercontent.com/fishzone24/Naptha-node/master/Naptha-node.sh && chmod +x Naptha-node.sh && ./Naptha-node.sh --auto-install
```

### 手动安装

1. 克隆仓库：
```bash
git clone https://github.com/fishzone24/Naptha-node.git
cd Naptha-node
```

2. 添加执行权限：
```bash
chmod +x Naptha-node.sh
```

3. 运行脚本：
```bash
./Naptha-node.sh
```

## 使用说明

运行脚本后，您可以通过菜单进行以下操作：

1. 安装 NapthaAI 节点
2. 导出 PRIVATE_KEY
3. 查看日志
4. 卸载 NapthaAI
5. 更换 PEM 文件中的私钥并重启节点
6. 停止节点运行
7. 重新启动节点
8. 查看服务状态

## 默认配置

- 节点端口：7001
- RabbitMQ 管理界面：15672
- SurrealDB 端口：3001
- PostgreSQL 端口：5432

## 作者

Fishzone24 - [Twitter](https://x.com/fishzone24)

## 许可证

MIT License