# Naptha-node

这是一个用于安装和管理NapthaAI节点的一键脚本。

## 功能

- 安装NapthaAI节点
- 创建/管理Naptha身份
- 配置环境变量
- 管理Secrets
- 运行模块（Agent、Tool、Knowledge Base、Memory、Orchestrator）
- 管理配置文件
- 查看节点日志
- 导出PRIVATE_KEY
- 更换PEM文件中的私钥
- 停止/重启节点
- 卸载NapthaAI节点

## 使用方法

### 一键安装脚本
```bash
wget -O Naptha-node.sh https://raw.githubusercontent.com/fishzone24/Naptha-node/refs/heads/master/Naptha-node.sh && sed -i 's/\r$//' Naptha-node.sh && chmod +x Naptha-node.sh && ./Naptha-node.sh
```

### 主要功能说明

1. **安装节点**
   - 自动安装Docker和Docker Compose
   - 安装uv包管理器
   - 创建Python虚拟环境
   - 安装必要的依赖包
   - 配置默认环境

2. **身份管理**
   - 创建新的Naptha身份
   - 配置Hub用户名和密码
   - 生成和管理私钥

3. **Secrets管理**
   - 添加新的Secret
   - 从环境变量导入Secrets
   - 查看所有存储的Secrets

4. **模块运行**
   - 支持运行多种类型的模块：
     - Agent
     - Tool
     - Knowledge Base
     - Memory
     - Orchestrator
   - 支持自定义模块参数

5. **配置文件管理**
   - 管理deployment.json
   - 管理agent_deployments.json
   - 管理kb_deployments.json

## 系统要求

- Linux操作系统
- Python 3.10或更高版本
- Docker和Docker Compose
- 足够的磁盘空间（建议至少10GB）

## 注意事项

1. 首次安装时请确保系统已更新到最新版本
2. 安装过程中需要root权限
3. 请妥善保管您的私钥和密码
4. 建议定期备份配置文件

## 作者

Fishzone24 - [Twitter](https://x.com/fishzone24)