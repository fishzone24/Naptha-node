# Naptha-node

这是一个用于启动和运行NapthaAI节点的简化脚本。

## 功能

- 检查并创建环境配置文件
- 安装Docker和Docker Compose
- 配置Hub凭据和私钥
- 启动NapthaAI Docker容器
- 管理运行中的容器

## 使用方法

### 启动脚本
```bash
chmod +x Naptha-node.sh && ./Naptha-node.sh
```

### 主要功能说明

1. **环境配置**
   - 检查并创建.env文件
   - 配置Hub用户名和密码
   - 生成和管理PRIVATE_KEY

2. **Docker管理**
   - 安装Docker和Docker Compose（如需要）
   - 创建和管理Docker网络
   - 使用Docker Compose启动容器

3. **LLM后端支持**
   - 支持Ollama作为LLM后端
   - 自动生成配置文件

4. **容器控制**
   - 自动创建docker-ctl.sh脚本
   - 支持查看日志和停止容器命令

## 系统要求

- Linux操作系统
- Python 3.10或更高版本
- Docker和Docker Compose
- 足够的磁盘空间（建议至少10GB）

## 注意事项

1. 首次运行时会提示配置必要的环境变量
2. 安装Docker可能需要root权限
3. 请妥善保管您的私钥和密码

## 使用docker-ctl.sh管理容器

脚本会生成一个docker-ctl.sh帮助文件，可以用来管理容器：

```bash
# 查看容器日志
./docker-ctl.sh logs

# 停止并移除所有容器
./docker-ctl.sh down
```