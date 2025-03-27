# Naptha 节点一键管理脚本

这是一个用于管理 Naptha 节点的一键式脚本，提供了完整的节点安装、配置、管理功能。

## 功能特点

- 自动检查并安装依赖（Docker、Docker Compose、Python环境）
- 安装 Naptha 节点
- 查看 PRIVATE_KEY
- 更换 PRIVATE_KEY 并自动重启节点
- 停止节点
- 重启节点
- 查看日志
- 删除 Naptha 节点

## 一键安装命令

在 Ubuntu 服务器上，复制以下命令并粘贴到终端中执行，即可自动下载、设置权限并运行脚本：

```bash
curl -fsSL https://raw.githubusercontent.com/fishzone24/naptha-node-manager/main/naptha-node.sh -o naptha-node.sh && chmod +x naptha-node.sh && ./naptha-node.sh
```

> 注意：脚本托管在 GitHub，请确保您的服务器可以访问 GitHub。

## 使用方法

1. 执行一键安装命令后，会出现主菜单
2. 选择需要执行的操作（输入对应数字并按回车）
3. 根据提示完成操作

## 注意事项

- 脚本仅在 Ubuntu 系统上测试过
- 需要有 sudo 权限执行安装依赖的操作
- 节点的安装目录默认为 `$HOME/naptha-node`

## 作者

- **fishzone24** - [GitHub](https://github.com/fishzone24) - [Twitter](https://x.com/fishzone24)

## 贡献指南

欢迎提交 Issues 和 Pull Requests 来改进这个脚本。

## 免责声明

本脚本仅供学习和参考使用，作者不对使用本脚本造成的任何后果负责。 