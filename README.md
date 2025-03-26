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
- 自动修复PRIVATE_KEY格式问题
- 修复user.py文件以支持多种私钥格式
- 支持多操作系统节点启动方式
- 卸载NapthaAI节点
- 模型管理与测试（支持Ollama和vLLM模型）
- 自动GPU检测与配置建议
- 工具调用支持与模型能力测试
- 推荐模型展示和详细说明

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

2. **节点运行**
   - 支持Docker方式运行节点
   - 支持Linux系统的systemd服务管理
   - 支持MacOS系统的launchd服务管理
   - 支持直接后台运行方式（适用于不支持systemd/launchd的系统）
   - 自动检测并使用最合适的运行方式

3. **身份管理**
   - 创建新的Naptha身份
   - 配置Hub用户名和密码
   - 生成和管理私钥
   - 自动修复PRIVATE_KEY格式问题

4. **模型管理与测试**
   - 支持vLLM模型的添加、删除和配置
   - 支持设置HuggingFace Token进行授权访问
   - 自动GPU检测及显存需求分析
   - Ollama模型管理与更新
   - 提供推荐模型列表及详细规格说明
   - 模型能力测试功能，包括基本对话、工具调用和JSON输出测试

5. **故障排除**
   - 修复PRIVATE_KEY格式问题
   - 修复user.py文件以支持多种私钥格式
   - 自动检测并修复PEM文件问题
   - 自动检测并解决端口冲突

6. **Secrets管理**
   - 添加新的Secret
   - 从环境变量导入Secrets
   - 查看所有存储的Secrets

7. **模块运行**
   - 支持运行多种类型的模块：
     - Agent
     - Tool
     - Knowledge Base
     - Memory
     - Orchestrator
   - 支持自定义模块参数

8. **LiteLLM服务管理**
   - 查看可用模型列表
   - 测试服务连接
   - 管理服务配置
   - 自定义API密钥

9. **配置文件管理**
   - 管理deployment.json
   - 管理agent_deployments.json
   - 管理kb_deployments.json

10. **备份与恢复**
   - 创建配置备份
   - 恢复之前的备份
   - 管理备份文件

## 系统要求

- Linux、MacOS或Windows(WSL)操作系统
- Python 3.10或更高版本
- Docker和Docker Compose
- 足够的磁盘空间（建议至少10GB）
- GPU支持（可选，用于vLLM模型）：
  - 8B模型至少需要8GB显存
  - 24-32B模型至少需要24GB显存
  - 70B模型约需70GB显存

## 常见问题解决

### PRIVATE_KEY格式问题
如果遇到`ValueError: non-hexadecimal number found in fromhex() arg at position 0`错误，可以使用脚本的`修复PRIVATE_KEY格式问题`选项进行修复。该功能会：
- 检测私钥格式是否正确
- 备份当前.env文件
- 生成新的有效私钥
- 更新相关配置

### 节点无法启动
如果节点无法正常启动，可以尝试：
1. 使用`检查并修复配置问题`选项进行自动诊断
2. 使用`查看NapthaAI日志`选项检查错误信息
3. 确保私钥格式正确
4. 检查Docker服务是否正常运行

### 模型相关问题
1. **GPU检测错误**：确保已正确安装NVIDIA驱动和CUDA
2. **模型加载失败**：检查HuggingFace Token是否正确配置
3. **显存不足**：尝试使用更小的模型或增加显存
4. **工具调用不正常**：建议使用推荐的工具调用专用模型

## 推荐模型

### Ollama推荐模型
- hermes3:8b - 支持工具调用与多轮对话的主流模型
- llama3:8b - Meta的最新开源模型，通用性能良好
- qwen2.5-7b - 阿里巴巴的强大模型，工具调用可靠性高

### vLLM推荐模型(需要GPU)
- NousResearch/Hermes-3-Llama-3.1-8B - 工具调用性能出色
- Qwen/Qwen2.5-7B-Instruct - 多轮对话和工具调用均表现出色
- Team-ACE/ToolACE-8B - 专注于工具调用的模型

## 注意事项

1. 首次安装时请确保系统已更新到最新版本
2. 安装过程中需要root权限
3. 请妥善保管您的私钥和密码
4. 建议定期备份配置文件
5. 修改私钥后请重启节点以应用更改
6. 使用工具调用功能时，推荐设置模型温度为0以获得最佳效果

## 作者

Fishzone24 - [Twitter](https://x.com/fishzone24)