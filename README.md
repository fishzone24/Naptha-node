# Naptha 节点一键管理脚本

## 功能特点

- 🚀 一键安装 Naptha 节点
- 🔄 支持自定义 Ollama 端口（随机/手动/默认）
- 🔑 支持查看和更换 PRIVATE_KEY
- 🛑 支持停止/重启节点
- 📝 实时查看节点日志
- 🗑️ 支持完全删除节点
- 🛡️ 自动检查并安装所需依赖
- 🔧 自动配置环境变量和端口映射
- 🎨 美观的彩色界面
- 📱 支持移动端访问

## 更新日志

### v1.0.0 (2024-02-20)
- 初始版本发布
- 支持基本的节点管理功能
- 添加彩色界面支持
- 实现自动依赖检查

### v1.1.0 (2024-02-21)
- 添加 Ollama 端口自定义功能
  - 支持随机端口分配
  - 支持手动指定端口
  - 支持使用默认端口
- 优化 docker-compose.yml 配置
- 修复镜像拉取问题
- 改进错误处理和提示信息

## 安装说明

### 一键安装命令
```bash
curl -fsSL https://raw.githubusercontent.com/fishzone24/Naptha-node/master/Naptha-node.sh -o Naptha-node.sh && chmod +x Naptha-node.sh && ./Naptha-node.sh
```

### 手动安装步骤
1. 克隆仓库：
```bash
git clone https://github.com/fishzone24/Naptha-node.git
cd Naptha-node
```

2. 设置执行权限：
```bash
chmod +x Naptha-node.sh
```

3. 运行脚本：
```bash
./Naptha-node.sh
```

## 使用说明

### 主菜单功能
1. 安装 Naptha 节点
   - 自动检查并安装依赖
   - 支持自定义 Ollama 端口
   - 自动配置环境变量
   - 自动启动节点服务

2. 查看 PRIVATE_KEY
   - 显示当前节点的 PRIVATE_KEY
   - 支持查看多个 PEM 文件

3. 更换 PRIVATE_KEY 并重启节点
   - 安全备份原 PRIVATE_KEY
   - 自动重启节点服务

4. 停止节点
   - 安全停止所有容器
   - 保留配置和数据

5. 重启节点
   - 完全重启节点服务
   - 保持配置不变

6. 查看日志
   - 实时显示节点日志
   - 默认显示最后 300 行
   - 支持实时更新

7. 删除 Naptha 节点
   - 完全删除节点数据
   - 清理所有相关文件
   - 需要确认操作

### 端口配置
- 默认 Ollama 端口：11434
- 支持随机端口（10000-65535）
- 支持手动指定端口
- 自动检查端口可用性

### 环境要求
- Ubuntu 系统
- Python 3.x
- Docker
- Docker Compose
- NVIDIA GPU（可选）

## 注意事项

1. 首次安装需要 root 权限
2. 确保系统已安装 Docker 和 Docker Compose
3. 建议使用新钱包地址
4. 请妥善保管 PRIVATE_KEY
5. 删除节点操作不可恢复

## 常见问题

1. 端口被占用
   - 使用随机端口功能
   - 手动指定其他可用端口

2. 镜像拉取失败
   - 检查网络连接
   - 确认 Docker 服务状态

3. 权限问题
   - 使用 sudo 运行脚本
   - 检查文件权限设置

## 联系方式

- 作者：fishzone24
- 推特：https://x.com/fishzone24
- GitHub：https://github.com/fishzone24

## 许可证

MIT License 