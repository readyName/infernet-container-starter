# Infernet 非 Docker 纯节点模式

这个脚本提供了不使用 Docker 的 Infernet 节点部署方式，直接运行二进制文件，**不启动任何容器服务**。

## 功能特点

- ✅ 无需 Docker，直接运行二进制文件
- ✅ **纯节点模式**，不启动任何容器服务
- ✅ 自动检测操作系统并安装依赖
- ✅ 自动下载 Infernet 节点二进制文件
- ✅ 自动安装和配置 Redis
- ✅ 配置文件自动更新
- ✅ 完整的日志记录
- ✅ 服务状态监控

## 当前运行的服务

**非 Docker 模式下会运行：**

1. **Redis 服务** - 本地安装的 Redis 服务器
2. **Infernet 节点** - 直接运行的二进制文件

**注意：** 此模式不启动任何容器服务，仅运行核心的 Infernet 节点功能。

## 系统要求

- **操作系统**: macOS, Ubuntu, CentOS
- **内存**: 至少 2GB RAM
- **存储**: 至少 1GB 可用空间
- **网络**: 稳定的互联网连接

## 快速开始

### 1. 启动服务

```bash
./start-infernet-no-docker.sh
```

首次运行时会：
- 检查并安装系统依赖
- 提示输入 RPC URL 和私钥
- 安装 Redis
- 下载 Infernet 节点二进制文件
- 更新配置文件
- 启动所有服务

### 2. 检查服务状态

```bash
./start-infernet-no-docker.sh status
```

### 3. 停止服务

```bash
./start-infernet-no-docker.sh stop
```

### 4. 重启服务

```bash
./start-infernet-no-docker.sh restart
```

## 配置说明

### 配置文件位置

- **用户配置**: `~/.infernet_config`
- **节点配置**: `deploy/config.json`
- **容器配置**: `projects/hello-world/container/config.json`

### 二进制文件位置

- **Infernet 节点**: `~/.infernet/infernet-node`

### 日志文件

- **脚本日志**: `~/.infernet-no-docker.log`
- **节点日志**: `logs/infernet-node.log`

## 📝 日志输出情况

**当前脚本的日志处理：**

- ✅ **Infernet 节点日志**：会输出到当前页面（通过 `tee` 命令）
- ✅ **Redis 日志**：后台运行，日志保存到 `logs/redis.log`
- ✅ **统一日志监控**：使用 `./monitor-logs.sh` 可以同时查看所有日志

## 手动配置

如果需要手动修改配置，可以编辑以下文件：

### 1. 更新 RPC URL 和私钥

```bash
# 编辑用户配置文件
nano ~/.infernet_config

# 或重新运行配置
./start-infernet-no-docker.sh start
```

### 2. 修改节点配置

```bash
# 编辑节点配置文件
nano deploy/config.json
```

## 故障排除

### 1. 端口冲突

如果遇到端口冲突，检查：

```bash
# 检查端口占用
lsof -i :4001  # Infernet 节点端口
lsof -i :6379  # Redis 端口
```

### 2. 权限问题

如果遇到权限问题：

```bash
# 确保脚本有执行权限
chmod +x start-infernet-no-docker.sh

# 确保配置文件权限正确
chmod 600 ~/.infernet_config
```

### 3. 网络问题

如果下载失败：

```bash
# 手动下载 Infernet 节点二进制文件
# 访问: https://github.com/ritual-net/infernet/releases
# 下载对应平台的版本并放置到 ~/.infernet/infernet-node
```

### 4. Redis 连接问题

```bash
# 检查 Redis 状态
redis-cli ping

# 重启 Redis
sudo systemctl restart redis  # Ubuntu/CentOS
brew services restart redis   # macOS
```

## 与 Docker 模式的区别

| 特性 | Docker 模式 | 非 Docker 模式 |
|------|-------------|----------------|
| 部署复杂度 | 中等 | 简单 |
| 资源占用 | 较高 | 较低 |
| 隔离性 | 完全隔离 | 系统级 |
| 依赖管理 | 容器内管理 | 系统级管理 |
| 调试便利性 | 需要进入容器 | 直接访问 |
| 更新便利性 | 镜像更新 | 二进制更新 |

## 注意事项

1. **安全性**: 私钥存储在本地文件中，请确保文件权限正确
2. **备份**: 定期备份配置文件
3. **更新**: 定期检查 Infernet 节点版本更新
4. **监控**: 使用 `status` 命令定期检查服务状态
5. **日志**: 定期检查日志文件以排查问题

## 支持的操作系统

- **macOS**: 10.15+ (Intel/Apple Silicon)
- **Ubuntu**: 18.04+
- **CentOS**: 7+

## 获取帮助

如果遇到问题：

1. 检查日志文件
2. 运行 `status` 命令检查服务状态
3. 查看故障排除部分
4. 提交 Issue 到项目仓库

## 更新日志

- **v1.0.0**: 初始版本，支持基本的非 Docker 部署 